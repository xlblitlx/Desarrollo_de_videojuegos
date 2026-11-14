class_name GestorOrbita
extends Node

@export var planeta_actual: Node3D
@export var usa_propulsores: bool = false
@export var limite_mapa_global: float = 850.0  # Ligeramente mayor que radio_sistema_global (800)

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
		if usa_propulsores:
			# Rompe la atmósfera al cruzar el borde con el propulsor activo
			planeta_actual = null
		else:
			# Rebota contra la cúpula si no lleva propulsores
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
