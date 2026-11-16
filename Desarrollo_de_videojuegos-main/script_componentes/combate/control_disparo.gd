class_name ControlDisparo
extends Node3D
## Busca el enemigo más cercano y dispara automáticamente (estilo Vampire Survivors).

signal disparo_realizado(destino: Node3D)

@export var jugador: CharacterBody3D
@export var contenedor_proyectiles: Node3D
@export var escena_proyectil: PackedScene = preload("res://escenas/proyectil.tscn")
@export var intervalo: float = 0.85
@export var alcance: float = 30.0
@export var dano: float = 5.0
@export var altura_salida: float = 0.2
@export var cantidad_proyectiles: int = 1
@export var angulo_abanico_grados: float = 12.0

var _espera: float = 0.0


func _ready() -> void:
	# Si no se asignaron en el Inspector, busca al padre (Jugador) y la raíz de la escena
	if jugador == null:
		jugador = get_parent() as CharacterBody3D
	if contenedor_proyectiles == null:
		contenedor_proyectiles = get_tree().current_scene


func _physics_process(delta: float) -> void:
	if jugador == null or contenedor_proyectiles == null or escena_proyectil == null:
		return

	_espera = maxf(0.0, _espera - delta)
	if _espera > 0.0:
		return

	var enemigo := _encontrar_enemigo()
	if enemigo == null:
		return

	_disparar(enemigo)
	_espera = maxf(intervalo, 0.05)


func _encontrar_enemigo() -> Node3D:
	var objetivo: Node3D = null
	var distancia_minima := alcance * alcance

	for nodo in get_tree().get_nodes_in_group("enemigos"):
		if not nodo is Node3D or nodo.is_queued_for_deletion():
			continue
		var candidato := nodo as Node3D
		var distancia := jugador.global_position.distance_squared_to(candidato.global_position)
		if distancia < distancia_minima:
			objetivo = candidato
			distancia_minima = distancia

	return objetivo


func _disparar(enemigo: Node3D) -> void:
	var origen := jugador.global_position + Vector3.UP * altura_salida
	var dir_base := (enemigo.global_position - origen).normalized()
	if dir_base == Vector3.ZERO:
		return

	var total := maxi(1, cantidad_proyectiles)
	var paso_rad := deg_to_rad(angulo_abanico_grados)
	var angulo_inicial := -paso_rad * float(total - 1) * 0.5

	for i in range(total):
		var proyectil := escena_proyectil.instantiate() as Proyectil
		if proyectil == null:
			continue

		var rotacion := angulo_inicial + paso_rad * float(i)
		var dir_final := dir_base.rotated(Vector3.UP, rotacion).normalized()

		proyectil.configurar(dir_final, dano)
		contenedor_proyectiles.add_child(proyectil)
		proyectil.global_position = origen + dir_final * 1.4

	disparo_realizado.emit(enemigo)
