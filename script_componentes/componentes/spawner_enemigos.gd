class_name SpawnEnemigos
extends Node3D

signal enemigo_generado(enemigo: Node3D)
signal enemigo_destruido(posicion_global: Vector3)

@export var escena_enemigo: PackedScene
@export var intervalo_spawn: float = 2.4
@export var max_enemigos: int = 12
@export var activo: bool = true
@export var distancia_segura: float = 34.0

var intensidad: int = 1
var presupuesto: int = 8
var en_descanso: bool = false

var _jugador: Node3D = null
var _espera: float = 1.5
var _tiempo_partida: float = 0.0
var _presentados: Dictionary = {}
var _forma := SphereShape3D.new()


func _ready() -> void:
	add_to_group("generador_enemigos")
	_forma.radius = 3.6


func _physics_process(delta: float) -> void:
	if not activo or escena_enemigo == null:
		return

	# Escalado automático de intensidad y presupuesto con el tiempo de partida
	_tiempo_partida += delta
	intensidad = clampi(1 + int(_tiempo_partida / 35.0), 1, 5)
	presupuesto = 8 + (intensidad - 1) * 4

	_espera -= delta
	if _espera > 0.0:
		return
	_espera = intervalo_spawn * (1.7 if en_descanso else 1.0)

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		if _jugador == null:
			return

	var grupo := get_tree().get_nodes_in_group("enemigos")
	var ocupados := 0
	for nodo in grupo:
		if nodo is Enemigo:
			ocupados += Enemigo.COSTES[(nodo as Enemigo).rol]
		else:
			ocupados += 1

	var cantidad := 2 if intensidad >= 4 and not en_descanso else 1
	for i in range(cantidad):
		if grupo.size() >= max_enemigos or ocupados >= presupuesto:
			break
		var rol := _elegir_rol(presupuesto - ocupados)
		var posicion := _buscar_posicion(grupo)
		if posicion == Vector3.INF:
			break

		var nave := escena_enemigo.instantiate() as Enemigo
		if nave == null:
			break
		nave.rol = rol
		nave.establecer_objetivo(_jugador)
		nave.destruido.connect(_notificar_baja)
		add_child(nave)
		nave.global_position = posicion

		_presentados[rol] = true
		enemigo_generado.emit(nave)
		ocupados += Enemigo.COSTES[rol]
		grupo.append(nave)


func _elegir_rol(disponible: int) -> Enemigo.Rol:
	var dado := randf()
	if intensidad >= 3 and disponible >= 3 and (not _presentados.has(Enemigo.Rol.ARTILLERO) or dado < 0.24):
		return Enemigo.Rol.ARTILLERO
	if intensidad >= 2 and disponible >= 2 and (not _presentados.has(Enemigo.Rol.EMBESTIDOR) or dado < 0.54):
		return Enemigo.Rol.EMBESTIDOR
	return Enemigo.Rol.PERSEGUIDOR


func _buscar_posicion(ocupantes: Array) -> Vector3:
	if not is_instance_valid(_jugador):
		return Vector3.INF
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = _forma
	consulta.collision_mask = 11
	var espacio := get_world_3d().direct_space_state
	var centro := _jugador.global_position

	for intento in range(24):
		var azimut := randf() * TAU
		var rumbo := Vector3(cos(azimut), randf_range(-0.44, 0.58), sin(azimut)).normalized()
		var punto := centro + rumbo * randf_range(distancia_segura, distancia_segura + 22.0)
		if punto.length() > 840.0:
			continue
		consulta.transform.origin = punto
		if not espacio.intersect_shape(consulta, 1).is_empty():
			continue
		var libre := true
		for enemigo in ocupantes:
			if is_instance_valid(enemigo) and (enemigo as Node3D).global_position.distance_squared_to(punto) < 64.0:
				libre = false
				break
		if libre:
			return punto
	return Vector3.INF


func invocar_jefe(escena_jefe: PackedScene) -> Node3D:
	if escena_jefe == null:
		return null
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D

	var jefe := escena_jefe.instantiate() as Node3D
	if jefe == null:
		return null

	var posicion := _buscar_posicion(get_tree().get_nodes_in_group("enemigos"))
	if posicion == Vector3.INF and is_instance_valid(_jugador):
		posicion = _jugador.global_position + Vector3(0.0, 8.0, -distancia_segura)

	if jefe.has_method("establecer_objetivo") and is_instance_valid(_jugador):
		jefe.establecer_objetivo(_jugador)

	add_child(jefe)
	jefe.global_position = posicion
	return jefe


func _notificar_baja(posicion: Vector3) -> void:
	enemigo_destruido.emit(posicion)
