class_name FeedbackUX
extends CanvasLayer
## Capa de interfaz 2D reactiva: viñetas de daño y vacío, avisos de estado,
## progreso de ruptura orbital, brújula de rescate y panel planetario.

@export var umbral_energia_baja: float = 40.0
@export var distancia_info_planeta: float = 85.0

var _jugador: Node3D = null
var _camara: Camera3D = null
var _alerta_sonora: AlertaSonora = null
var _vida_anterior: float = -1.0
var _tiempo_alerta: float = 0.0

# Controles visuales HUD
var _vineta_dano: ColorRect
var _vineta_energia: ColorRect
var _aviso_central: Label
var _flecha_planeta: Control
var _etiqueta_flecha: Label

# Panel HUD de información del planeta
var _panel_planeta: PanelContainer
var _lbl_tipo_planeta: Label
var _lbl_estado_orbita: Label
var _lbl_efecto_planeta: Label
var _lbl_alerta_planeta: Label
var _barra_energia_planeta: ProgressBar
var _lbl_pct_planeta: Label


func _ready() -> void:
	layer = 15
	_construir_interfaz()

	# Usa el nodo hijo AlertaSonora si existe en escena, o lo crea automáticamente
	_alerta_sonora = get_node_or_null("AlertaSonora") as AlertaSonora
	if _alerta_sonora == null:
		_alerta_sonora = AlertaSonora.new()
		_alerta_sonora.name = "AlertaSonora"
		add_child(_alerta_sonora)

	await get_tree().process_frame
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
	_camara = get_viewport().get_camera_3d()
	if is_instance_valid(_jugador) and _jugador.get_node_or_null("EfectosDanoNave") == null:
		var efectos := EfectosDanoNave.new()
		efectos.name = "EfectosDanoNave"
		_jugador.add_child(efectos)


func _construir_interfaz() -> void:
	# 1. Viñeta roja de daño / muerte en el vacío
	_vineta_dano = _crear_overlay_borde(Color(0.95, 0.12, 0.18, 0.0))
	add_child(_vineta_dano)

	# 2. Viñeta ámbar de energía baja
	_vineta_energia = _crear_overlay_borde(Color(1.0, 0.6, 0.1, 0.0))
	add_child(_vineta_energia)

	# 3. Tarjeta de planeta en la esquina inferior izquierda
	_construir_panel_planeta()

	# 4. Aviso central en pantalla
	_aviso_central = Label.new()
	_aviso_central.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso_central.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso_central.offset_top = -135.0
	_aviso_central.offset_bottom = -100.0
	_aviso_central.offset_left = -320.0
	_aviso_central.offset_right = 320.0
	_aviso_central.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_central.add_theme_font_size_override("font_size", 16)
	_aviso_central.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_aviso_central.add_theme_constant_override("outline_size", 5)
	_aviso_central.visible = false
	add_child(_aviso_central)

	# 5. Indicador direccional hacia el planeta con carga más cercano
	_flecha_planeta = Control.new()
	_flecha_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flecha_planeta.visible = false
	add_child(_flecha_planeta)

	_etiqueta_flecha = Label.new()
	_etiqueta_flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_etiqueta_flecha.text = "● SIGUIENTE ÓRBITA"
	_etiqueta_flecha.add_theme_font_size_override("font_size", 12)
	_etiqueta_flecha.modulate = Color("#48cae4")
	_etiqueta_flecha.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_etiqueta_flecha.add_theme_constant_override("outline_size", 3)
	_etiqueta_flecha.position = Vector2(-65, -24)
	_flecha_planeta.add_child(_etiqueta_flecha)


