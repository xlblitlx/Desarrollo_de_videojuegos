class_name HUDJugador
extends CanvasLayer

@onready var barra_vida: ProgressBar = $MarginContainer/VBoxContainer/BarraVida
@onready var barra_propulsor: ProgressBar = $MarginContainer/VBoxContainer/BarraPropulsor
@onready var etiqueta_estado: Label = $MarginContainer/VBoxContainer/EtiquetaEstado

var _sin_energia: bool = false

func actualizar_vida(actual: float, maxima: float) -> void:
	barra_vida.max_value = maxima
	barra_vida.value = actual


func actualizar_propulsor(actual: float, maxima: float, agotado: bool) -> void:
	barra_propulsor.max_value = maxima
	barra_propulsor.value = actual
	_sin_energia = actual <= 0.0
	barra_propulsor.modulate = Color.ORANGE_RED if agotado else Color.WHITE


func actualizar_estado_orbita(en_espacio_abierto: bool) -> void:
	if en_espacio_abierto:
		if _sin_energia:
			etiqueta_estado.text = "⚠️ SIN ENERGÍA - RADIACIÓN CRÍTICA"
			etiqueta_estado.modulate = Color.TOMATO
		else:
			etiqueta_estado.text = "🚀 ESPACIO ABIERTO (ESCUDO ACTIVO)"
			etiqueta_estado.modulate = Color.GOLD
	else:
		etiqueta_estado.text = "🛡️ ÓRBITA SEGURA (RECARGANDO)"
		etiqueta_estado.modulate = Color.CYAN
