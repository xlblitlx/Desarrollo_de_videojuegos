class_name Jugador
extends CharacterBody3D

@export_group("Velocidades")
@export var velocidad_normal: float = 20.0
@export var velocidad_propulsion: float = 75.0 # Impulso interplanetario
@export var rotation_speed: float = 12.0 # Velocidad de giro del mesh

# Referencias a los nodos hijos y componentes
@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var camera_pivot: Node3D = get_node_or_null("CamaraPivot")
@onready var gestor_orbita: GestorOrbita = get_node_or_null("GestorOrbita")
@onready var sensor_dano: SensorDano = get_node_or_null("SensorDano")

@export_group("Supervivencia")
@export var dano_espacio_abierto: float = 10.0 # Daño por segundo fuera de planetas
var vida_actual: float = 100.0

func _physics_process(delta: float) -> void:
	_procesar_input_propulsion()
	_procesar_movimiento(delta)
	
	# Usamos el nuevo procesar_limites que maneja órbita + mapa global
	if gestor_orbita:
		gestor_orbita.procesar_limites(self)
		_procesar_peligro_vacio(delta)
		
	if sensor_dano:
		sensor_dano.procesar_prueba_dano(global_position)

	move_and_slide()

## Aplica daño constante si la nave sale de la protección de una cúpula orbital
func _procesar_peligro_vacio(delta: float) -> void:
	if gestor_orbita.esta_en_espacio_abierto():
		vida_actual -= dano_espacio_abierto * delta
		# Opcional: imprimir en consola para probar que baja la vida al salir de órbita
		# print("¡Radiación! Vida restante: ", snapped(vida_actual, 0.1))
		
		if vida_actual <= 0:
			print("Nave destruida por radiación espacial")

## Controla la activación y desactivación de propulsores interplanetarios
func _procesar_input_propulsion() -> void:
	var presionando_propulsor := Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SHIFT)
	
	if gestor_orbita:
		if presionando_propulsor:
			gestor_orbita.activar_propulsores(true)
		else:
			# Al soltar la tecla vuelve a modo normal para dejarse capturar por otro planeta
			gestor_orbita.usa_propulsores = false

## Mantiene la lógica original de movimiento según el CamaraPivot
func _procesar_movimiento(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
	
	# Determina la velocidad según si los propulsores están activos
	var vel_actual := velocidad_propulsion if (gestor_orbita and gestor_orbita.usa_propulsores) else velocidad_normal

	if input_dir == Vector2.ZERO:
		velocity = velocity.move_toward(Vector3.ZERO, vel_actual * delta * 4.0)
		return

	# Utiliza la orientación del nodo "CamaraPivot" tal como te gustaba
	var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot else global_transform.basis

	var forward := -cam_basis.z
	var right := cam_basis.x
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()

	velocity = direction * vel_actual

	# Rotación suave del modelo 3D mirando en la dirección del movimiento
	if mesh and direction != Vector3.ZERO:
		var target_basis := Basis.looking_at(direction, Vector3.UP)
		mesh.global_transform.basis = mesh.global_transform.basis.slerp(target_basis, rotation_speed * delta)