func _construir_panel_planeta() -> void:
	_panel_planeta = PanelContainer.new()
	_panel_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_planeta.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_panel_planeta.offset_left = 20.0
	_panel_planeta.offset_right = 292.0
	_panel_planeta.offset_bottom = -20.0
	_panel_planeta.offset_top = -112.0
	_panel_planeta.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel_planeta.visible = false
	_panel_planeta.add_theme_stylebox_override("panel", _crear_caja(Color("#0c1a28de"), Color("#395267"), 1, 8, 12, 9))
	add_child(_panel_planeta)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 5)
	_panel_planeta.add_child(vbox)

	var fila_sup := HBoxContainer.new()
	fila_sup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(fila_sup)

	_lbl_tipo_planeta = Label.new()
	_lbl_tipo_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_tipo_planeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_tipo_planeta.add_theme_font_size_override("font_size", 12)
	_lbl_tipo_planeta.text = "PLANETA ESTÁNDAR"
	fila_sup.add_child(_lbl_tipo_planeta)

	_lbl_estado_orbita = Label.new()
	_lbl_estado_orbita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_estado_orbita.add_theme_font_size_override("font_size", 11)
	_lbl_estado_orbita.modulate = Color("#9fb3c8")
	fila_sup.add_child(_lbl_estado_orbita)

	_lbl_efecto_planeta = Label.new()
	_lbl_efecto_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_efecto_planeta.add_theme_font_size_override("font_size", 11)
	_lbl_efecto_planeta.modulate = Color("#d9e2ec")
	_lbl_efecto_planeta.text = "Recarga propulsor (1.0x)"
	vbox.add_child(_lbl_efecto_planeta)

	var fila_barra := HBoxContainer.new()
	fila_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_barra.add_theme_constant_override("separation", 8)
	vbox.add_child(fila_barra)

	_barra_energia_planeta = ProgressBar.new()
	_barra_energia_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_energia_planeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barra_energia_planeta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_barra_energia_planeta.custom_minimum_size = Vector2(0.0, 7.0)
	_barra_energia_planeta.max_value = 100.0
	_barra_energia_planeta.show_percentage = false
	_barra_energia_planeta.add_theme_stylebox_override("background", _crear_caja(Color("#263948"), Color.TRANSPARENT, 0, 3))
	_barra_energia_planeta.add_theme_stylebox_override("fill", _crear_caja(Color("#48cae4"), Color.TRANSPARENT, 0, 3))
	fila_barra.add_child(_barra_energia_planeta)

	_lbl_pct_planeta = Label.new()
	_lbl_pct_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_pct_planeta.custom_minimum_size = Vector2(36.0, 0.0)
	_lbl_pct_planeta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_pct_planeta.add_theme_font_size_override("font_size", 11)
	_lbl_pct_planeta.text = "100%"
	fila_barra.add_child(_lbl_pct_planeta)

	_lbl_alerta_planeta = Label.new()
	_lbl_alerta_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_alerta_planeta.add_theme_font_size_override("font_size", 11)
	_lbl_alerta_planeta.modulate = Color("#ffbe0b")
	_lbl_alerta_planeta.text = "⚠ ENERGÍA DEL PLANETA BAJA"
	_lbl_alerta_planeta.visible = false
	vbox.add_child(_lbl_alerta_planeta)


func _crear_caja(fondo: Color, borde: Color, grosor: int, radio: int, mh: int = 0, mv: int = 0) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(grosor)
	caja.set_corner_radius_all(radio)
	if mh > 0 or mv > 0:
		caja.content_margin_left = mh
		caja.content_margin_right = mh
		caja.content_margin_top = mv
		caja.content_margin_bottom = mv
	return caja


