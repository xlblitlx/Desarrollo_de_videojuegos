class_name Enemigo
extends CharacterBody3D

signal destruido(posicion_global: Vector3)

enum Rol { PERSEGUIDOR, EMBESTIDOR, ARTILLERO }
enum Estado { ENTRADA, APROXIMAR, PREPARAR, ATACAR, RECUPERAR }

const BALA := preload("res://escenas/proyectil.tscn")
const SenalEnemiga := preload("res://script_componentes/entidades/senal_enemiga.gd")

const COSTES := [1, 2, 3]
const VIDAS_ROL := [35.0, 55.0, 42.0]
const VELOCIDADES_ROL := [15.0, 12.5, 12.0]
const DANOS_ROL := [10.0, 16.0, 10.0]
const AVISOS_DURACION := [0.25, 0.72, 0.85]
const COLORES := [Color("#f0607e"), Color("#ffae52"), Color("#be94ff")]
const ESCALAS_ROL := [
	Vector3(0.95, 0.95, 1.0),
	Vector3(1.10, 1.15, 1.35),
	Vector3(1.25, 0.85, 0.95)
]

@export var rol: Rol = Rol.PERSEGUIDOR
@export var duracion_entrada: float = 0.75

var estado := Estado.ENTRADA
var vida: float = 35.0
var velocidad: float = 15.0
var dano_contacto: float = 10.0
var objetivo: Node3D = null

var _destruido: bool = false
var _restante: float = 0.75
var _duracion_aviso: float = 0.5
var _direccion: Vector3 = Vector3.FORWARD
var _impulso: Vector3 = Vector3.ZERO
var _golpe_aplicado: bool = false
var _lejos: float = 0.0
var _lado: float = 1.0
var _senal: Node3D = null
var _mallas_originales: Dictionary = {}


func _ready() -> void:
	vida = VIDAS_ROL[rol]
	velocidad = VELOCIDADES_ROL[rol] * randf_range(0.92, 1.08)
	dano_contacto = DANOS_ROL[rol]
	_duracion_aviso = AVISOS_DURACION[rol]
	_restante = duracion_entrada
	_lado = -1.0 if get_instance_id() % 2 == 0 else 1.0

	_senal = SenalEnemiga.new()
	add_child(_senal)
	_senal.configurar(rol, COLORES[rol])

	var mult_rol: Vector3 = ESCALAS_ROL[rol]
	for nodo in find_children("*", "MeshInstance3D", true, false):
		if nodo.get_parent() == _senal:
			continue
		var mi := nodo as MeshInstance3D
		var escala_objetivo := mi.scale * mult_rol
		_mallas_originales[mi] = escala_objetivo
		mi.scale = Vector3.ONE * 0.05


