class_name SistemaEventos
extends Node

@export var luz_evento: OmniLight3D
@export var pico_destello := 2.0
@export var k_destello := 6.0

@export var luz_variable: Light3D
@export var color_bajo: Color = Color(0.2, 0.8, 1.0) # Vida alta / Normal (Cian)
@export var color_alto: Color = Color(0.0, 1.0, 0.0) # Color de prueba/alerta (Verde o Rojo #FF4B63)
@export var k_variable := 4.0

var variable := 0.0

func _ready() -> void:
	# Conecta todos los nodos del grupo "disparadores"
	for d in get_tree().get_nodes_in_group("disparadores"):
		if d.has_signal("evento"):
			d.evento.connect(_on_evento)
	
	if luz_evento:
		luz_evento.light_energy = 0.0

func _process(delta: float) -> void:
	# 1. Manejo del destello (decae exponencialmente hasta 0)
	if luz_evento and luz_evento.light_energy > 0.001:
		luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)
	
	# 2. Control de la variable de juego con las flechas del teclado
	if Input.is_key_pressed(KEY_UP):
		variable = minf(1.0, variable + delta * 0.8)
	elif Input.is_key_pressed(KEY_DOWN):
		variable = maxf(0.0, variable - delta * 0.8)
		
	# 3. Aplicar color y energía a la luz variable de la zona
	if luz_variable:
		luz_variable.light_color = color_bajo.lerp(color_alto, variable)
		var energia_deseada = 1.0 + 3.0 * variable
		luz_variable.light_energy = decaer(luz_variable.light_energy, energia_deseada, k_variable, delta)

func _on_evento(posicion: Vector3) -> void:
	if luz_evento:
		print("¡Evento recibido en SistemaEventos! Encendiendo destello...")
		# Desplaza la luz ligeramente sobre el punto del disparo/evento
		luz_evento.global_position = posicion + Vector3.UP * 1.5
		luz_evento.light_energy = pico_destello

# Función pura para el decaimiento exponencial (Taller 2 / Taller 4)
static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	var alpha = 1.0 - exp(-k * dt)
	return actual + (base - actual) * alpha