func _crear_overlay_borde(color_base: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = color_base

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
		_alerta_sonora.actualizar_sirena(false)
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		return
	if not is_instance_valid(_camara):
		_camara = get_viewport().get_camera_3d()

	var estado_planeta := _actualizar_hud_planeta_cercano()
	_monitorear_alertas_hud(estado_planeta)


func _monitorear_alertas_hud(estado_planeta: Dictionary) -> void:
	var vida := _leer_propiedad(_jugador, ["vida_actual", "vida", "casco"], 100.0)
	var energia := _leer_propiedad(_jugador, ["energia_actual", "energia", "propulsor", "combustible"], 100.0)
	var energia_max := _leer_propiedad(_jugador, ["energia_maxima", "max_energia", "propulsor_maximo"], 100.0)
	var pct_energia := (energia / maxf(energia_max, 1.0)) * 100.0

	var en_orbita: bool = estado_planeta["en_orbita"]
	var muriendo_por_vacio := (not en_orbita) and (energia <= 0.01) and (vida > 0.0)

	# Flash rojo en bordes de pantalla y sacudida de cámara ante impactos puntuales
	if not muriendo_por_vacio and _vida_anterior >= 0.0 and vida < _vida_anterior - 0.25:
		_disparar_flash_hud()
	_vida_anterior = vida

	var parpadeo := 0.65 + 0.35 * sin(_tiempo_alerta * 7.0)

	# Prioridad 0: Peligro mortal — muriendo en el vacío sin energía
	if muriendo_por_vacio:
		var pulso_rojo := 0.38 + 0.28 * sin(_tiempo_alerta * 8.0)
		_vineta_dano.color.a = pulso_rojo
		_vineta_energia.color.a = lerpf(_vineta_energia.color.a, 0.0, 0.2)
		_aviso_central.visible = true
		_aviso_central.text = "🚨 SIN SOPORTE VITAL · MURIENDO EN EL VACÍO"
		_aviso_central.modulate = Color(1.0, 0.22, 0.32, parpadeo)
		_apuntar_a_planeta_disponible(null)
		_alerta_sonora.actualizar_sirena(true)
		return
	else:
		_vineta_dano.color.a = lerpf(_vineta_dano.color.a, 0.0, 0.12)
		_alerta_sonora.actualizar_sirena(false)

	# Prioridad 1: Progreso de ruptura de órbita
	var gestor_orbita := _jugador.get_node_or_null("GestorOrbita")
	if gestor_orbita and gestor_orbita.get("intentando_escapar") == true:
		var prog := float(gestor_orbita.get("progreso_escape")) * 100.0
		_vineta_energia.color.a = lerpf(_vineta_energia.color.a, 0.0, 0.15)
		_flecha_planeta.visible = false
		_aviso_central.visible = true
		_aviso_central.text = "🚀 ROMPIENDO ÓRBITA... %d%%" % int(prog)
		_aviso_central.modulate = Color("#48cae4")
		return

	# Prioridad 2: Escasez o agotamiento de energía del planeta (<40%)
	var pct_planeta: float = estado_planeta["pct"]
	var planeta_actual: Node3D = estado_planeta["nodo"]

	if en_orbita and pct_planeta < umbral_energia_baja:
		_aviso_central.visible = true
		if pct_planeta <= 1.0:
			_vineta_energia.color.a = 0.18 + 0.12 * sin(_tiempo_alerta * 7.0)
			_aviso_central.text = "🚨 ÓRBITA AGOTADA (0%) · SAL HACIA OTRO PLANETA"
			_aviso_central.modulate = Color(1.0, 0.30, 0.43, parpadeo)
		else:
			_vineta_energia.color.a = lerpf(_vineta_energia.color.a, 0.12, 0.15)
			_aviso_central.text = "⚠ RESERVA DEL PLANETA BAJA (%d%%) · PREPÁRATE PARA SALIR" % int(pct_planeta)
			_aviso_central.modulate = Color(1.0, 0.75, 0.05, parpadeo)
		_apuntar_a_planeta_disponible(planeta_actual)
		return

	# Prioridad 3: Energía baja del propio propulsor de la nave (<40%)
	if pct_energia < umbral_energia_baja:
		var pulso := 0.20 + 0.15 * sin(_tiempo_alerta * 6.0)
		_vineta_energia.color.a = pulso
		_aviso_central.visible = true
		_aviso_central.text = "⚡ ENERGÍA DE NAVE BAJA (%d%%) · RECARGA EN UNA ÓRBITA" % int(pct_energia)
		_aviso_central.modulate = Color(1.0, 0.75, 0.05, parpadeo)
		_apuntar_a_planeta_disponible(null)
	else:
		_vineta_energia.color.a = lerpf(_vineta_energia.color.a, 0.0, 0.15)
		_aviso_central.visible = false
		_flecha_planeta.visible = false


func _actualizar_hud_planeta_cercano() -> Dictionary:
	var cercano: Node3D = null
	var dist_min := INF

	for p in get_tree().get_nodes_in_group("planetas"):
		if not (p is Node3D):
			continue
		var d := _jugador.global_position.distance_to((p as Node3D).global_position)
		if d < dist_min:
			dist_min = d
			cercano = p as Node3D

	if cercano == null or dist_min > distancia_info_planeta:
		_panel_planeta.visible = false
		return {"en_orbita": false, "pct": 100.0, "nodo": null}

	_panel_planeta.visible = true

	var radio_orbita := _leer_propiedad(cercano, ["radio_orbita", "radio_atraccion", "radio_zona"], 45.0 * cercano.scale.x)
	var en_orbita := dist_min <= radio_orbita
	_lbl_estado_orbita.text = "EN ÓRBITA" if en_orbita else "A %dm" % int(dist_min)
	_lbl_estado_orbita.modulate = Color("#70e000") if en_orbita else Color("#9fb3c8")

	var info := _obtener_info_planeta(cercano)
	var pct := _obtener_porcentaje_planeta(cercano)

	_lbl_tipo_planeta.text = info["nombre"]
	_lbl_tipo_planeta.modulate = info["color"]
	_barra_energia_planeta.value = pct

	if pct <= 1.0:
		_lbl_efecto_planeta.text = "Órbita agotada · Regenerando reserva..."
		_lbl_efecto_planeta.modulate = Color("#ff758f")
		_lbl_pct_planeta.text = "0%"
		_lbl_pct_planeta.modulate = Color("#ff4d6d")
		_lbl_alerta_planeta.visible = true
		_lbl_alerta_planeta.text = "⚠ SIN RESERVA · BUSCA OTRO PLANETA"
		_lbl_alerta_planeta.modulate = Color("#ff4d6d")
		_barra_energia_planeta.add_theme_stylebox_override("fill", _crear_caja(Color("#ff4d6d"), Color.TRANSPARENT, 0, 3))
		_panel_planeta.add_theme_stylebox_override("panel", _crear_caja(Color("#1f0f17e6"), Color("#ff4d6d"), 1, 8, 12, 9))
	elif pct < umbral_energia_baja:
		_lbl_efecto_planeta.text = info["efecto"]
		_lbl_efecto_planeta.modulate = Color("#d9e2ec")
		_lbl_pct_planeta.text = "%d%%" % int(pct)
		_lbl_pct_planeta.modulate = Color("#ffbe0b")
		_lbl_alerta_planeta.visible = true
		_lbl_alerta_planeta.text = "⚠ RESERVA BAJA (<40%) · PREPARA SALIDA"
		_lbl_alerta_planeta.modulate = Color("#ffbe0b")
		_barra_energia_planeta.add_theme_stylebox_override("fill", _crear_caja(Color("#ffbe0b"), Color.TRANSPARENT, 0, 3))
		_panel_planeta.add_theme_stylebox_override("panel", _crear_caja(Color("#1c1910e6"), Color("#ffbe0b"), 1, 8, 12, 9))
	else:
		_lbl_efecto_planeta.text = info["efecto"]
		_lbl_efecto_planeta.modulate = Color("#d9e2ec")
		_lbl_pct_planeta.text = "%d%%" % int(pct)
		_lbl_pct_planeta.modulate = info["color"]
		_lbl_alerta_planeta.visible = false
		_barra_energia_planeta.add_theme_stylebox_override("fill", _crear_caja(info["color"], Color.TRANSPARENT, 0, 3))
		_panel_planeta.add_theme_stylebox_override("panel", _crear_caja(Color("#0c1a28de"), Color("#395267"), 1, 8, 12, 9))

	return {"en_orbita": en_orbita, "pct": pct, "nodo": cercano}


func _obtener_info_planeta(planeta: Node) -> Dictionary:
	var tipo_id := int(_leer_propiedad(planeta, ["tipo", "tipo_planeta"], -1.0))
	var rep_casco := _leer_propiedad(planeta, ["reparacion_casco_por_seg", "reparacion_casco", "tasa_reparacion", "cura_por_segundo"], 0.0)
	var mult_recarga := _leer_propiedad(planeta, ["multiplicador_recarga", "factor_recarga", "velocidad_recarga"], 1.0)

	if tipo_id == 2 or rep_casco > 0.01:
		return {
			"nombre": "PLANETA BIOLÓGICO",
			"efecto": "Repara casco (+2.5 HP/s) y recarga propulsor",
			"color": Color("#52b788")
		}
	elif tipo_id == 1 or mult_recarga > 1.25:
		return {
			"nombre": "PLANETA ENERGÉTICO",
			"efecto": "Recarga rápida de propulsor (1.8x)",
			"color": Color("#ffbe0b")
		}

	return {
		"nombre": "PLANETA ESTÁNDAR",
		"efecto": "Recarga propulsor de forma equilibrada (1.0x)",
		"color": Color("#48cae4")
	}


func _disparar_flash_hud() -> void:
	_vineta_dano.color.a = 0.65
	var tw := _vineta_dano.create_tween()
	tw.tween_property(_vineta_dano, "color:a", 0.0, 0.38)

	if is_instance_valid(_camara):
		var orig_h := _camara.h_offset
		var orig_v := _camara.v_offset
		var tw_cam := _camara.create_tween()
		tw_cam.tween_property(_camara, "h_offset", orig_h + randf_range(-0.35, 0.35), 0.05)
		tw_cam.parallel().tween_property(_camara, "v_offset", orig_v + randf_range(-0.35, 0.35), 0.05)
		tw_cam.tween_property(_camara, "h_offset", orig_h, 0.08)
		tw_cam.parallel().tween_property(_camara, "v_offset", orig_v, 0.08)


func _apuntar_a_planeta_disponible(ignorar_planeta: Node3D) -> void:
	if not is_instance_valid(_camara):
		return
	var mejor_planeta: Node3D = null
	var mejor_dist := INF

	for p in get_tree().get_nodes_in_group("planetas"):
		if not (p is Node3D) or p == ignorar_planeta:
			continue
		if _obtener_porcentaje_planeta(p) <= 15.0:
			continue
		var d := _jugador.global_position.distance_to((p as Node3D).global_position)
		if d < mejor_dist:
			mejor_dist = d
			mejor_planeta = p as Node3D

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
	_etiqueta_flecha.text = "● SIGUIENTE ÓRBITA (%dm)" % int(mejor_dist)


func _obtener_porcentaje_planeta(planeta: Node) -> float:
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
