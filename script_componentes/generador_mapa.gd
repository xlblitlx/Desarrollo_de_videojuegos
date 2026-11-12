class_name GeneradorMapa
extends Node3D

@export_group("Configuración Procedural")
@export var planeta_scene: PackedScene
@export var campo_asteroides_scene: PackedScene
@export var cantidad_planetas: int = 8
@export var radio_sistema_global: float = 800.0
@export var distancia_minima_entre_planetas: float = 450.0

@export_group("Variación de Planetas")
@export var tamano_minimo: float = 0.5
@export var tamano_maximo: float = 3.0

func _ready() -> void:
	randomize()
	generar_sistema_planetario()

## Coordinador principal
func generar_sistema_planetario() -> void:
	if not planeta_scene:
		push_warning("Falta asignar Planeta.tscn en GeneradorMapa")
		return

	var planetas: Array[Vector3] = []
	for i in range(cantidad_planetas):
		var pos := _buscar_punto_libre(planetas, distancia_minima_entre_planetas)
		if pos != Vector3.ZERO:
			planetas.append(pos)
			_instanciar_nodo(planeta_scene, pos, randf_range(tamano_minimo, tamano_maximo))

	_generar_red_asteroides(planetas)

## Busca una coordenada válida lejos de los puntos existentes
func _buscar_punto_libre(existentes: Array[Vector3], radio_minimo: float) -> Vector3:
	for intento in range(150):
		var angulo := randf_range(0.0, TAU)
		var dist := randf_range(150.0, radio_sistema_global * 0.9)
		var candidato := Vector3(cos(angulo) * dist, randf_range(-15.0, 15.0), sin(angulo) * dist)
		
		if not _hay_punto_cerca(candidato, existentes, radio_minimo):
			return candidato
	return Vector3.ZERO

## Conecta cada planeta con sus 2 vecinos más cercanos mediante campos de asteroides
func _generar_red_asteroides(planetas: Array[Vector3]) -> void:
	if not campo_asteroides_scene or planetas.size() < 2:
		return

	var campos_creados: Array[Vector3] = []

	for origen in planetas:
		var vecinos: Array[Vector3] = []
		vecinos.assign(planetas.filter(func(p: Vector3) -> bool: return p != origen))
		vecinos.sort_custom(func(a: Vector3, b: Vector3) -> bool:
			return origen.distance_to(a) < origen.distance_to(b)
		)

		var limite: int = mini(2, vecinos.size())
		for k in range(limite):
			var destino: Vector3 = vecinos[k]
			var medio: Vector3 = (origen + destino) / 2.0

			if origen.distance_to(destino) > 220.0:
				# Valida que no invada ningún planeta (140m) ni duplique otro campo (70m)
				if not _hay_punto_cerca(medio, planetas, 140.0) and not _hay_punto_cerca(medio, campos_creados, 70.0):
					campos_creados.append(medio)
					_instanciar_nodo(campo_asteroides_scene, medio)

## Utilidad única: Verifica si existe algún punto dentro del radio dado
func _hay_punto_cerca(punto: Vector3, lista: Array[Vector3], radio: float) -> bool:
	for item in lista:
		if item.distance_to(punto) < radio:
			return true
	return false

## Utilidad única: Instancia cualquier escena en una posición y escala
func _instanciar_nodo(escena: PackedScene, posicion: Vector3, escala: float = 1.0) -> void:
	var instancia := escena.instantiate() as Node3D
	add_child(instancia)
	instancia.global_position = posicion
	if escala != 1.0:
		instancia.scale = Vector3.ONE * escala
