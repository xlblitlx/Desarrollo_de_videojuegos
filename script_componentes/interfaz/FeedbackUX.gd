class_name FeedbackUX
extends CanvasLayer
## Capa de UX reactiva: viñetas de daño, alerta de energía crítica, brújula al planeta cercano
## e indicadores de reserva energética proyectados sobre cada planeta.

@export var umbral_energia_baja: float = 25.0
@export var distancia_mostrar_info_planeta: float = 95.0

var _jugador: Node3D = null
var _camara: Camera3D = null
var _vida_anterior: float = -1.0
var _energia_anterior: float = -1.0
var _tiempo_alerta: float = 0.0

# Controles visuales
var _vineta_dano: ColorRect
var _vineta_energia: ColorRect
var _aviso_central: Label
var _flecha_planeta: Control
var _etiqueta_flecha: Label
var _controles_inicio: PanelContainer
var _contenedor_planetas: Control
var _widgets_planetas: Dictionary = {} # { Node3D: { panel, barra, texto } }


func _ready() -> void:
	layer = 15
	_construir_interfaz()
	await get_tree().process_frame
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
	_camara = get_viewport().get_camera_3d()


func _construir_interfaz() -> void:
	# 1. Viñeta roja de daño (borde de pantalla)
	_vineta_dano = _crear_overlay_borde(Color(0.95, 0.12, 0.18, 0.0))
	add_child(_vineta_dano)

	# 2. Viñeta ámbar de energía crítica
	_vineta_energia = _crear_overlay_borde(Color(1.0, 0.6, 0.1, 0.0))
	add_child(_vineta_energia)

	# 3. Contenedor para barras flotantes sobre los planetas
	_contenedor_planetas = Control.new()
	_contenedor_planetas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contenedor_planetas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_contenedor_planetas)

	# 4. Aviso central de estado crítico (ej. "¡ENERGÍA CRÍTICA!")
	_aviso_central = Label.new()
	_aviso_central.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso_central.offset_top = -135.0
	_aviso_central.offset_bottom = -105.0
	_aviso_central.offset_left = -260.0
	_aviso_central.offset_right = 260.0
	_aviso_central.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_central.add_theme_font_size_override("font_size", 15)
	_aviso_central.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_aviso_central.add_theme_constant_override("outline_size", 4)
	_aviso_central.visible = false
	add_child(_aviso_central)

	# 5. Indicador direccional hacia el planeta con carga más cercano
	_flecha_planeta = Control.new()
	_flecha_planeta.visible = false
	add_child(_flecha_planeta)

	_etiqueta_flecha = Label.new()
	_etiqueta_flecha.text = "▲ ÓRBITA SEGURA"
	_etiqueta_flecha.add_theme_font_size_override("font_size", 12)
	_etiqueta_flecha.modulate = Color("#48cae4")
	_etiqueta_flecha.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_etiqueta_flecha.add_theme_constant_override("outline_size", 3)
	_etiqueta_flecha.position = Vector2(-55, -24)
	_flecha_planeta.add_child(_etiqueta_flecha)

	# 6. Recordatorio rápido de controles (se desvanece a los 8s)
	_controles_inicio = PanelContainer.new()
	_controles_inicio.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_controles_inicio.offset_left = 20.0
	_controles_inicio.offset_bottom = -20.0
	_controles_inicio.offset_top = -78.0
	_controles_inicio.offset_right = 430.0
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#0c1a28cc")
	caja.border_color = Color("#395267")
	caja.set_border_width_all(1)
	caja.set_corner_radius_all(8)
	caja.content_margin_left = 12
	caja.content_margin_right = 12
	caja.content_margin_top = 8
	caja.content_margin_bottom = 8
	_controles_inicio.add_theme_stylebox_override("panel", caja)
	add_child(_controles_inicio)

	var lbl_guia := Label.new()
	lbl_guia.text = "[WASD] Volar  ·  [ESPACIO] Propulsor  ·  [CLIC] Disparar\nEntra en las órbitas de colores para recargar propulsor y casco"
	lbl_guia.add_theme_font_size_override("font_size", 12)
	lbl_guia.modulate = Color("#cbd8e0")
	_controles_inicio.add_child(lbl_guia)

	var tw := create_tween()
	tw.tween_interval(7.5)
	tw.tween_property(_controles_inicio, "modulate:a", 0.0, 1.2)
	tw.tween_callback(_controles_inicio.queue_free)


