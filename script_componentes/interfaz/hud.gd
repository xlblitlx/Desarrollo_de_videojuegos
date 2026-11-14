class_name HUDJugador
extends CanvasLayer

@onready var barra_vida: ProgressBar = $MarginContainer/VBoxContainer/BarraVida
@onready var barra_propulsor: ProgressBar = $MarginContainer/VBoxContainer/BarraPropulsor
@onready var etiqueta_estado: Label = $MarginContainer/VBoxContainer/EtiquetaEstado
@onready var etiqueta_nivel: Label = find_child("EtiquetaNivel") as Label
@onready var barra_experiencia: ProgressBar = find_child("BarraExperiencia") as ProgressBar

var _sin_energia: bool = false

@onready var radar_planetas: Control = get_node_or_null("RadarPlanetas")

var _indicadores_planetas: Dictionary = {} # { instance_id: Control }
var _cache_planetas: Array[Node] = []
var _timer_refresco_planetas: float = 0.0


func _process(delta: float) -> void:
	_actualizar_radar_planetas(delta)


func _actualizar_radar_planetas(delta: float) -> void:
	if radar_planetas == null:
		return

	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return

	# Refresca la lista de planetas cada 1.0 s en lugar de buscar en el árbol cada frame
	_timer_refresco_planetas -= delta
	if _timer_refresco_planetas <= 0.0 or _cache_planetas.is_empty():
		_cache_planetas = get_tree().get_nodes_in_group("planetas")
		_timer_refresco_planetas = 1.0

	var tam_pantalla := get_viewport().get_visible_rect().size
	var centro := tam_pantalla * 0.5
	var margen := 32.0
	var rect_pantalla := Rect2(Vector2.ZERO, tam_pantalla)

	# Limpia indicadores de planetas que ya no existan
	var ids_activos: Dictionary = {}

	for nodo in _cache_planetas:
		var planeta := nodo as Node3D
		if not is_instance_valid(planeta):
			continue

		var id := planeta.get_instance_id()
		ids_activos[id] = true

		if not _indicadores_planetas.has(id):
			_indicadores_planetas[id] = _crear_indicador_planeta()

		var indicador: Control = _indicadores_planetas[id]

		# Si el planeta está detrás de la cámara, invierte la proyección para apuntar hacia atrás
		var detras_camara := camara.is_position_behind(planeta.global_position)
		var pos_2d := camara.unproject_position(planeta.global_position)
		if detras_camara:
			pos_2d = tam_pantalla - pos_2d

		var visible_en_pantalla := not detras_camara and rect_pantalla.has_point(pos_2d)
		indicador.visible = not visible_en_pantalla

		if indicador.visible:
			var dir := (pos_2d - centro).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.UP

			var limite_x := centro.x - margen
			var limite_y := centro.y - margen
			var escala_x := absf(limite_x / dir.x) if absf(dir.x) > 0.001 else 99999.0
			var escala_y := absf(limite_y / dir.y) if absf(dir.y) > 0.001 else 99999.0
			var pos_borde := centro + dir * minf(escala_x, escala_y)

			# Escala ligeramente el marcador según cercanía (más grande = planeta más cercano)
			var dist_3d := camara.global_position.distance_to(planeta.global_position)
			var factor_escala := clampf(1.35 - (dist_3d / 350.0), 0.65, 1.35)
			indicador.scale = Vector2.ONE * factor_escala
			indicador.position = pos_borde - indicador.pivot_offset
			indicador.rotation = dir.angle()

	# Elimina marcadores huérfanos si se regenera el mapa
	for id_guardado in _indicadores_planetas.keys():
		if not ids_activos.has(id_guardado):
			var viejo: Control = _indicadores_planetas[id_guardado]
			if is_instance_valid(viejo):
				viejo.queue_free()
			_indicadores_planetas.erase(id_guardado)


func _crear_indicador_planeta() -> Control:
	# Dibuja un rombo/flecha cian ligero sin depender de texturas externas
	var marcador := Polygon2D.new()
	marcador.polygon = PackedVector2Array([
		Vector2(10, 0),
		Vector2(-6, -6),
		Vector2(-3, 0),
		Vector2(-6, 6)
	])
	marcador.color = Color(0.2, 0.92, 1.0, 0.9)

	var contenedor := Control.new()
	contenedor.size = Vector2(20, 20)
	contenedor.pivot_offset = Vector2(10, 10)
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor.add_child(marcador)
	marcador.position = Vector2(10, 10)

	radar_planetas.add_child(contenedor)
	return contenedor

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
