class_name GestorOrbita
extends Node

@export var planeta_actual: Node3D
@export var usa_propulsores: bool = false
@export var limite_mapa_global: float = 850.0  # Ligeramente mayor que radio_sistema_global (800)
@export var tiempo_escape_respaldo: float = 1.8
var _impulso_escape: float = 0.0

func procesar_limites(jugador: CharacterBody3D) -> void:
	if not is_instance_valid(planeta_actual):
		planeta_actual = null
		if not usa_propulsores:
			_buscar_planeta_mas_cercano(jugador)

	if is_instance_valid(planeta_actual):
		_procesar_frontera_orbital(jugador)
	
	_aplicar_limite_global(jugador)

func activar_propulsores(activar: bool) -> void:
	usa_propulsores = activar

func _procesar_frontera_orbital(jugador: CharacterBody3D) -> void:
	var centro := planeta_actual.global_position
	var desde_centro := jugador.global_position - centro
	var radio_maximo := 45.0 * planeta_actual.scale.x

	if desde_centro.length() > radio_maximo:
		if usa_propulsores and _impulso_escape >= 0.85:
			# Rompe la atmósfera solo cuando el propulsor reunió suficiente empuje
			planeta_actual = null
			_impulso_escape = 0.0
		else:
			# Mantiene la nave dentro de la cúpula mientras sigue acumulando impulso
			var normal := desde_centro.normalized()
			jugador.global_position = centro + normal * radio_maximo
			jugador.velocity = jugador.velocity.bounce(normal) * 0.1

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
		if p is Node3D:
			var dist := jugador.global_position.distance_to(p.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				mas_cercano = p

	if mas_cercano and menor_distancia < (45.0 * mas_cercano.scale.x):
		planeta_actual = mas_cercano

func registrar_planeta_entrante(planeta: Node3D) -> void:
	planeta_actual = planeta
	usa_propulsores = false

func registrar_planeta_saliente(planeta: Node3D) -> void:
	if planeta_actual == planeta:
		planeta_actual = null

## Devuelve true si la nave está expuesta en el espacio abierto sin protección orbital
func esta_en_espacio_abierto() -> bool:
	return not is_instance_valid(planeta_actual)

func obtener_planeta_actual() -> Node3D:
	# Reemplaza "planeta_actual" por el nombre real de tu variable en gestor_orbita.gd
	return planeta_actual

## Modifica la velocidad de la nave aplicando gravedad planetaria y resistencia de escape
func aplicar_fisica_orbital(pos_nave: Vector3, vel_nave: Vector3, vel_max_propulsion: float, impulsando: bool, delta: float) -> Vector3:
	if esta_en_espacio_abierto():
		_impulso_escape = 0.0
		return vel_nave

	var planeta := obtener_planeta_actual()
	if not is_instance_valid(planeta) or not planeta.has_method("calcular_atraccion_sobre"):
		return vel_nave

	var tiempo_req: float = planeta.tiempo_escape_base if "tiempo_escape_base" in planeta else tiempo_escape_respaldo
	if impulsando:
		_impulso_escape = minf(_impulso_escape + (delta / maxf(tiempo_req, 0.1)), 1.0)
	else:
		_impulso_escape = maxf(_impulso_escape - delta * 1.5, 0.0)

	var dir_salida := (pos_nave - planeta.global_position).normalized()
	var vel_radial := vel_nave.dot(dir_salida)
	if vel_radial > 0.0:
		var tope_salida := lerpf(8.0, vel_max_propulsion, _impulso_escape * _impulso_escape)
		if vel_radial > tope_salida:
			vel_nave -= dir_salida * (vel_radial - tope_salida)

	return vel_nave + planeta.calcular_atraccion_sobre(pos_nave, vel_nave, _impulso_escape) * delta


## Devuelve Vector2(energia_recibida, curacion_recibida) desde el planeta actual
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