func _crear_overlay_borde(color_base: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = color_base

	# Shader ligero de viñeta radial para no tapar el centro de la pantalla
	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec2 uv = UV * 2.0 - 1.0;
		float dist = length(uv * vec2(0.85, 1.0));
		float borde = smoothstep(0.55, 1.25, dist);
		COLOR = vec4(COLOR.rgb, COLOR.a * borde);
	}
	"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	return rect


func _process(delta: float) -> void:
	_tiempo_alerta += delta
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		return
	if not is_instance_valid(_camara):
		_camara = get_viewport().get_camera_3d()

	_monitorear_jugador()
	_actualizar_indicadores_planetas()


func _monitorear_jugador() -> void:
	# Lee propiedades habituales del jugador (adapta los nombres si difieren en jugador.gd)
	var vida: float = _leer_propiedad(_jugador, ["vida_actual", "vida", "casco"], 100.0)
	var energia: float = _leer_propiedad(_jugador, ["energia_actual", "energia", "propulsor", "combustible"], 100.0)
	var energia_max: float = _leer_propiedad(_jugador, ["energia_maxima", "max_energia", "propulsor_maximo"], 100.0)
	var pct_energia := (energia / maxf(energia_max, 1.0)) * 100.0

	# Destello rojo cuando baja la vida
	if _vida_anterior >= 0.0 and vida < _vida_anterior - 0.1:
		_disparar_flash_dano()
	_vida_anterior = vida

	# Alerta pulsante cuando queda poca energía
	if pct_energia <= umbral_energia_baja:
		var pulso := 0.22 + 0.16 * sin(_tiempo_alerta * 7.0)
		_vineta_energia.color.a = pulso
		_aviso_central.visible = true
		if pct_energia <= 1.0:
			_aviso_central.text = "⚠ SIN ENERGÍA · RADIACIÓN DEL VACÍO"
			_aviso_central.modulate = Color("#ff4d6d")
		else:
			_aviso_central.text = "⚡ PROPULSOR BAJO (%d%%) · BUSCA UNA ÓRBITA" % int(pct_energia)
			_aviso_central.modulate = Color("#ffbe0b")
		_apuntar_a_planeta_disponible()
	else:
		_vineta_energia.color.a = lerpf(_vineta_energia.color.a, 0.0, 0.15)
		_aviso_central.visible = false
		_flecha_planeta.visible = false

	_energia_anterior = energia


func _disparar_flash_dano() -> void:
	_vineta_dano.color.a = 0.65
	var tw := create_tween()
	tw.tween_property(_vineta_dano, "color:a", 0.0, 0.38)

	# Pequeña sacudida de cámara para que el golpe se sienta físico
	if is_instance_valid(_camara):
		var orig_h := _camara.h_offset
		var orig_v := _camara.v_offset
		var tw_cam := create_tween()
		tw_cam.tween_property(_camara, "h_offset", orig_h + randf_range(-0.35, 0.35), 0.05)
		tw_cam.parallel().tween_property(_camara, "v_offset", orig_v + randf_range(-0.35, 0.35), 0.05)
		tw_cam.tween_property(_camara, "h_offset", orig_h, 0.08)
		tw_cam.parallel().tween_property(_camara, "v_offset", orig_v, 0.08)


