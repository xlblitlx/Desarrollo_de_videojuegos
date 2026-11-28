class_name EnemigoBase
extends CharacterBody3D

signal destruido(posicion_global: Vector3)

enum Estado { ENTRADA, APROXIMAR, PREPARAR, ATACAR, RECUPERAR }

const SenalEnemiga := preload("res://script_componentes/entidades/senal_enemiga.gd")

@export var duracion_entrada: float = 0.75
@export var vida_base: float = 18.0
@export var velocidad_base: float = 15.0
@export var dano_contacto: float = 10.0
@export var alcance_ataque: float = 12.0
@export var duracion_aviso: float = 0.45
@export var duracion_recuperacion: float = 1.0
@export var color_rol: Color = Color("#f0607e")
@export var escala_rol: Vector3 = Vector3.ONE
@export var indice_senal: int = 0

var estado := Estado.ENTRADA
var vida: float = 18.0
var velocidad: float = 15.0
var objetivo: Node3D = null

var _destruido: bool = false
var _restante: float = 0.75
var _direccion: Vector3 = Vector3.FORWARD
var _impulso: Vector3 = Vector3.ZERO
var _golpe_aplicado: bool = false
var _lejos: float = 0.0
var _lado: float = 1.0
var _senal: Node3D = null
var _mallas_originales: Dictionary = {}


func _ready() -> void:
	_lado = -1.0 if get_instance_id() % 2 == 0 else 1.0
	_restante = duracion_entrada

	for nodo in find_children("*", "MeshInstance3D", true, false):
		var mi := nodo as MeshInstance3D
		_mallas_originales[mi] = mi.scale

	_inicializar_estadisticas()


func _inicializar_estadisticas() -> void:
	vida = vida_base
	velocidad = velocidad_base * randf_range(0.92, 1.08)

	if is_instance_valid(_senal):
		_senal.queue_free()
	_senal = SenalEnemiga.new()
	add_child(_senal)
	_senal.configurar(indice_senal, color_rol)

	for mi in _mallas_originales:
		if is_instance_valid(mi):
			var escala_objetivo: Vector3 = (_mallas_originales[mi] as Vector3) * escala_rol
			mi.set_meta("escala_final", escala_objetivo)
			mi.scale = Vector3.ONE * 0.05 if estado == Estado.ENTRADA else escala_objetivo


func establecer_objetivo(nuevo_objetivo: Node3D) -> void:
	objetivo = nuevo_objetivo


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	if not is_instance_valid(objetivo):
		objetivo = get_tree().get_first_node_in_group("jugador") as Node3D
		if objetivo == null:
			return

	var distancia := global_position.distance_to(objetivo.global_position)
	_lejos = _lejos + delta if distancia > 175.0 else 0.0
	if _lejos > 5.0:
		queue_free()
		return

	_restante -= delta
	var movimiento := Vector3.ZERO

	match estado:
		Estado.ENTRADA:
			movimiento = _procesar_entrada()
		Estado.APROXIMAR:
			movimiento = _procesar_aproximacion(distancia, delta)
		Estado.PREPARAR:
			movimiento = _procesar_preparacion(delta)
		Estado.ATACAR:
			movimiento = _procesar_ataque(delta)
		Estado.RECUPERAR:
			movimiento = _procesar_recuperacion(delta)

	var anterior := global_position
	velocity = movimiento + _impulso
	_impulso = _impulso.move_toward(Vector3.ZERO, 34.0 * delta)
	move_and_slide()

	_post_movimiento(anterior)


func _procesar_entrada() -> Vector3:
	var progreso := 1.0 - clampf(_restante / maxf(duracion_entrada, 0.01), 0.0, 1.0)
	if is_instance_valid(_senal):
		_senal.entrada(1.0 - progreso)
	for mi in _mallas_originales:
		if is_instance_valid(mi):
			var final: Vector3 = mi.get_meta("escala_final", _mallas_originales[mi])
			mi.scale = final * lerpf(0.05, 1.0, progreso)

	if _restante <= 0.0:
		if is_instance_valid(_senal):
			_senal.apagar()
		for mi in _mallas_originales:
			if is_instance_valid(mi):
				mi.scale = mi.get_meta("escala_final", _mallas_originales[mi])
		estado = Estado.APROXIMAR
	return Vector3.ZERO


# Métodos virtuales que cada subclase especializa
func _procesar_aproximacion(_distancia: float, _delta: float) -> Vector3:
	return Vector3.ZERO


func _procesar_preparacion(_delta: float) -> Vector3:
	return Vector3.ZERO


func _procesar_ataque(_delta: float) -> Vector3:
	return Vector3.ZERO


func _procesar_recuperacion(_delta: float) -> Vector3:
	if _restante <= 0.0:
		estado = Estado.APROXIMAR
	return Vector3.ZERO


