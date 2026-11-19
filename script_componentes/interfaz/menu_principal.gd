class_name MenuPrincipal
extends Control
## Menú de inicio: Jugar, controles en pantalla y Salir.

@export_file("*.tscn") var escena_juego: String = "res://Demo_Orbital.tscn"

@onready var boton_jugar: Button = find_child("BotonJugar") as Button
@onready var boton_salir: Button = find_child("BotonSalir") as Button


func _ready() -> void:
	# Al venir de una partida el ratón puede estar capturado o el árbol pausado
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	boton_jugar.pressed.connect(_al_pulsar_jugar)
	boton_salir.pressed.connect(_al_pulsar_salir)
	boton_jugar.grab_focus()


func _al_pulsar_jugar() -> void:
	get_tree().change_scene_to_file(escena_juego)


func _al_pulsar_salir() -> void:
	get_tree().quit()
