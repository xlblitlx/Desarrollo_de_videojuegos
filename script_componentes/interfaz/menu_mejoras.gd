class_name MenuMejoras
extends CanvasLayer
## Interfaz modal con 3 cartas aleatorias que aparece al subir de nivel.

@export var gestor_mejoras: GestorMejoras

@onready var titulo_nivel: Label = find_child("TituloNivel") as Label
@onready var botones: Array[Button] = [
	find_child("Carta1") as Button,
	find_child("Carta2") as Button,
	find_child("Carta3") as Button
]

var _opciones_actuales: Array[Dictionary] = []


func _ready() -> void:
	# Garantiza que funcione incluso cuando el árbol está en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	for i in range(botones.size()):
		if botones[i]:
			botones[i].pressed.connect(_al_pulsar_carta.bind(i))

	await get_tree().process_frame
	if gestor_mejoras == null:
		gestor_mejoras = get_tree().get_first_node_in_group("gestor_mejoras") as GestorMejoras

	if gestor_mejoras:
		gestor_mejoras.mostrar_menu_mejoras.connect(_abrir_menu)


func _abrir_menu(opciones: Array[Dictionary], nivel: int) -> void:
	_opciones_actuales = opciones
	if titulo_nivel:
		titulo_nivel.text = "¡NIVEL %d ALCANZADO! — ELIGE UNA MEJORA" % nivel

	for i in range(botones.size()):
		var btn := botones[i]
		if btn == null:
			continue
		if i < opciones.size():
			var op := opciones[i]
			btn.visible = true
			btn.text = "%s\n\n%s" % [op["titulo"], op["descripcion"]]
			btn.modulate = op.get("color", Color.WHITE)
		else:
			btn.visible = false

	# Libera el ratón para poder hacer clic en las cartas
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	if botones[0] and botones[0].visible:
		botones[0].grab_focus()


func _al_pulsar_carta(indice: int) -> void:
	if indice < 0 or indice >= _opciones_actuales.size():
		return

	var id_elegido: String = _opciones_actuales[indice]["id"]
	visible = false
	# Devuelve el control del ratón a la nave/cámara
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if gestor_mejoras:
		gestor_mejoras.aplicar_mejora(id_elegido)
