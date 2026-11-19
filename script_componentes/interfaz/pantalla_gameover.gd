class_name PantallaGameOver
extends CanvasLayer
## Pantalla de resumen (derrota o victoria). Solo muestra datos y emite señales
## cuando el jugador elige una opción; GestorPartida decide qué hacer.

signal reinicio_solicitado
signal menu_solicitado

@onready var titulo: Label = find_child("Titulo") as Label
@onready var linea_tiempo: Label = find_child("LineaTiempo") as Label
@onready var linea_nivel: Label = find_child("LineaNivel") as Label
@onready var linea_bajas: Label = find_child("LineaBajas") as Label
@onready var linea_oleada: Label = find_child("LineaOleada") as Label
@onready var boton_reiniciar: Button = find_child("BotonReiniciar") as Button
@onready var boton_menu: Button = find_child("BotonMenu") as Button


func _ready() -> void:
	# Debe seguir funcionando con el árbol en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	boton_reiniciar.pressed.connect(func() -> void: reinicio_solicitado.emit())
	boton_menu.pressed.connect(func() -> void: menu_solicitado.emit())


func mostrar(estadisticas: Dictionary, victoria: bool) -> void:
	if victoria:
		titulo.text = "¡VICTORIA!"
		titulo.modulate = Color.GOLD
	else:
		titulo.text = "NAVE DESTRUIDA"
		titulo.modulate = Color.TOMATO

	var total := int(estadisticas.get("tiempo", 0.0))
	@warning_ignore("integer_division")
	linea_tiempo.text = "Tiempo sobrevivido: %02d:%02d" % [total / 60, total % 60]
	linea_nivel.text = "Nivel alcanzado: %d" % int(estadisticas.get("nivel", 1))
	linea_bajas.text = "Enemigos eliminados: %d" % int(estadisticas.get("bajas", 0))
	linea_oleada.text = "Oleada: %d" % int(estadisticas.get("oleada", 1))

	visible = true
	boton_reiniciar.grab_focus()
