class_name CampoAsteroides
extends Node3D

@export var asteroide_scene: PackedScene
@export var cantidad_asteroides: int = 14
@export var radio_dispersion: float = 80.0

var asteroides_instanciados: Array[Node3D] = []
var velocidades_rotacion: Array[Vector3] = []

func _ready() -> void:
	_generar_campo()

func _process(delta: float) -> void:
	for i in range(asteroides_instanciados.size()):
		var asteroide = asteroides_instanciados[i]
		if is_instance_valid(asteroide):
			asteroide.rotate_x(velocidades_rotacion[i].x * delta)
			asteroide.rotate_y(velocidades_rotacion[i].y * delta)

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
		
		# Aumentamos la escala para que sean rocas gigantes que bloqueen el paso (de 6m a 14m)
		var escala_random := randf_range(6.0, 14.0)
		inst.scale = Vector3.ONE * escala_random
		inst.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
		
		asteroides_instanciados.append(inst)
		velocidades_rotacion.append(Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3)
		))
