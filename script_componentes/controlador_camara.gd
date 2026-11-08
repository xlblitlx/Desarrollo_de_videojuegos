class_name ControladorCamara
extends Node3D

@export var mouse_sensitivity: float = 0.003

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rota al padre (Jugador) horizontalmente
		get_parent().rotate_y(-event.relative.x * mouse_sensitivity)
		# Rota a este pivote verticalmente
		rotate_x(-event.relative.y * mouse_sensitivity)
		rotation.x = clamp(rotation.x, deg_to_rad(-45.0), deg_to_rad(30.0))

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
