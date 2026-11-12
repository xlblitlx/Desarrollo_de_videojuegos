class_name CampoAsteroides
extends Node3D

@export var asteroide_scene: PackedScene
@export var cantidad_asteroides: int = 14
@export var radio_dispersion: float = 80.0
@export var dano_impacto: float = 18.0
@export var cooldown_golpe: float = 0.8
@export var fuerza_rebote: float = 28.0

var asteroides_instanciados: Array[Node3D] = []
var radios_asteroides: Array[float] = []
var velocidades_rotacion: Array[Vector3] = []

var _jugador: CharacterBody3D = null
var _timer_golpe: float = 0.0


func _ready() -> void:
	_generar_campo()


func _process(delta: float) -> void:
	for i in range(asteroides_instanciados.size()):
		var asteroide := asteroides_instanciados[i]
		if is_instance_valid(asteroide):
			asteroide.rotate_x(velocidades_rotacion[i].x * delta)
			asteroide.rotate_y(velocidades_rotacion[i].y * delta)


func _physics_process(delta: float) -> void:
	if _timer_golpe > 0.0:
		_timer_golpe -= delta

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		if _jugador == null:
			return

	# Optimización: si la nave está fuera del campo completo, no revisa roca por roca
	if global_position.distance_squared_to(_jugador.global_position) > pow(radio_dispersion + 25.0, 2):
		return

	_verificar_colisiones()


func _verificar_colisiones() -> void:
	if _timer_golpe > 0.0:
		return

	for i in range(asteroides_instanciados.size()):
		var asteroide := asteroides_instanciados[i]
		if not is_instance_valid(asteroide):
			continue

		var offset := _jugador.global_position - asteroide.global_position
		var radio_choque := radios_asteroides[i] + 1.2 # Radio de la roca + margen de la nave

		if offset.length_squared() <= radio_choque * radio_choque:
			var normal := offset.normalized() if offset.length() > 0.01 else Vector3.UP
			# Empuja la nave fuera de la roca para que no quede atrapada dentro
			_jugador.global_position = asteroide.global_position + normal * (radio_choque + 0.3)
			_jugador.velocity = normal * fuerza_rebote

			if _jugador.has_method("recibir_dano"):
				_jugador.recibir_dano(dano_impacto)

			_timer_golpe = cooldown_golpe
			break


func _generar_campo() -> void:
	if not asteroide_scene:
		return

	for i in range(cantidad_asteroides):
		var inst := asteroide_scene.instantiate() as Node3D
		add_child(inst)

		var angulo := randf_range(0.0, TAU)
		var dist := randf_range(5.0, radio_dispersion)
		var offset_y := randf_range(-10.0, 10.0)

		inst.position = Vector3(cos(angulo) * dist, offset_y, sin(angulo) * dist)

		# Escala gigante (de 6m a 14m); el radio visual de una esfera base de 1m de diámetro es ~0.5 * escala
		var escala_random := randf_range(6.0, 14.0)
		inst.scale = Vector3.ONE * escala_random
		inst.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))

		asteroides_instanciados.append(inst)
		radios_asteroides.append(escala_random * 0.5)
		velocidades_rotacion.append(Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3)
		))
