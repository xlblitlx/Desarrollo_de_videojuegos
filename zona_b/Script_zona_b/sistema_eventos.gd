class_name SistemaEventos
extends Node

@export var luz_evento: OmniLight3D
@export var pico_destello := 4.0
@export var k_destello := 6.0
@export var luz_variable: Light3D
@export var color_bajo: Color = Color(0.2, 0.8, 1.0) # Vida sana (Cian)
@export var color_alto: Color = Color(1.0, 0.29, 0.39) # Vida baja/Peligro (#FF4B63)
@export var k_variable := 4.0

var variable := 0.0

func _ready() -> void:
	for d in get_tree().get_nodes_in_group("disparadores"):
		d.evento.connect(_on_evento)
	if luz_evento:
		luz_evento.light_energy = 0.0

func _process(delta: float) -> void:
	if luz_evento and luz_evento.light_energy > 0.0:
		luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)
	
	# Control manual con flechas arriba/abajo para probar la luz variable
	if Input.is_key_pressed(KEY_UP):
		variable = minf(1.0, variable + delta * 0.5)
	elif Input.is_key_pressed(KEY_DOWN):
		variable = maxf(0.0, variable - delta * 0.5)
		
	if luz_variable:
		luz_variable.light_color = color_bajo.lerp(color_alto, variable)
		var energia_deseada = 1.0 + 3.0 * variable
		luz_variable.light_energy = decaer(luz_variable.light_energy, energia_deseada, k_variable, delta)

func _on_evento(posicion: Vector3) -> void:
	if luz_evento:
		luz_evento.global_position = posicion + Vector3.UP * 1.5
		luz_evento.light_energy = pico_destello

static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	var alpha = 1.0 - exp(-k * dt)
	return actual + (base - actual) * alpha
