class_name ControladorCamara
extends Node3D

@export var mouse_sensitivity: float = 0.003

@export_group("FOV Dinamico")
@export var fov_base: float = 78.0
@export var fov_propulsor: float = 85.0
@export var suavizado_fov: float = 5.0

@onready var _camara: Camera3D = find_child("Camera3D", true, false) as Camera3D
var _jugador: Jugador = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _camara:
		_camara.fov = fov_base
	_jugador = get_parent() as Jugador


func _process(delta: float) -> void:
	if _camara == null or not is_instance_valid(_jugador):
		return
	var fov_objetivo := fov_propulsor if _jugador.propulsor_activo else fov_base
	_camara.fov = lerpf(_camara.fov, fov_objetivo, clampf(suavizado_fov * delta, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		get_parent().rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_x(-event.relative.y * mouse_sensitivity)
		rotation.x = clamp(rotation.x, deg_to_rad(-45.0), deg_to_rad(30.0))
