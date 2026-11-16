class_name GestorRecompensas
extends Node
## Escucha destrucciones y crea orbes sin acoplarse a enemigos concretos.

signal orbe_recogido(valor: int)
signal orbe_generado(posicion: Vector3)

@export var jugador: CharacterBody3D
@export var contenedor_orbes: Node3D
@export var escena_orbe: PackedScene = preload("res://escenas/orbe.tscn")


func _ready() -> void:
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if contenedor_orbes == null:
		contenedor_orbes = get_tree().current_scene

	get_tree().node_added.connect(_nodo_agregado)
	call_deferred("_registrar_existentes")


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_nodo_agregado):
		get_tree().node_added.disconnect(_nodo_agregado)


func _registrar_existentes() -> void:
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		_conectar_enemigo(enemigo)


func _nodo_agregado(nodo: Node) -> void:
	call_deferred("_conectar_enemigo", nodo)


func _conectar_enemigo(nodo: Node) -> void:
	if not is_instance_valid(nodo) or nodo.is_queued_for_deletion():
		return
	if not nodo.is_in_group("enemigos") or not nodo.has_signal("destruido"):
		return
	var escuchar := Callable(self, "_enemigo_destruido")
	if not nodo.is_connected("destruido", escuchar):
		nodo.connect("destruido", escuchar)


func _enemigo_destruido(posicion: Vector3) -> void:
	if contenedor_orbes == null or escena_orbe == null:
		return

	var orbe := escena_orbe.instantiate() as Orbe
	if orbe == null:
		push_error("La escena del orbe debe tener Orbe en la raíz.")
		return
	orbe.jugador = jugador
	orbe.orbe_recogido.connect(_recibir_orbe)
	contenedor_orbes.add_child(orbe)
	orbe.global_position = posicion
	orbe_generado.emit(posicion)


func _recibir_orbe(valor: int) -> void:
	orbe_recogido.emit(valor)