func _apuntar_a_planeta_disponible() -> void:
	if not is_instance_valid(_camara):
		return
	var mejor_planeta: Node3D = null
	var mejor_dist := INF

	for p in get_tree().get_nodes_in_group("planetas"):
		if not (p is Node3D):
			continue
		var pct := _obtener_porcentaje_planeta(p)
		if pct <= 5.0:
			continue # Ignora planetas agotados
		var d := _jugador.global_position.distance_to(p.global_position)
		if d < mejor_dist:
			mejor_dist = d
			mejor_planeta = p

	if mejor_planeta == null or _camara.is_position_in_frustum(mejor_planeta.global_position):
		_flecha_planeta.visible = false
		return

	_flecha_planeta.visible = true
	var centro := get_viewport().get_visible_rect().size * 0.5
	var pos_2d := _camara.unproject_position(mejor_planeta.global_position)
	if _camara.is_position_behind(mejor_planeta.global_position):
		pos_2d = centro - (pos_2d - centro)

	var dir := (pos_2d - centro).normalized()
	_flecha_planeta.position = centro + dir * (minf(centro.x, centro.y) - 65.0)
	_etiqueta_flecha.text = "● ÓRBITA (%dm)" % int(mejor_dist)


func _actualizar_indicadores_planetas() -> void:
	if not is_instance_valid(_camara):
		return

	var activos: Array[Node] = get_tree().get_nodes_in_group("planetas")
	for p in activos:
		if not (p is Node3D):
			continue
		var planeta := p as Node3D
		if not _widgets_planetas.has(planeta):
			_widgets_planetas[planeta] = _crear_widget_planeta()

		var w: Dictionary = _widgets_planetas[planeta]
		var panel: Control = w["panel"]
		var dist := _jugador.global_position.distance_to(planeta.global_position)

		if dist > distancia_mostrar_info_planeta or _camara.is_position_behind(planeta.global_position):
			panel.visible = false
			continue

		var pos_pantalla := _camara.unproject_position(planeta.global_position + Vector3.UP * 28.0)
		panel.visible = true
		panel.position = pos_pantalla - Vector2(55.0, 18.0)

		var pct := _obtener_porcentaje_planeta(planeta)
		var barra: ProgressBar = w["barra"]
		var texto: Label = w["texto"]
		barra.value = pct

		if pct <= 1.0:
			texto.text = "ÓRBITA AGOTADA"
			texto.modulate = Color("#ff4d6d")
			barra.modulate = Color("#ff4d6d")
		elif pct < 35.0:
			texto.text = "RESERVA %d%%" % int(pct)
			texto.modulate = Color("#ffbe0b")
			barra.modulate = Color("#ffbe0b")
		else:
			texto.text = "ENERGÍA %d%%" % int(pct)
			texto.modulate = Color("#90e0ef")
			barra.modulate = Color("#48cae4")


func _crear_widget_planeta() -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(110.0, 28.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color("#0c1a28b8")
	caja.set_corner_radius_all(6)
	caja.content_margin_left = 6
	caja.content_margin_right = 6
	caja.content_margin_top = 3
	caja.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", caja)
	_contenedor_planetas.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var texto := Label.new()
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 10)
	vbox.add_child(texto)

	var barra := ProgressBar.new()
	barra.max_value = 100.0
	barra.custom_minimum_size = Vector2(0.0, 5.0)
	barra.show_percentage = false
	vbox.add_child(barra)

	return {"panel": panel, "barra": barra, "texto": texto}


func _obtener_porcentaje_planeta(planeta: Node) -> float:
	# Busca en el planeta o en su hijo ReservaOrbital
	var nodos := [planeta] + planeta.get_children()
	for n in nodos:
		var actual := _leer_propiedad(n, ["energia_actual", "reserva_actual", "carga_actual", "energia"], -1.0)
		var maximo := _leer_propiedad(n, ["energia_maxima", "reserva_maxima", "carga_maxima", "capacidad_maxima"], -1.0)
		if actual >= 0.0 and maximo > 0.0:
			return clampf((actual / maximo) * 100.0, 0.0, 100.0)
		var pct := _leer_propiedad(n, ["porcentaje", "porcentaje_energia", "factor_carga"], -1.0)
		if pct >= 0.0:
			return pct * 100.0 if pct <= 1.0 else pct
	return 100.0


func _leer_propiedad(obj: Object, nombres: Array[String], defecto: float) -> float:
	if obj == null:
		return defecto
	for nombre in nombres:
		if nombre in obj:
			var val = obj.get(nombre)
			if val is float or val is int:
				return float(val)
	return defecto
