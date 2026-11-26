extends RefCounted
const FONDO := Color("09121f")
const PANEL := Color("102234")
const TEXTO := Color("edf5fc")
const SUAVE := Color("a8bdce")
const CIAN := Color("65e4ed")
const AMBAR := Color("ffc778")
const ROJO := Color("ff7c86")

static func caja(color: Color = PANEL, borde: Color = Color("294252"), ancho: int = 1, espacio: int = 20) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = borde
	s.set_border_width_all(ancho)
	s.set_corner_radius_all(10)
	s.content_margin_left = espacio
	s.content_margin_right = espacio
	s.content_margin_top = espacio
	s.content_margin_bottom = espacio
	return s

static func texto(valor: String, tamano: int = 18, color: Color = TEXTO) -> Label:
	var l := Label.new()
	l.text = valor
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func boton(valor: String, primario: bool = false) -> Button:
	var b := Button.new()
	b.text = valor
	b.custom_minimum_size = Vector2(0, 52)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", FONDO if primario else TEXTO)
	b.add_theme_color_override("font_hover_color", FONDO if primario else TEXTO)
	b.add_theme_color_override("font_focus_color", FONDO if primario else TEXTO)
	b.add_theme_color_override("font_pressed_color", TEXTO)
	b.add_theme_stylebox_override("normal", caja(CIAN if primario else PANEL, CIAN if primario else Color("35536a"), 1, 14))
	b.add_theme_stylebox_override("hover", caja(Color("a4f2f5") if primario else Color("1b384c"), CIAN, 1, 14))
	b.add_theme_stylebox_override("pressed", caja(Color("215369"), CIAN, 1, 14))
	var foco := caja(Color.TRANSPARENT, AMBAR, 3, 14)
	b.add_theme_stylebox_override("focus", foco)
	return b

static func barra(color: Color, alto: float = 8.0) -> ProgressBar:
	var p := ProgressBar.new()
	p.custom_minimum_size = Vector2(0, alto)
	p.show_percentage = false
	p.add_theme_stylebox_override("background", caja(Color("1f3444"), Color.TRANSPARENT, 0, 0))
	p.add_theme_stylebox_override("fill", caja(color, Color.TRANSPARENT, 0, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", caja())
	return p

static func vbox(separacion: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separacion)
	return v

static func fondo(padre: Node, alfa: float = 0.88) -> ColorRect:
	var f := ColorRect.new()
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.color = Color(0.015, 0.035, 0.06, alfa)
	padre.add_child(f)
	return f
