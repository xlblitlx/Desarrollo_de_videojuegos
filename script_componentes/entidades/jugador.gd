class_name Jugador
extends CharacterBody3D

signal vida_cambiada(actual: float, maxima: float)
signal propulsor_cambiado(actual: float, maxima: float, agotado: bool)
signal estado_orbita_cambiado(en_espacio_abierto: bool)
signal impacto_recibido(duracion_invulnerable: float)

@export_group("Velocidades")
@export var velocidad_normal: float = 20.0
@export var velocidad_propulsion: float = 75.0
@export var rotation_speed: float = 12.0

@export_group("Supervivencia")
@export var vida_maxima: float = 100.0
@export var dano_espacio_abierto: float = 10.0
@export var tiempo_invulnerable: float = 0.45

@export_group("Propulsor")
@export var energia_maxima: float = 1000.0
@export var consumo_por_segundo: float = 20.0
@export var recarga_por_segundo: float = 25.0
@export var umbral_reactivacion: float = 15.0
@export var consumo_soporte_vital_vacio: float = 4.5

@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var camera_pivot: Node3D = get_node_or_null("CamaraPivot")
@onready var gestor_orbita: GestorOrbita = get_node_or_null("GestorOrbita")
@onready var sensor_dano: SensorDano = get_node_or_null("SensorDano")

var vida_actual: float = 100.0
var energia_actual: float = 100.0
var propulsor_agotado: bool = false
var propulsor_activo: bool = false
var multiplicador_consumo: float = 1.0

var _destruido: bool = false
var _invulnerable_restante: float = 0.0


func _ready() -> void:
	vida_actual = vida_maxima
	energia_actual = energia_maxima
	vida_cambiada.emit(vida_actual, vida_maxima)


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	_actualizar_invulnerabilidad(delta)
	_procesar_propulsor(delta)
	_procesar_movimiento(delta)

	if gestor_orbita:
		velocity = gestor_orbita.aplicar_fisica_orbital(
			global_position, velocity, velocidad_propulsion, propulsor_activo and not propulsor_agotado, delta
		)

	move_and_slide()

	if gestor_orbita:
		gestor_orbita.procesar_limites(self)
		_procesar_peligro_vacio(delta)

	if sensor_dano:
		sensor_dano.procesar_prueba_dano(global_position)

	propulsor_cambiado.emit(energia_actual, energia_maxima, propulsor_agotado)
	if gestor_orbita:
		estado_orbita_cambiado.emit(gestor_orbita.esta_en_espacio_abierto())


func _actualizar_invulnerabilidad(delta: float) -> void:
	if _invulnerable_restante > 0.0:
		_invulnerable_restante -= delta
		if mesh:
			mesh.visible = int(_invulnerable_restante * 22.0) % 2 == 0
	elif mesh and not mesh.visible:
		mesh.visible = true


func recibir_dano(cantidad: float, ignorar_iframes: bool = false) -> void:
	if _destruido or cantidad <= 0.0:
		return
	if not ignorar_iframes and _invulnerable_restante > 0.0:
		return

	if not ignorar_iframes:
		_invulnerable_restante = tiempo_invulnerable
		impacto_recibido.emit(tiempo_invulnerable)

	vida_actual = maxf(0.0, vida_actual - cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)

	if vida_actual <= 0.0:
		_finalizar_partida()


func _finalizar_partida() -> void:
	_destruido = true
	if mesh:
		mesh.visible = true

	var gestor_oleadas := get_tree().current_scene.find_child("GestorOleadas", true, false)
	var estadisticas := {
		"tiempo": gestor_oleadas.tiempo_supervivencia if gestor_oleadas else 0.0,
		"oleada": gestor_oleadas.nivel_intensidad if gestor_oleadas else 1,
	}

	if EventosJuego and EventosJuego.has_signal("partida_terminada") and EventosJuego.partida_terminada.get_connections().size() > 0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		EventosJuego.partida_terminada.emit(estadisticas)
		get_tree().paused = true
	else:
		await get_tree().create_timer(1.0).timeout
		if is_inside_tree():
			get_tree().reload_current_scene()


func curar(cantidad: float) -> void:
	if _destruido or cantidad <= 0.0 or vida_actual >= vida_maxima:
		return
	vida_actual = minf(vida_maxima, vida_actual + cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)


func _procesar_peligro_vacio(delta: float) -> void:
	if gestor_orbita and gestor_orbita.esta_en_espacio_abierto() and energia_actual <= 0.0:
		recibir_dano(dano_espacio_abierto * delta, true)


func _procesar_propulsor(delta: float) -> void:
	var quiere_propulsar := Input.is_action_pressed("ui_accept")
	var en_orbita := gestor_orbita != null and not gestor_orbita.esta_en_espacio_abierto()

	if propulsor_agotado and energia_actual >= umbral_reactivacion:
		propulsor_agotado = false

	if quiere_propulsar and not propulsor_agotado and energia_actual > 0.0:
		propulsor_activo = true
		energia_actual = maxf(0.0, energia_actual - (consumo_por_segundo * multiplicador_consumo) * delta)
	else:
		propulsor_activo = false
		if en_orbita:
			var energia_faltante := maxf(0.0, energia_maxima - energia_actual)
			var necesita_curacion := vida_actual < vida_maxima
			if energia_faltante > 0.01 or necesita_curacion:
				var demanda_energia := minf(recarga_por_segundo * delta, energia_faltante)
				var recursos := gestor_orbita.recolectar_recursos_orbitales(demanda_energia, delta)
				energia_actual = minf(energia_maxima, energia_actual + recursos.x)
				if necesita_curacion and recursos.y > 0.0:
					curar(recursos.y)
		else:
			energia_actual = maxf(0.0, energia_actual - (consumo_soporte_vital_vacio * multiplicador_consumo) * delta)

	if energia_actual <= 0.0:
		propulsor_agotado = true


func _procesar_movimiento(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "up", "down")
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
