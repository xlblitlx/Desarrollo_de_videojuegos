class_name GestorOrbita
extends Node

@export var planeta_actual: Node3D
@export var radio_maximo: float = 40.0
@export var usa_propulsores: bool = false

func _ready() -> void:
	if not planeta_actual and get_tree().current_scene.has_node("Planeta"):
		planeta_actual = get_tree().current_scene.get_node("Planeta")

## Revisa si la nave superó el radio y corrige su posición
func aplicar_limite(jugador: CharacterBody3D) -> void:
	if planeta_actual and not usa_propulsores:
		var vector_desde_centro = jugador.global_position - planeta_actual.global_position
		var distancia_actual = vector_desde_centro.length()
		
		if distancia_actual > radio_maximo:
			jugador.global_position = planeta_actual.global_position + vector_desde_centro.normalized() * radio_maximo
			jugador.velocity = jugador.velocity.bounce(vector_desde_centro.normalized()) * 0.2