func establecer_objetivo(nuevo_objetivo: Node3D) -> void:
	objetivo = nuevo_objetivo


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	if not is_instance_valid(objetivo):
		objetivo = get_tree().get_first_node_in_group("jugador") as Node3D
		if objetivo == null:
			return

	var hacia := objetivo.global_position - global_position
	var distancia := hacia.length()

	_lejos = _lejos + delta if distancia > 175.0 else 0.0
	if _lejos > 5.0:
		queue_free()
		return

	_restante -= delta
	var movimiento := Vector3.ZERO

	match estado:
		Estado.ENTRADA:
			var progreso := 1.0 - clampf(_restante / maxf(duracion_entrada, 0.01), 0.0, 1.0)
			if is_instance_valid(_senal):
				_senal.entrada(1.0 - progreso)
			for mi in _mallas_originales:
				if is_instance_valid(mi):
					mi.scale = (_mallas_originales[mi] as Vector3) * lerpf(0.05, 1.0, progreso)

			if _restante <= 0.0:
				if is_instance_valid(_senal):
					_senal.apagar()
				for mi in _mallas_originales:
					if is_instance_valid(mi):
						mi.scale = _mallas_originales[mi]
				estado = Estado.APROXIMAR

		Estado.APROXIMAR:
			var rumbo := hacia.normalized()
			var alcance: float = [4.2, 26.0, 38.0][rol]
			var tiene_linea_vision := distancia <= alcance and _sin_cobertura(objetivo.global_position)

			if tiene_linea_vision and get_tree().get_node_count_in_group("ataque_anunciado") < 3:
				_preparar(rumbo)
			elif rol == Rol.ARTILLERO and tiene_linea_vision:
				movimiento = rumbo.cross(Vector3.UP) * _lado * velocidad
			else:
				movimiento = rumbo * velocidad
				if get_slide_collision_count() > 0:
					var normal := get_slide_collision(0).get_normal()
					var tangente := rumbo.slide(normal)
					if tangente.length_squared() < 0.02:
						tangente = normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT) * _lado
					movimiento = tangente.normalized() * velocidad
			_orientar(rumbo)

		Estado.PREPARAR:
			var prog_aviso := 1.0 - maxf(0.0, _restante) / maxf(_duracion_aviso, 0.01)
			if is_instance_valid(_senal):
				_senal.preparacion(prog_aviso)

			if rol == Rol.PERSEGUIDOR:
				var punto_futuro := _calcular_punto_intercepcion(0.25)
				_direccion = global_position.direction_to(punto_futuro)
				_orientar(_direccion)
				movimiento = _direccion * velocidad
			elif rol == Rol.EMBESTIDOR and prog_aviso < 0.70:
				var punto_embestida := _calcular_punto_intercepcion(0.42)
				_direccion = global_position.direction_to(punto_embestida)
				_orientar(_direccion)
				if is_instance_valid(_senal):
					_senal.apuntar(global_position.distance_to(punto_embestida), true)

			if _restante <= 0.0:
				estado = Estado.ATACAR
				_restante = 0.65 if rol == Rol.EMBESTIDOR else 0.42
				if rol == Rol.ARTILLERO:
					_disparar()
					_recuperar()

		Estado.ATACAR:
			if rol == Rol.PERSEGUIDOR:
				var rumbo_actual := global_position.direction_to(_calcular_punto_intercepcion(0.15))
				_direccion = _direccion.lerp(rumbo_actual, 8.0 * delta).normalized()
				_orientar(_direccion)
				movimiento = _direccion * (velocidad * 1.65)
			else:
				movimiento = _direccion * 54.0

		Estado.RECUPERAR:
			if _restante <= 0.0:
				estado = Estado.APROXIMAR

	var anterior := global_position
	velocity = movimiento + _impulso
	_impulso = _impulso.move_toward(Vector3.ZERO, 34.0 * delta)
	move_and_slide()

	if estado == Estado.ATACAR and rol != Rol.ARTILLERO:
		var cercano := anterior
		if anterior.distance_squared_to(global_position) > 0.000001:
			cercano = Geometry3D.get_closest_point_to_segment(objetivo.global_position, anterior, global_position)

		var choco_con_jugador := false
		for i in range(get_slide_collision_count()):
			var col := get_slide_collision(i).get_collider()
			if col == objetivo or (col is Node and (col as Node).is_in_group("jugador")):
				choco_con_jugador = true
				break

		if not _golpe_aplicado and (choco_con_jugador or cercano.distance_squared_to(objetivo.global_position) <= 4.6 * 4.6) and _sin_cobertura(objetivo.global_position):
			_golpe_aplicado = true
			if objetivo.has_method("recibir_dano"):
				objetivo.recibir_dano(dano_contacto)
			aplicar_impulso(-_direccion * 16.0)

		if _golpe_aplicado or _restante <= 0.0 or get_slide_collision_count() > 0:
			_recuperar()


func _preparar(rumbo: Vector3) -> void:
	_direccion = rumbo if not rumbo.is_zero_approx() else Vector3.FORWARD
	var factor_pred: float = [0.25, 0.42, 0.28][rol]
	var punto := _calcular_punto_intercepcion(factor_pred)
	_direccion = global_position.direction_to(punto)
	_orientar(_direccion)
	estado = Estado.PREPARAR
	_restante = _duracion_aviso
	_golpe_aplicado = false
	add_to_group("ataque_anunciado")
	if is_instance_valid(_senal):
		_senal.apuntar(global_position.distance_to(punto), rol != Rol.PERSEGUIDOR)


func _calcular_punto_intercepcion(factor: float) -> Vector3:
	if not is_instance_valid(objetivo):
		return global_position + _direccion * 10.0
	var punto := objetivo.global_position
	if objetivo is CharacterBody3D:
		punto += (objetivo as CharacterBody3D).velocity.limit_length(30.0) * factor
	return punto


func _sin_cobertura(destino: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position, destino, 8)
	q.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _orientar(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.RIGHT if absf(dir.y) > 0.98 else Vector3.UP)


func _disparar() -> void:
	var escena := get_tree().current_scene as Node3D
	if escena == null or BALA == null:
		return
	var bala := BALA.instantiate() as Proyectil
	if bala == null:
		return
	bala.hostil = true
	bala.velocidad = 34.0
	bala.vida_maxima = 2.2
	bala.configurar(_direccion, dano_contacto)
	escena.add_child(bala)
	bala.global_position = global_position + _direccion * 1.6


func _recuperar() -> void:
	if is_in_group("ataque_anunciado"):
		remove_from_group("ataque_anunciado")
	if is_instance_valid(_senal):
		_senal.apagar()
	estado = Estado.RECUPERAR
	_restante = [0.85, 1.35, 1.7][rol]


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
		EfectoCombate.crear(get_parent(), global_position, COLORES[rol], 1.25)
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
