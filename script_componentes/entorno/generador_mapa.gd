class_name GeneradorMapa
extends Node3D

@export_group("Configuración Procedural")
@export var planeta_scene: PackedScene
@export var campo_asteroides_scene: PackedScene
@export var cantidad_planetas: int = 8
@export var brecha_minima_orbitas: float = 135.0 # Espacio abierto mínimo entre bordes de órbitas
@export var brecha_maxima_vuelo: float = 285.0   # Espacio abierto máximo (100% alcanzable con 1 tanque)
@export var dispersion_vertical: float = 175.0   # Rango vertical (-175m a +175m) para romper la fila

@export_group("Variación de Planetas")
@export var tamano_minimo: float = 0.75
@export var tamano_maximo: float = 1.85


func _ready() -> void:
	randomize()
	generar_sistema_planetario()


## Coordinador principal: construye una red 3D abierta, sin solapamientos y con rutas de asteroides
func generar_sistema_planetario() -> void:
	if not planeta_scene:
		push_warning("Falta asignar Planeta.tscn en GeneradorMapa")
		return

	var radio_orbita_base := _detectar_radio_orbita_base()
	var posiciones: Array[Vector3] = []
	var radios_orbita: Array[float] = []
	var direcciones_entrada: Array[Vector3] = []

	for i in range(cantidad_planetas):
		var escala := randf_range(tamano_minimo, tamano_maximo)
		if i == 0:
			escala = clampf(escala, 1.0, 1.35) # Planeta inicial equilibrado

		var radio_nuevo := radio_orbita_base * escala
		var resultado := _buscar_posicion_3d(i, radio_nuevo, posiciones, radios_orbita, direcciones_entrada)

		if resultado.pos != Vector3.INF:
			posiciones.append(resultado.pos)
			radios_orbita.append(radio_nuevo)
			direcciones_entrada.append(resultado.dir)
			_instanciar_nodo(planeta_scene, resultado.pos, escala)

	_generar_red_asteroides(posiciones, radios_orbita)


## Mide automáticamente el radio real de ZonaOrbita en planeta.tscn para evitar solapamientos
func _detectar_radio_orbita_base() -> float:
	var temp := planeta_scene.instantiate() as Node3D
	if temp == null:
		return 90.0

	var radio_detectado := 85.0
	var zona := temp.get_node_or_null("ZonaOrbita") as Node3D
	if zona:
		for hijo in zona.get_children():
			if hijo is CollisionShape3D and hijo.shape is SphereShape3D:
				radio_detectado = maxf(radio_detectado, hijo.shape.radius * hijo.scale.x * zona.scale.x)
			elif hijo is MeshInstance3D and hijo.mesh:
				var r_malla: float = hijo.get_aabb().size.x * 0.5 * hijo.scale.x * zona.scale.x
				radio_detectado = maxf(radio_detectado, r_malla)

	temp.free()
	return radio_detectado


## Ubica planetas en 3D evitando que formen una fila y garantizando que el combustible alcance
func _buscar_posicion_3d(
	indice: int,
	radio_nuevo: float,
	existentes: Array[Vector3],
	radios_existentes: Array[float],
	direcciones_entrada: Array[Vector3]
) -> Dictionary:
	if indice == 0:
		var ang := randf_range(0.0, TAU)
		var dist := radio_nuevo + 35.0
		return {
			"pos": Vector3(cos(ang) * dist, randf_range(-10.0, 10.0), sin(ang) * dist),
			"dir": Vector3.ZERO
		}

	for intento in range(240):
		var idx_ancla := randi() % existentes.size()
		var ancla := existentes[idx_ancla]
		var radio_ancla := radios_existentes[idx_ancla]
		var dir_previa := direcciones_entrada[idx_ancla]

		# Coordenadas esféricas con fuerte inclinación vertical (-55° a +55°)
		var azimut := randf_range(0.0, TAU)
		var elevacion := randf_range(-0.95, 0.95)
		var dir_3d := Vector3(
			cos(elevacion) * cos(azimut),
			sin(elevacion),
			cos(elevacion) * sin(azimut)
		).normalized()

		# Evita seguir en línea recta respecto al salto anterior (rompe la fila)
		if dir_previa != Vector3.ZERO and dir_3d.dot(dir_previa) > 0.45:
			continue

		# Distancia medida borde-a-borde de órbita para garantizar espacio para asteroides y combustible
		var brecha := randf_range(brecha_minima_orbitas, brecha_maxima_vuelo)
		var dist_centros := radio_ancla + radio_nuevo + brecha
		var candidata := ancla + dir_3d * dist_centros
		candidata.y = clampf(candidata.y, -dispersion_vertical, dispersion_vertical)

		if _es_orbita_libre(candidata, radio_nuevo, existentes, radios_existentes):
			return { "pos": candidata, "dir": dir_3d }

	return { "pos": Vector3.INF, "dir": Vector3.ZERO }


## Verifica que el borde de la nueva órbita respete la brecha mínima frente a todos los planetas
func _es_orbita_libre(
	candidata: Vector3,
	radio_nuevo: float,
	existentes: Array[Vector3],
	radios_existentes: Array[float]
) -> bool:
	for i in range(existentes.size()):
		var dist_minima := radio_nuevo + radios_existentes[i] + brecha_minima_orbitas
		if candidata.distance_to(existentes[i]) < dist_minima:
			return false
	return true


## Coloca cinturones de asteroides en las brechas abiertas entre planetas vecinos
func _generar_red_asteroides(planetas: Array[Vector3], radios_orbita: Array[float]) -> void:
	if not campo_asteroides_scene or planetas.size() < 2:
		return

	var campos_creados: Array[Vector3] = []

	for i in range(planetas.size()):
		var origen := planetas[i]
		var indices_vecinos: Array[int] = []
		for j in range(planetas.size()):
			if i != j:
				indices_vecinos.append(j)

		indices_vecinos.sort_custom(func(a: int, b: int) -> bool:
			return origen.distance_to(planetas[a]) < origen.distance_to(planetas[b])
		)

		var limite := mini(2, indices_vecinos.size())
		for k in range(limite):
			var idx_dest := indices_vecinos[k]
			var destino := planetas[idx_dest]

			# Punto medio exacto entre los bordes de ambas órbitas (no entre centros)
			var dir := (destino - origen).normalized()
			var borde_a := origen + dir * radios_orbita[i]
			var borde_b := destino - dir * radios_orbita[idx_dest]
			var medio := (borde_a + borde_b) * 0.5

			if _punto_fuera_de_orbitas(medio, 55.0, planetas, radios_orbita) and not _hay_punto_cerca(medio, campos_creados, 130.0):
				campos_creados.append(medio)
				_instanciar_nodo(campo_asteroides_scene, medio)


func _punto_fuera_de_orbitas(
	punto: Vector3,
	margen_seguridad: float,
	planetas: Array[Vector3],
	radios_orbita: Array[float]
) -> bool:
	for i in range(planetas.size()):
		if punto.distance_to(planetas[i]) < (radios_orbita[i] + margen_seguridad):
			return false
	return true


func _hay_punto_cerca(punto: Vector3, lista: Array[Vector3], radio: float) -> bool:
	for item in lista:
		if item.distance_to(punto) < radio:
			return true
	return false


func _instanciar_nodo(escena: PackedScene, posicion: Vector3, escala: float = 1.0) -> void:
	var instancia := escena.instantiate() as Node3D
	add_child(instancia)
	instancia.global_position = posicion
	if escala != 1.0:
		instancia.scale = Vector3.ONE * escala
