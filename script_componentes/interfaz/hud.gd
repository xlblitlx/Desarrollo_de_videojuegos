class_name HUDJugador
extends CanvasLayer

@onready var barra_vida: ProgressBar = $MarginContainer/VBoxContainer/BarraVida
@onready var barra_propulsor: ProgressBar = $MarginContainer/VBoxContainer/BarraPropulsor
@onready var etiqueta_estado: Label = $MarginContainer/VBoxContainer/EtiquetaEstado
@onready var etiqueta_nivel: Label = find_child("EtiquetaNivel") as Label
@onready var barra_experiencia: ProgressBar = find_child("BarraExperiencia") as ProgressBar

var _sin_energia: bool = false

func actualizar_vida(actual: float, maxima: float) -> void:
	if not is_node_ready():
		await ready
	barra_vida.max_value = maxima
	barra_vida.value = actual

func actualizar_propulsor(actual: float, maxima: float, agotado: bool) -> void:
	if not is_node_ready():
		await ready
	barra_propulsor.max_value = maxima
	barra_propulsor.value = actual
	_sin_energia = actual <= 0.0
	barra_propulsor.modulate = Color.ORANGE_RED if agotado else Color.WHITE

func actualizar_estado_orbita(en_espacio_abierto: bool) -> void:
	if not is_node_ready():
		await ready
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

func actualizar_experiencia(total: int, nivel: int) -> void:
	if not is_node_ready():
		await ready

	var inicio_nivel := GestorExperiencia.umbral_nivel(nivel)
	var siguiente_nivel := GestorExperiencia.umbral_nivel(nivel + 1)
	var requerido_en_nivel := maxf(1.0, float(siguiente_nivel - inicio_nivel))
	var progreso_actual := float(total - inicio_nivel)

	if etiqueta_nivel:
		etiqueta_nivel.text = "LVL %d  (%d / %d EXP)" % [nivel, int(progreso_actual), int(requerido_en_nivel)]

	if barra_experiencia:
		barra_experiencia.max_value = requerido_en_nivel
		barra_experiencia.value = progreso_actual
