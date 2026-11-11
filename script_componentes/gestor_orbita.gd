class_name GestorOrbita
extends Node

@export var planeta_actual: Node3D
@export var usa_propulsores: bool = false
@export var limite_mapa_global: float = 800.0

func procesar_limites(jugador: CharacterBody3D) -> void:
	# Si no se ha registrado un planeta por Area3D, buscar el más cercano automáticamente
	if not planeta_actual:
		_buscar_planeta_mas_cercano(jugador)

	if not usa_propulsores and planeta_actual:
		_aplicar_limite_orbital(jugador)
	
	_aplicar_limite_global(jugador)

func _aplicar_limite_orbital(jugador: CharacterBody3D) -> void:
	var centro := planeta_actual.global_position
	var desde_centro := jugador.global_position - centro
	var radio_maximo := _calcular_radio_efectivo()

	# Si sobrepasa el radio de la órbita del planeta actual
	if desde_centro.length() > radio_maximo:
		_rebotar_jugador(jugador, centro, desde_centro.normalized(), radio_maximo)

func _aplicar_limite_global(jugador: CharacterBody3D) -> void:
	var dist_centro := jugador.global_position.length()
	if dist_centro > limite_mapa_global:
		var dir_centro := -jugador.global_position.normalized()
		jugador.global_position = dir_centro * -limite_mapa_global
		jugador.velocity += dir_centro * 15.0

func _calcular_radio_efectivo() -> float:
	# Toma como base el radio físico del planeta multiplicado por su escala
	return 50.0 * planeta_actual.scale.x

func _rebotar_jugador(jugador: CharacterBody3D, centro: Vector3, dir: Vector3, radio: float) -> void:
	# Bloquea la posición en el borde de la esfera orbital y frena el impulso hacia afuera
	jugador.global_position = centro + dir * radio
	jugador.velocity = jugador.velocity.bounce(dir) * 0.1

func _buscar_planeta_mas_cercano(jugador: CharacterBody3D) -> void:
	var planetas := get_tree().get_nodes_in_group("planetas")
	if planetas.is_empty():
		return

	var mas_cercano: Node3D = null
	var menor_distancia := INF

	for p in planetas:
		if p is Node3D:
			var dist := jugador.global_position.distance_to(p.global_position)
			# Solo lo captura como planeta de órbita si está razonablemente cerca
			if dist < menor_distancia:
				menor_distancia = dist
				mas_cercano = p

	# Si está a menos del radio de influencia, lo asigna
	if mas_cercano and menor_distancia < (60.0 * mas_cercano.scale.x):
		planeta_actual = mas_cercano

## API de registro llamada desde Area3D del Planeta
func registrar_planeta_entrante(planeta: Node3D) -> void:
	planeta_actual = planeta

func registrar_planeta_saliente(planeta: Node3D) -> void:
	if planeta_actual == planeta:
		planeta_actual = null
