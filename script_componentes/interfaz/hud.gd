class_name HUDJugador
extends CanvasLayer
## Gestiona las barras de estado, tarjeta táctil y etiquetas del jugador.

const COLOR_FONDO := Color("#0c1a28eb")
const COLOR_BORDE := Color("#395267")
const COLOR_BARRA_FONDO := Color("#263948")
const COLOR_CIAN := Color("#5ce6f5")
const COLOR_AMBAR := Color("#f5be6b")
const COLOR_LAVANDA := Color("#b5a5fa")
const COLOR_ROJO := Color("#ff6b7a")
const COLOR_TEXTO := Color("#e8f1f5")
const AVISOS_ROL := ["Golpe cercano", "Embestida", "Disparo dirigido"]

@onready var instrumentos: PanelContainer = find_child("Instrumentos") as PanelContainer
@onready var barra_vida: ProgressBar = find_child("BarraVida") as ProgressBar
@onready var barra_propulsor: ProgressBar = find_child("BarraPropulsor") as ProgressBar
@onready var barra_experiencia: ProgressBar = find_child("BarraExperiencia") as ProgressBar
@onready var etiqueta_estado: Label = find_child("EtiquetaEstado") as Label
@onready var etiqueta_nivel: Label = find_child("EtiquetaNivel") as Label
@onready var etiqueta_tiempo: Label = find_child("EtiquetaTiempo") as Label
@onready var etiqueta_evento: Label = find_child("EtiquetaEvento") as Label
@onready var casco: Label = find_child("Casco") as Label
@onready var motor: Label = find_child("Motor") as Label
@onready var amenaza: Label = find_child("Amenaza") as Label

var _sin_energia: bool = false
var _titulo_evento_actual: String = ""
var _jugador: Node3D
var _refresco: float = 0.0


func _ready() -> void:
	_aplicar_estilo_visual()

	if EventosJuego:
		EventosJuego.evento_iniciado.connect(_al_iniciar_evento)
		EventosJuego.evento_progreso.connect(_al_progresar_evento)
		EventosJuego.evento_finalizado.connect(_al_finalizar_evento)
		EventosJuego.tiempo_supervivencia_actualizado.connect(_al_actualizar_tiempo)

	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D


func _aplicar_estilo_visual() -> void:
	if instrumentos:
		instrumentos.custom_minimum_size = Vector2(215.0, 0.0)
		instrumentos.add_theme_stylebox_override(
			"panel",
			_crear_caja(COLOR_FONDO, COLOR_BORDE, 1, 10, 12, 10)
		)

	var pares := [
		[barra_vida, COLOR_CIAN],
		[barra_propulsor, COLOR_AMBAR],
		[barra_experiencia, COLOR_LAVANDA]
	]
	for par in pares:
		var barra := par[0] as ProgressBar
		var color_relleno: Color = par[1]
		if barra:
			barra.show_percentage = false
			barra.custom_minimum_size = Vector2(190.0, 6.0)
			barra.add_theme_stylebox_override("background", _crear_caja(COLOR_BARRA_FONDO, Color.TRANSPARENT, 0, 3))
			barra.add_theme_stylebox_override("fill", _crear_caja(color_relleno, Color.TRANSPARENT, 0, 3))

	if barra_vida and barra_vida.get_parent() is VBoxContainer:
		(barra_vida.get_parent() as VBoxContainer).add_theme_constant_override("separation", 4)

	for lbl in [casco, motor, etiqueta_nivel]:
		if lbl:
			lbl.add_theme_font_size_override("font_size", 12)

	if etiqueta_estado:
		etiqueta_estado.add_theme_font_size_override("font_size", 11)

	for etiqueta in [etiqueta_tiempo, etiqueta_evento, amenaza]:
		if etiqueta:
			etiqueta.add_theme_constant_override("outline_size", 4)
			etiqueta.add_theme_color_override("font_outline_color", Color("#09121f"))


func _crear_caja(fondo: Color, borde: Color, grosor_borde: int, radio: int, margen_h: int = 0, margen_v: int = 0) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(grosor_borde)
	caja.set_corner_radius_all(radio)
	if margen_h > 0 or margen_v > 0:
		caja.content_margin_left = margen_h
		caja.content_margin_right = margen_h
		caja.content_margin_top = margen_v
		caja.content_margin_bottom = margen_v
	return caja


