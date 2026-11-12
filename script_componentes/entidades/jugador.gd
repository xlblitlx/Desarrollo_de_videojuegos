class_name Jugador
extends CharacterBody3D

signal vida_cambiada(actual: float, maxima: float)
signal propulsor_cambiado(actual: float, maxima: float, agotado: bool)
signal estado_orbita_cambiado(en_espacio_abierto: bool)

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
@export var vida_maxima: float = 100.0
@export var dano_espacio_abierto: float = 10.0 # Daño por segundo fuera de planetas sin energía
var vida_actual: float = 100.0
var _destruido: bool = false

@export_group("Propulsor")
@export var energia_maxima: float = 100.0
@export var consumo_por_segundo: float = 20.0   # ~4 segundos de propulsor continuo para viajes largos
@export var recarga_por_segundo: float = 25.0   # Solo aplica dentro de una órbita planetaria
@export var umbral_reactivacion: float = 15.0   # Penalización mínima si vacías el tanque por completo
@export var consumo_soporte_vital_vacio: float = 4.5 # Consume energía pasivamente fuera de órbita (~22s)

var energia_actual: float = 100.0
var propulsor_agotado: bool = false
var propulsor_activo: bool = false

func _ready() -> void:
	vida_actual = vida_maxima
	energia_actual = energia_maxima
	await get_tree().process_frame
	vida_cambiada.emit(vida_actual, vida_maxima)


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	_procesar_input_propulsion(delta)
	_procesar_movimiento(delta)
	move_and_slide()

	if gestor_orbita:
		gestor_orbita.procesar_limites(self)
		_procesar_peligro_vacio(delta)

	if sensor_dano:
		sensor_dano.procesar_prueba_dano(global_position)

	propulsor_cambiado.emit(energia_actual, energia_maxima, propulsor_agotado)
	if gestor_orbita:
		estado_orbita_cambiado.emit(gestor_orbita.esta_en_espacio_abierto())

## Punto único de entrada para recibir daño (enemigos, radiación o asteroides)
func recibir_dano(cantidad: float) -> void:
	if _destruido:
		return

	vida_actual = maxf(0.0, vida_actual - cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)

	if vida_actual <= 0.0:
		_destruido = true
		print("Nave destruida")
		get_tree().reload_current_scene()


## Aplica daño constante si la nave está en el vacío y sin energía en los propulsores
func _procesar_peligro_vacio(delta: float) -> void:
	if gestor_orbita and gestor_orbita.esta_en_espacio_abierto() and energia_actual <= 0.0:
		recibir_dano(dano_espacio_abierto * delta)

## Controla la activación y desactivación de propulsores interplanetarios
func _procesar_input_propulsion(delta: float) -> void:
	var quiere_propulsar := Input.is_action_pressed("ui_accept")
	var en_orbita := gestor_orbita != null and not gestor_orbita.esta_en_espacio_abierto()

	if propulsor_agotado and energia_actual >= umbral_reactivacion:
		propulsor_agotado = false

	if quiere_propulsar and not propulsor_agotado and energia_actual > 0.0:
		propulsor_activo = true
		energia_actual = maxf(0.0, energia_actual - consumo_por_segundo * delta)
	else:
		propulsor_activo = false
		if en_orbita:
			energia_actual = minf(energia_maxima, energia_actual + recarga_por_segundo * delta)
		else:
			energia_actual = maxf(0.0, energia_actual - consumo_soporte_vital_vacio * delta)

	if energia_actual <= 0.0:
		propulsor_agotado = true

## Mantiene la lógica original de movimiento según el CamaraPivot
func _procesar_movimiento(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")

	# Sincroniza el permiso de atravesar órbitas con el estado real del combustible
	if gestor_orbita:
		gestor_orbita.usa_propulsores = propulsor_activo

	var vel_actual := velocidad_propulsion if propulsor_activo else velocidad_normal

	if input_dir == Vector2.ZERO:
		velocity = velocity.move_toward(Vector3.ZERO, vel_actual * delta * 4.0)
		return

	var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot else global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()

	velocity = direction * vel_actual

	if mesh and direction != Vector3.ZERO:
		var target_basis := Basis.looking_at(direction, Vector3.UP)
		mesh.global_transform.basis = mesh.global_transform.basis.slerp(target_basis, rotation_speed * delta)