func _post_movimiento(_anterior: Vector3) -> void:
	pass


func _mover_hacia_punto(destino: Vector3, mult_vel: float = 1.0) -> Vector3:
	var hacia := destino - global_position
	if hacia.length_squared() < 0.01:
		return Vector3.ZERO
	var rumbo := hacia.normalized()
	var mov := rumbo * (velocidad * mult_vel)

	if get_slide_collision_count() > 0:
		var normal := get_slide_collision(0).get_normal()
		var tangente := rumbo.slide(normal)
		if tangente.length_squared() < 0.02:
			tangente = normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT) * _lado
		mov = tangente.normalized() * (velocidad * mult_vel)

	_orientar(rumbo)
	return mov


func _iniciar_preparacion(punto_objetivo: Vector3, mostrar_linea_larga: bool) -> void:
	_direccion = global_position.direction_to(punto_objetivo)
	if _direccion.is_zero_approx():
		_direccion = Vector3.FORWARD
	_orientar(_direccion)
	estado = Estado.PREPARAR
	_restante = duracion_aviso
	_golpe_aplicado = false
	add_to_group("ataque_anunciado")
	if is_instance_valid(_senal):
		_senal.apuntar(global_position.distance_to(punto_objetivo), mostrar_linea_larga)


func _finalizar_ataque() -> void:
	if is_in_group("ataque_anunciado"):
		remove_from_group("ataque_anunciado")
	if is_instance_valid(_senal):
		_senal.apagar()
	estado = Estado.RECUPERAR
	_restante = duracion_recuperacion


func _evaluar_impacto_cuerpo_a_cuerpo(anterior: Vector3) -> void:
	var cercano := anterior
	if anterior.distance_squared_to(global_position) > 0.000001:
		cercano = Geometry3D.get_closest_point_to_segment(objetivo.global_position, anterior, global_position)

	var choco_con_jugador := false
	var choco_con_obstaculo := false
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i).get_collider()
		if col == objetivo or (col is Node and (col as Node).is_in_group("jugador")):
			choco_con_jugador = true
		elif col is Node and not (col as Node).is_in_group("enemigos"):
			choco_con_obstaculo = true

	if not _golpe_aplicado and (choco_con_jugador or cercano.distance_squared_to(objetivo.global_position) <= 4.6 * 4.6) and _sin_cobertura(objetivo.global_position):
		_golpe_aplicado = true
		if objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(dano_contacto)
		aplicar_impulso(-_direccion * 16.0)

	if _golpe_aplicado or _restante <= 0.0 or choco_con_obstaculo:
		_finalizar_ataque()


func _calcular_punto_intercepcion(segundos_adelante: float) -> Vector3:
	if not is_instance_valid(objetivo):
		return global_position + _direccion * 10.0
	var punto := objetivo.global_position
	if objetivo is CharacterBody3D:
		punto += (objetivo as CharacterBody3D).velocity.limit_length(32.0) * segundos_adelante
	return punto


func _sin_cobertura(destino: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position, destino, 8)
	q.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _orientar(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.RIGHT if absf(dir.y) > 0.98 else Vector3.UP)


func aplicar_impulso(impulso: Vector3) -> void:
	_impulso = (_impulso + impulso).limit_length(50.0)


func recibir_dano(cantidad: float) -> void:
	if _destruido or cantidad <= 0.0 or estado == Estado.ENTRADA:
		return
	vida -= cantidad
	_destellar_impacto()
	if is_instance_valid(_senal):
		_senal.impacto()
	if vida <= 0.0:
		_destruido = true
		if is_in_group("ataque_anunciado"):
			remove_from_group("ataque_anunciado")
		EfectoCombate.crear(get_parent(), global_position, color_rol, 1.25)
		destruido.emit(global_position)
		if EventosJuego and EventosJuego.has_signal("enemigo_eliminado"):
			EventosJuego.enemigo_eliminado.emit(global_position)
		queue_free()


func _destellar_impacto() -> void:
	for nodo in find_children("*", "MeshInstance3D", true, false):
		if nodo.get_parent() == _senal:
			continue
		var mi := nodo as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			var mat := mi.get_active_material(s)
			if not (mat is BaseMaterial3D):
				continue
			var flash := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			flash.emission_enabled = true
			flash.emission = Color(1.0, 0.95, 0.9)
			flash.emission_energy_multiplier = 2.2
			mi.set_surface_override_material(s, flash)

			var tw := create_tween()
			tw.tween_property(flash, "emission_energy_multiplier", 0.0, 0.09)
			tw.tween_callback(_restaurar_material.bind(mi, s, mat))


func _restaurar_material(mi: MeshInstance3D, superficie: int, original: Material) -> void:
	if is_instance_valid(mi):
		mi.set_surface_override_material(superficie, original)
