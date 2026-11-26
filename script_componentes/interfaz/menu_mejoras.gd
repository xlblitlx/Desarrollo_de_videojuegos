class_name MenuMejoras
extends CanvasLayer

const UI = preload("res://script_componentes/interfaz/estilo_orbital.gd")

@export var gestor_mejoras: GestorMejoras

var titulo_nivel: Label
var botones: Array[Button] = []
var _opciones_actuales: Array[Dictionary] = []
var _panel: PanelContainer
var _cartas: GridContainer
var _seleccionando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	_construir()
	visible = false
	get_viewport().size_changed.connect(_adaptar)
	await get_tree().process_frame
	if gestor_mejoras == null:
		gestor_mejoras = get_tree().get_first_node_in_group("gestor_mejoras") as GestorMejoras
	if gestor_mejoras:
		gestor_mejoras.mostrar_menu_mejoras.connect(_abrir_menu)
		if gestor_mejoras.has_signal("cerrar_menu_mejoras"):
			gestor_mejoras.connect("cerrar_menu_mejoras", _cerrar)


func _construir() -> void:
	UI.fondo(self)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	_panel = UI.panel()
	centro.add_child(_panel)

	var caja := UI.vbox(18)
	_panel.add_child(caja)

	caja.add_child(UI.texto("SISTEMA DE MEJORAS", 14, UI.CIAN))
	titulo_nivel = UI.texto("NIVEL ALCANZADO", 30)
	titulo_nivel.name = "TituloNivel"
	caja.add_child(titulo_nivel)
	caja.add_child(UI.texto("Elige una mejora para tu nave. La misión está en pausa.", 17, UI.SUAVE))

	_cartas = GridContainer.new()
	_cartas.add_theme_constant_override("h_separation", 16)
	_cartas.add_theme_constant_override("v_separation", 12)
	caja.add_child(_cartas)

	for i in range(3):
		var b := UI.boton("")
		b.name = "Carta%d" % (i + 1)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_al_pulsar_carta.bind(i))
		_cartas.add_child(b)
		botones.append(b)

	caja.add_child(UI.texto("1 / 2 / 3  Elegir     ·     TAB / FLECHAS  Navegar     ·     ENTER  Confirmar", 14, UI.SUAVE))
	_adaptar()


func _adaptar() -> void:
	if _panel == null:
		return
	var ancho := get_viewport().get_visible_rect().size.x
	_cartas.columns = 3 if ancho >= 900 else 1
	_panel.custom_minimum_size.x = minf(1040.0, ancho - 32.0)
	for b in botones:
		b.custom_minimum_size = Vector2(0, 230 if _cartas.columns == 3 else 110)


func _abrir_menu(opciones: Array[Dictionary], nivel: int) -> void:
	_opciones_actuales = opciones
	_seleccionando = false
	titulo_nivel.text = "NIVEL %02d · ELIGE TU MEJORA" % nivel

	for i in range(botones.size()):
		var b := botones[i]
		b.visible = i < opciones.size()
		b.disabled = false
		if i < opciones.size():
			var op := opciones[i]
			var actual: int = int(op.get("nivel_actual", 0))
			var siguiente: int = int(op.get("nivel_siguiente", 1))
			var maximo: int = int(op.get("max_nivel", 0))

			var contador_texto := ""
			if maximo > 0:
				var barras := ""
				for k in range(maximo):
					barras += "■ " if k < actual else "□ "
				contador_texto = "\n%s(%d/%d  →  %d/%d)" % [barras, actual, maximo, siguiente, maximo]

			b.text = "[ %02d ]  %s%s\n\n%s" % [i + 1, op["titulo"], contador_texto, op["descripcion"]]
			var color: Color = op.get("color", UI.CIAN)
			b.add_theme_stylebox_override("normal", UI.caja(Color("122738"), color, 2, 18))

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	_adaptar()
	if not botones.is_empty():
		botones[0].grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			_al_pulsar_carta(event.keycode - KEY_1)
			get_viewport().set_input_as_handled()


func _al_pulsar_carta(indice: int) -> void:
	if _seleccionando or not visible or indice < 0 or indice >= _opciones_actuales.size() or gestor_mejoras == null:
		return
	_seleccionando = true
	var id: String = _opciones_actuales[indice]["id"]
	if gestor_mejoras.aplicar_mejora(id):
		visible = false
		for b in botones:
			b.disabled = true
	else:
		_seleccionando = false


func _cerrar() -> void:
	visible = false
	_opciones_actuales.clear()
