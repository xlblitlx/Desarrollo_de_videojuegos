class_name SpawnEnemigos
extends Node3D

signal enemigo_generado(enemigo: Node3D)
signal enemigo_destruido(posicion_global: Vector3)

@export var escena_enemigo: PackedScene
@export var intervalo_spawn: float = 3.0
@export var max_enemigos: int = 20
@export var activo: bool = true

@export_group("Configuración de Jefe")
@export var escena_jefe: PackedScene
@export var bajas_para_jefe: int = 20
@export var segundos_para_jefe: float = 90.0

var _bajas_acumuladas: int = 0
var _tiempo_transcurrido: float = 0.0
var _jefe_invocado: bool = false

@export_group("Zona de spawn en el planeta")
## Fracción del radio de ZonaOrbita donde empieza el spawn (0.0 = centro del planeta)
@export_range(0.0, 1.0) var fraccion_min: float = 0.55
## Fracción del radio de ZonaOrbita donde termina el spawn
@export_range(0.0, 1.0) var fraccion_max: float = 0.9
## Se usa solo si no se encuentra el radio de ZonaOrbita
@export var radio_respaldo: float = 40.0
@export var distancia_minima_jugador: float = 42.0

var _jugador: Node3D = null
var _timer: Timer


func _ready() -> void:
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D

	_timer = Timer.new()
	_timer.wait_time = intervalo_spawn
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()


func _on_timer_timeout() -> void:
	if not activo or escena_enemigo == null:
		return

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		if _jugador == null:
			push_warning("SpawnEnemigos: no hay ningún nodo en el grupo 'jugador'")
			return

	if get_tree().get_nodes_in_group("enemigos").size() >= max_enemigos:
		return

	var planeta := _obtener_planeta_cercano()
	if planeta == null:
		push_warning("SpawnEnemigos: no hay planetas en el grupo 'planetas'")
		return

	_generar_enemigo(planeta)


func _obtener_planeta_cercano() -> Node3D:
	var mejor: Node3D = null
	var mejor_distancia := INF
	for nodo in get_tree().get_nodes_in_group("planetas"):
		var planeta := nodo as Node3D
		if planeta == null:
			continue
		var distancia := planeta.global_position.distance_to(_jugador.global_position)
		if distancia < mejor_distancia:
			mejor_distancia = distancia
			mejor = planeta
	return mejor


func _obtener_radio_zona(planeta: Node3D) -> float:
	var zona := planeta.find_child("ZonaOrbita", true, false) as Node3D
	if zona == null:
		return radio_respaldo

	for hijo in zona.get_children():
		var colision := hijo as CollisionShape3D
		if colision and colision.shape is SphereShape3D:
			var escala := colision.global_transform.basis.get_scale().x
			return (colision.shape as SphereShape3D).radius * escala

	return radio_respaldo


func _generar_enemigo(planeta: Node3D) -> void:
	var enemigo := escena_enemigo.instantiate() as Node3D
	if enemigo == null:
		push_error("SpawnEnemigos: la raíz de la escena asignada no es un Node3D")
		return

	add_child(enemigo)
	var radio_zona := _obtener_radio_zona(planeta)
	enemigo.global_position = _posicion_en_planeta(planeta.global_position, radio_zona)

	if enemigo.has_method("establecer_objetivo"):
		enemigo.establecer_objetivo(_jugador)
	else:
		push_warning("SpawnEnemigos: el enemigo no tiene enemigo.gd asignado a la raíz")

	if enemigo.has_signal("destruido"):
		enemigo.destruido.connect(_on_enemigo_destruido)

	enemigo_generado.emit(enemigo)


func _posicion_en_planeta(centro: Vector3, radio_zona: float) -> Vector3:
	var mejor_pos := centro + Vector3.FORWARD * (radio_zona * fraccion_max)
	var mejor_dist_jugador := -1.0

	# Intenta hasta 12 posiciones en la órbita y se queda con la primera que esté lejos del jugador
	for i in range(12):
		var direccion := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		if direccion == Vector3.ZERO:
			direccion = Vector3.FORWARD

		var distancia := radio_zona * randf_range(fraccion_min, fraccion_max)
		var candidata := centro + direccion * distancia

		if not is_instance_valid(_jugador):
			return candidata

		var dist_jugador := candidata.distance_to(_jugador.global_position)
		if dist_jugador >= distancia_minima_jugador:
			return candidata

		if dist_jugador > mejor_dist_jugador:
			mejor_dist_jugador = dist_jugador
			mejor_pos = candidata

	return mejor_pos


func _on_enemigo_destruido(posicion: Vector3) -> void:
	enemigo_destruido.emit(posicion)

func invocar_jefe(escena_jefe: PackedScene) -> Node3D:
	if escena_jefe == null or not is_instance_valid(_jugador):
		return null

	var jefe := escena_jefe.instantiate() as Node3D
	if jefe == null:
		return null

	add_child(jefe)
	var angulo := randf() * TAU
	jefe.global_position = _jugador.global_position + Vector3(cos(angulo), 0.12, sin(angulo)) * 55.0

	if jefe.has_method("establecer_objetivo"):
		jefe.establecer_objetivo(_jugador)
	if jefe.has_signal("destruido"):
		jefe.destruido.connect(_on_enemigo_destruido)

	enemigo_generado.emit(jefe)
	return jefe
