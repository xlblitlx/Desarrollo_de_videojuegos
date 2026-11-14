class_name HUDJugador
extends CanvasLayer
## Gestiona únicamente las barras de estado y etiquetas textuales del jugador.

@onready var barra_vida: ProgressBar = find_child("BarraVida") as ProgressBar
@onready var barra_propulsor: ProgressBar = find_child("BarraPropulsor") as ProgressBar
@onready var etiqueta_estado: Label = find_child("EtiquetaEstado") as Label
@onready var etiqueta_nivel: Label = find_child("EtiquetaNivel") as Label
@onready var barra_experiencia: ProgressBar = find_child("BarraExperiencia") as ProgressBar
@onready var etiqueta_tiempo: Label = find_child("EtiquetaTiempo") as Label
@onready var etiqueta_evento: Label = find_child("EtiquetaEvento") as Label

var _sin_energia: bool = false
var _titulo_evento_actual: String = ""


func _ready() -> void:
	if EventosJuego:
		EventosJuego.evento_iniciado.connect(_al_iniciar_evento)
		EventosJuego.evento_progreso.connect(_al_progresar_evento)
		EventosJuego.evento_finalizado.connect(_al_finalizar_evento)
		EventosJuego.tiempo_supervivencia_actualizado.connect(_al_actualizar_tiempo)


func _al_iniciar_evento(_id: String, titulo: String, _objetivo: Node3D, _duracion: float) -> void:
	_titulo_evento_actual = titulo
	if etiqueta_evento:
		etiqueta_evento.text = titulo
		etiqueta_evento.modulate = Color.GOLD
		etiqueta_evento.visible = true


func _al_progresar_evento(texto_estado: String, _porcentaje: float) -> void:
	if etiqueta_evento and not texto_estado.is_empty():
		etiqueta_evento.text = "%s\n%s" % [_titulo_evento_actual, texto_estado]


func _al_finalizar_evento(_id: String, exito: bool) -> void:
	_titulo_evento_actual = ""
	if etiqueta_evento:
		if exito:
			etiqueta_evento.text = "✅ EVENTO COMPLETADO"
			etiqueta_evento.modulate = Color.SPRING_GREEN
			await get_tree().create_timer(2.5).timeout
		if is_instance_valid(etiqueta_evento) and _titulo_evento_actual.is_empty():
			etiqueta_evento.visible = false


func actualizar_vida(actual: float, maxima: float) -> void:
	if not is_node_ready():
		await ready
	if barra_vida:
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

func _al_actualizar_tiempo(segundos_totales: float, nivel_intensidad: int) -> void:
	if etiqueta_tiempo == null:
		return
	var total := int(segundos_totales)
	@warning_ignore("integer_division")
	var minutos := total / 60
	var segundos := total % 60
	etiqueta_tiempo.text = "⏱️ %02d:%02d" % [minutos, segundos]
	etiqueta_tiempo.modulate = Color.ORANGE_RED if nivel_intensidad >= 5 else Color.WHITE