func _process(delta: float) -> void:
	if amenaza == null:
		return
	_refresco -= delta
	if _refresco > 0.0:
		return
	_refresco = 0.07

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		if _jugador == null:
			amenaza.visible = false
			return

	var cerca: EnemigoBase = null
	var distancia := INF
	for nodo in get_tree().get_nodes_in_group("ataque_anunciado"):
		if nodo is EnemigoBase:
			var nave := nodo as EnemigoBase
			var actual := _jugador.global_position.distance_to(nave.global_position)
			if actual < distancia:
				distancia = actual
				cerca = nave

	amenaza.visible = is_instance_valid(cerca)
	if cerca:
		var local := _jugador.to_local(cerca.global_position)
		var lado := "delante" if local.z < 0.0 else "detrás"
		if absf(local.x) > absf(local.z):
			lado = "derecha" if local.x > 0.0 else "izquierda"
		var idx := clampi(cerca.indice_senal, 0, AVISOS_ROL.size() - 1)
		amenaza.text = "%s  ·  %s" % [AVISOS_ROL[idx].to_upper(), lado]
		amenaza.modulate = cerca.color_rol


func actualizar_vida(actual: float, maxima: float) -> void:
	if not is_node_ready():
		await ready
	if barra_vida:
		barra_vida.max_value = maxima
		barra_vida.value = actual
	if casco:
		casco.text = "CASCO   %d / %d" % [ceili(actual), int(maxima)]
		casco.modulate = COLOR_ROJO if actual < maxima * 0.3 else COLOR_TEXTO


func actualizar_propulsor(actual: float, maxima: float, agotado: bool) -> void:
	if not is_node_ready():
		await ready
	if barra_propulsor:
		barra_propulsor.max_value = maxima
		barra_propulsor.value = actual
		barra_propulsor.modulate = Color.ORANGE_RED if agotado else Color.WHITE
	_sin_energia = actual <= 0.0
	if motor:
		motor.text = "PROPULSOR   %d%%" % roundi(100.0 * actual / maxf(1.0, maxima))
		motor.modulate = COLOR_ROJO if agotado else COLOR_TEXTO


func actualizar_estado_orbita(en_espacio_abierto: bool) -> void:
	if not is_node_ready():
		await ready
	if etiqueta_estado == null:
		return
	if en_espacio_abierto:
		if _sin_energia:
			etiqueta_estado.text = "SIN ENERGÍA · RADIACIÓN CRÍTICA"
			etiqueta_estado.modulate = COLOR_ROJO
		else:
			etiqueta_estado.text = "ESPACIO ABIERTO · ESCUDO ACTIVO"
			etiqueta_estado.modulate = COLOR_AMBAR
	else:
		etiqueta_estado.text = "ÓRBITA SEGURA · RECARGANDO"
		etiqueta_estado.modulate = COLOR_CIAN


func actualizar_experiencia(total: int, nivel: int) -> void:
	if not is_node_ready():
		await ready

	var inicio_nivel := GestorExperiencia.umbral_nivel(nivel)
	var siguiente_nivel := GestorExperiencia.umbral_nivel(nivel + 1)
	var requerido_en_nivel := maxf(1.0, float(siguiente_nivel - inicio_nivel))
	var progreso_actual := float(total - inicio_nivel)

	if etiqueta_nivel:
		etiqueta_nivel.text = "NIVEL %d   %d / %d EXP" % [nivel, int(progreso_actual), int(requerido_en_nivel)]
		etiqueta_nivel.modulate = COLOR_TEXTO

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
	etiqueta_tiempo.text = "%02d:%02d" % [minutos, segundos]
	etiqueta_tiempo.modulate = COLOR_ROJO if nivel_intensidad >= 5 else COLOR_TEXTO


func _al_iniciar_evento(_id: String, titulo: String, _objetivo: Node3D, _duracion: float) -> void:
	_titulo_evento_actual = titulo
	if etiqueta_evento:
		etiqueta_evento.text = titulo
		etiqueta_evento.modulate = COLOR_AMBAR
		etiqueta_evento.visible = true


func _al_progresar_evento(texto_estado: String, _porcentaje: float) -> void:
	if etiqueta_evento and not texto_estado.is_empty():
		etiqueta_evento.text = "%s\n%s" % [_titulo_evento_actual, texto_estado]


func _al_finalizar_evento(_id: String, exito: bool) -> void:
	_titulo_evento_actual = ""
	if etiqueta_evento:
		if exito:
			etiqueta_evento.text = "EVENTO COMPLETADO"
			etiqueta_evento.modulate = COLOR_CIAN
			await get_tree().create_timer(2.5).timeout
		if is_instance_valid(etiqueta_evento) and _titulo_evento_actual.is_empty():
			etiqueta_evento.visible = false
