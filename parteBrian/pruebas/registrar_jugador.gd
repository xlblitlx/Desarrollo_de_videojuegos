extends Node
## Habilita el grupo del jugador solo dentro de la escena de integracion.

@export var jugador: CharacterBody3D


func _ready() -> void:
    if jugador != null:
        jugador.add_to_group("jugador")
