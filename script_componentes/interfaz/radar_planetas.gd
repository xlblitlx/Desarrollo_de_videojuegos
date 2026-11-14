class_name RadarPlanetas
extends Control
## Proyecta indicadores direccionales en los bordes de pantalla para planetas y objetivos de evento.

@export var margen_borde: float = 32.0
@export var intervalo_refresco_cache: float = 1.0

var _indicadores: Dictionary = {} # { clave_unica: Control }
var _cache_planetas: Array[Node] = []
var _timer_refresco: float = 0.0


func _process(delta: float) -> void:
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return

	_timer_refresco -= delta
	if _timer_refresco <= 0.0 or _cache_planetas.is_empty():
		_cache_planetas = get_tree().get_nodes_in_group("planetas")
		_timer_refresco = intervalo_refresco_cache

	var tam_pantalla := get_viewport().get_visible_rect().size
	var centro := tam_pantalla * 0.5
	var rect_pantalla := Rect2(Vector2.ZERO, tam_pantalla)
	var claves_activas: Dictionary = {}

	# 1. Planetas del sistema
	for nodo in _cache_planetas:
		var planeta := nodo as Node3D
		if is_instance_valid(planeta):
			var clave := "P_%d" % planeta.get_instance_id()
			claves_activas[clave] = true
			var col: Color = planeta.obtener_color_estado() if planeta.has_method("obtener_color_estado") else Color(0.2, 0.92, 1.0, 0.9)
			_actualizar_marcador(clave, planeta.global_position, col, 1.0, camara, tam_pantalla, centro, rect_pantalla)

	# 2. Objetivos de eventos activos (balizas o planetas sobrecargados)
	for nodo in get_tree().get_nodes_in_group("puntos_interes"):
		var objetivo := nodo as Node3D
		if is_instance_valid(objetivo):
			var clave := "E_%d" % objetivo.get_instance_id()
			claves_activas[clave] = true
			_actualizar_marcador(clave, objetivo.global_position, Color(1.0, 0.85, 0.15, 1.0), 1.45, camara, tam_pantalla, centro, rect_pantalla)

	for clave_guardada in _indicadores.keys():
		if not claves_activas.has(clave_guardada):
			var viejo: Control = _indicadores[clave_guardada]
			if is_instance_valid(viejo):
				viejo.queue_free()
			_indicadores.erase(clave_guardada)


func _actualizar_marcador(
	clave: String,
	pos_3d: Vector3,
	color: Color,
	mult_escala: float,
	camara: Camera3D,
	tam_pantalla: Vector2,
	centro: Vector2,
	rect_pantalla: Rect2
) -> void:
	if not _indicadores.has(clave):
		_indicadores[clave] = _crear_indicador()

	var indicador: Control = _indicadores[clave]
	var detras_camara := camara.is_position_behind(pos_3d)
	var pos_2d := camara.unproject_position(pos_3d)
	if detras_camara:
		pos_2d = tam_pantalla - pos_2d

	var visible_en_pantalla := not detras_camara and rect_pantalla.has_point(pos_2d)
	indicador.visible = not visible_en_pantalla

	if indicador.visible:
		var dir := (pos_2d - centro).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP

		var limite_x := centro.x - margen_borde
		var limite_y := centro.y - margen_borde
		var escala_x := absf(limite_x / dir.x) if absf(dir.x) > 0.001 else 99999.0
		var escala_y := absf(limite_y / dir.y) if absf(dir.y) > 0.001 else 99999.0
		var pos_borde := centro + dir * minf(escala_x, escala_y)

		var dist_3d := camara.global_position.distance_to(pos_3d)
		var factor_escala := clampf(1.35 - (dist_3d / 350.0), 0.65, 1.35) * mult_escala
		indicador.scale = Vector2.ONE * factor_escala
		indicador.position = pos_borde - indicador.pivot_offset
		indicador.rotation = dir.angle()

		var poly := indicador.get_child(0) as Polygon2D
		if poly:
			poly.color = color


func _crear_indicador() -> Control:
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

	add_child(contenedor)
	return contenedor
