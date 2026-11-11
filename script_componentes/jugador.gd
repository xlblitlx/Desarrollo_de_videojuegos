class_name Jugador
extends CharacterBody3D

@export var speed: float = 20.0
@export var rotation_speed: float = 12.0

# Referencias a los nodos hijos y componentes con el nuevo nombre "CamaraPivot"
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var camera_pivot: Node3D = get_node_or_null("CamaraPivot")
@onready var gestor_orbita: GestorOrbita = get_node_or_null("GestorOrbita")
@onready var sensor_dano: SensorDano = get_node_or_null("SensorDano")

func _physics_process(delta: float) -> void:
	_procesar_movimiento(delta)
	
	if gestor_orbita:
		gestor_orbita.procesar_limites(self) # Invoca orbital + global
		
	if sensor_dano:
		sensor_dano.procesar_prueba_dano(global_position)

	move_and_slide()

func _procesar_movimiento(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down",)
	
	if input_dir == Vector2.ZERO:
		velocity = velocity.move_toward(Vector3.ZERO, speed)
		return

	# Utiliza la orientación del nodo "CamaraPivot"
	var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot else global_transform.basis

	var forward := -cam_basis.z
	var right := cam_basis.x
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()

	velocity = direction * speed

	if mesh and direction != Vector3.ZERO:
		var target_basis = Basis.looking_at(direction, Vector3.UP)
		mesh.global_transform.basis = mesh.global_transform.basis.slerp(target_basis, rotation_speed * delta)
