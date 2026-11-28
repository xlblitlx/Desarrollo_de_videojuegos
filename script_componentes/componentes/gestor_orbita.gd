class_name GestorOrbita
extends Node

@export var planeta_actual: Node3D
@export var usa_propulsores: bool = false
@export var limite_mapa_global: float = 850.0
@export_range(0.5, 0.98) var umbral_borde_escape: float = 0.82
@export_range(0.35, 0.75) var factor_radio_nucleo: float = 0.56
@export var tiempo_ignicion_salida: float = 0.75
@export var impulso_despegue: float = 90.0

var progreso_escape: float = 0.0
var intentando_escapar: bool = false
var direccion_escape_radial: Vector3 = Vector3.ZERO

var _planeta_recien_salido: Node3D = null
var _cooldown_recaptura: float = 0.0


func _process(delta: float) -> void:
	if _cooldown_recaptura > 0.0:
		_cooldown_recaptura -= delta
		if _cooldown_recaptura <= 0.0:
			_planeta_recien_salido = null


func procesar_limites(jugador: CharacterBody3D) -> void:
	if not is_instance_valid(planeta_actual):
		planeta_actual = null
		progreso_escape = 0.0
		intentando_escapar = false
		_buscar_planeta_mas_cercano(jugador)

	if is_instance_valid(planeta_actual):
		_procesar_frontera_orbital(jugador)

	_aplicar_limite_global(jugador)


func activar_propulsores(activar: bool) -> void:
	usa_propulsores = activar


func _procesar_frontera_orbital(jugador: CharacterBody3D) -> void:
	var centro := planeta_actual.global_position
	var desde_centro_3d := jugador.global_position - centro
	var dist_3d := desde_centro_3d.length()

	var radio_maximo := 45.0 * planeta_actual.scale.x
	var radio_minimo := radio_maximo * factor_radio_nucleo

	# Vector radial 3D completo (cubre arriba, abajo y todos los ángulos de la esfera)
	var normal_3d := desde_centro_3d.normalized() if dist_3d > 0.001 else Vector3.UP

	# 1. Núcleo interior: desliza la nave alrededor de la superficie sin atascarla
	if dist_3d < radio_minimo:
		jugador.global_position = centro + normal_3d * radio_minimo
		var vel_hacia_adentro := jugador.velocity.dot(normal_3d)
		if vel_hacia_adentro < 0.0:
			jugador.velocity -= normal_3d * vel_hacia_adentro
		return

	# 2. Frontera exterior 3D: retiene por completo en todos los ángulos hasta romper con el propulsor
	if dist_3d >= radio_maximo:
		if usa_propulsores and progreso_escape >= 0.85:
			_planeta_recien_salido = planeta_actual
			_cooldown_recaptura = 0.55
			planeta_actual = null
			progreso_escape = 0.0
			intentando_escapar = false
			jugador.velocity = normal_3d * impulso_despegue
		else:
			jugador.global_position = centro + normal_3d * radio_maximo
			if intentando_escapar:
				jugador.velocity = Vector3.ZERO
			else:
				var vel_afuera := jugador.velocity.dot(normal_3d)
				if vel_afuera > 0.0:
					jugador.velocity -= normal_3d * vel_afuera


func _aplicar_limite_global(jugador: CharacterBody3D) -> void:
	var dist_centro := jugador.global_position.length()
	if dist_centro > limite_mapa_global:
		var dir_centro := -jugador.global_position.normalized()
		jugador.global_position = dir_centro * limite_mapa_global
		jugador.velocity = jugador.velocity.bounce(dir_centro) * 0.2


func _buscar_planeta_mas_cercano(jugador: CharacterBody3D) -> void:
	var planetas := get_tree().get_nodes_in_group("planetas")
	if planetas.is_empty():
		return

	var mas_cercano: Node3D = null
	var menor_distancia := INF

	for p in planetas:
		if p is Node3D and p != _planeta_recien_salido:
			var dist := jugador.global_position.distance_to(p.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mas_cercano = p

	if mas_cercano and menor_distancia < (45.0 * mas_cercano.scale.x):
		planeta_actual = mas_cercano


func registrar_planeta_entrante(planeta: Node3D) -> void:
	if planeta == _planeta_recien_salido and _cooldown_recaptura > 0.0:
		return
	planeta_actual = planeta
	progreso_escape = 0.0
	intentando_escapar = false


func registrar_planeta_saliente(planeta: Node3D) -> void:
	if planeta_actual == planeta:
		if usa_propulsores and progreso_escape >= 0.85:
			planeta_actual = null
			progreso_escape = 0.0
			intentando_escapar = false


func esta_en_espacio_abierto() -> bool:
	return not is_instance_valid(planeta_actual)


func obtener_planeta_actual() -> Node3D:
	return planeta_actual


func aplicar_fisica_orbital(pos_nave: Vector3, vel_nave: Vector3, _vel_max_propulsion: float, impulsando: bool, delta: float) -> Vector3:
	if esta_en_espacio_abierto():
		progreso_escape = 0.0
		intentando_escapar = false
		return vel_nave

	var planeta := obtener_planeta_actual()
	if not is_instance_valid(planeta):
		return vel_nave

	var desde_centro_3d := pos_nave - planeta.global_position
	var dist_3d := desde_centro_3d.length()
	var radio_maximo := 45.0 * planeta.scale.x
	var dir_radial_3d := desde_centro_3d.normalized() if dist_3d > 0.001 else Vector3.UP
	direccion_escape_radial = dir_radial_3d

	var pegado_al_borde := dist_3d >= (radio_maximo * umbral_borde_escape)
	var sin_direccion := vel_nave.length_squared() < 1.0
	var apuntando_afuera := sin_direccion or (vel_nave.normalized().dot(dir_radial_3d) > 0.40)

	if impulsando and pegado_al_borde and apuntando_afuera:
		intentando_escapar = true
		progreso_escape = minf(progreso_escape + (delta / maxf(tiempo_ignicion_salida, 0.1)), 1.0)
		var vel_vertical := lerpf(50.0, impulso_despegue, progreso_escape)
		return dir_radial_3d * vel_vertical

	intentando_escapar = false
	progreso_escape = maxf(progreso_escape - delta * 2.0, 0.0)

	if impulsando:
		return vel_nave

	if planeta.has_method("calcular_atraccion_sobre"):
		var atraccion: Vector3 = planeta.calcular_atraccion_sobre(pos_nave, vel_nave, 0.0)
		if vel_nave.length_squared() > 1.0 and vel_nave.normalized().dot(dir_radial_3d) > 0.15:
			atraccion *= 0.35
		return vel_nave + atraccion * delta

	return vel_nave


func recolectar_recursos_orbitales(energia_solicitada: float, delta: float) -> Vector2:
	var planeta := obtener_planeta_actual()
	if not is_instance_valid(planeta):
		return Vector2(energia_solicitada, 0.0)

	var energia := energia_solicitada
	var curacion := 0.0
	if planeta.has_method("extraer_energia_orbital"):
		energia = planeta.extraer_energia_orbital(energia_solicitada)
		if planeta.has_method("obtener_porcentaje_carga") and planeta.obtener_porcentaje_carga() > 0.0:
			if "reparacion_casco_por_seg" in planeta:
				curacion = planeta.reparacion_casco_por_seg * delta

	return Vector2(energia, curacion)
