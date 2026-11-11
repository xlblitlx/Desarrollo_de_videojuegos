class_name GeneradorMapa
extends Node3D

@export_group("Configuración Procedural")
@export var planeta_scene: PackedScene
@export var cantidad_planetas: int = 8
@export var radio_sistema_global: float = 500.0
@export var distancia_minima_entre_planetas: float = 300.0 # Subimos el espacio mínimo base


@export_group("Variación de Planetas")
@export var tamano_minimo: float = 0.8
@export var tamano_maximo: float = 2.5

func _ready() -> void:
	randomize()
	generar_sistema_planetario()

## Función principal: Solo coordina los pasos
func generar_sistema_planetario() -> void:
	if not planeta_scene:
		push_warning("Falta asignar la escena Planeta.tscn")
		return

	var posiciones: Array[Vector3] = []
	for i in range(cantidad_planetas):
		var pos := _obtener_posicion_valida(posiciones)
		if pos != Vector3.ZERO:
			posiciones.append(pos)
			_crear_planeta(pos)

## Responsabilidad 1: Encontrar un punto válido sin colisiones
func _obtener_posicion_valida(existentes: Array[Vector3]) -> Vector3:
	for intento in range(150):
		var candidato := _generar_punto_aleatorio()
		if _es_posicion_distante(candidato, existentes):
			return candidato
	return Vector3.ZERO

## Responsabilidad 2: Matemática pura de posición
func _generar_punto_aleatorio() -> Vector3:
	var angulo := randf_range(0.0, TAU)
	# Distribuimos en un radio más amplio (de 150m a 700m) para liberar el centro
	var distancia := randf_range(150.0, radio_sistema_global * 0.9)
	return Vector3(cos(angulo) * distancia, randf_range(-15.0, 15.0), sin(angulo) * distancia)

## Responsabilidad 3: Validar distancia mínima
func _es_posicion_distante(punto: Vector3, existentes: Array[Vector3]) -> bool:
	for pos in existentes:
		if pos.distance_to(punto) < distancia_minima_entre_planetas:
			return false
	return true

## Responsabilidad 4: Instanciar en la escena de Godot
func _crear_planeta(posicion: Vector3) -> void:
	var planeta = planeta_scene.instantiate() as Node3D
	add_child(planeta)
	planeta.global_position = posicion
	planeta.scale = Vector3.ONE * randf_range(tamano_minimo, tamano_maximo)
