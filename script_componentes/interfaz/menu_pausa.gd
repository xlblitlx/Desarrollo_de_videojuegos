class_name MenuPausa
extends CanvasLayer

@export_file("*.tscn") var escena_menu_principal: String = "res://escenas/menu_principal.tscn"

var _panel: PanelContainer
var _fondo: ColorRect
var _centro: CenterContainer


func _ready() -> void:
	layer = 20
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()
	_mostrar_ui(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Si el juego ya está pausado por otro modal (Menú de Mejoras o Game Over), no abrir pausa encima
		if get_tree().paused and not _panel.visible:
			return
		_alternar_pausa()
		get_viewport().set_input_as_handled()


func _alternar_pausa() -> void:
	var pausar := not _panel.visible
	_mostrar_ui(pausar)
	get_tree().paused = pausar
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausar else Input.MOUSE_MODE_CAPTURED


func _mostrar_ui(estado: bool) -> void:
	if _fondo:
		_fondo.visible = estado
	if _centro:
		_centro.visible = estado
	if _panel:
		_panel.visible = estado


func _construir_ui() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color(0.0, 0.0, 0.0, 0.55)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)

	_centro = CenterContainer.new()
	_centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_centro)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(280, 0)
	_centro.add_child(_panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)

	var titulo := Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	caja.add_child(titulo)

	var btn_continuar := Button.new()
	btn_continuar.text = "Continuar"
	btn_continuar.custom_minimum_size = Vector2(0, 38)
	btn_continuar.pressed.connect(_alternar_pausa)
	caja.add_child(btn_continuar)

	var btn_reiniciar := Button.new()
	btn_reiniciar.text = "Reiniciar Partida"
	btn_reiniciar.custom_minimum_size = Vector2(0, 38)
	btn_reiniciar.pressed.connect(_al_reiniciar)
	caja.add_child(btn_reiniciar)

	var btn_menu := Button.new()
	btn_menu.text = "Menú Principal"
	btn_menu.custom_minimum_size = Vector2(0, 38)
	btn_menu.pressed.connect(_al_ir_menu)
	caja.add_child(btn_menu)


func _al_reiniciar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _al_ir_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(escena_menu_principal)
