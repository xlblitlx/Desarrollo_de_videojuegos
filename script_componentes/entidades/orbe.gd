class_name Orbe
extends Area3D
## Recompensa de EXP con forma de cristal/diamante y etiqueta flotante "XP"
## para distinguirse al instante de las balas enemigas.

signal orbe_recogido(valor: int)

@export var valor: int = 10
@export var radio_iman: float = 28.0
@export var velocidad_iman: float = 25.0
@export var distancia_recoleccion: float = 2.4
@export var jugador: CharacterBody3D

@export_group("Apariencia XP")
@export var color_xp: Color = Color("#2ef29b")
@export var mostrar_etiqueta_xp: bool = true
@export var mostrar_valor_en_etiqueta: bool = false # false -> "XP" | true -> "+10 XP"
@export var velocidad_rotacion: float = 2.2
@export var amplitud_flotacion: float = 0.28
@export var frecuencia_flotacion: float = 3.0

var _recogido: bool = false
var _tiempo: float = 0.0
var _velocidad_actual_iman: float = 0.0
var _material_cristal: StandardMaterial3D = null
var _etiqueta_3d: Label3D = null


func _ready() -> void:
	add_to_group("orbes")
	body_entered.connect(_al_entrar_cuerpo)
	_tiempo = randf() * TAU
	_construir_cristal_y_etiqueta()


func _construir_cristal_y_etiqueta() -> void:
	_material_cristal = StandardMaterial3D.new()
	_material_cristal.albedo_color = color_xp
	_material_cristal.emission_enabled = true
	_material_cristal.emission = color_xp
	_material_cristal.emission_energy_multiplier = 1.65
	_material_cristal.metallic = 0.25
	_material_cristal.roughness = 0.2

	# Reemplaza o crea una malla con forma de diamante/cristal (4 caras)
	var malla_existente := _buscar_malla(self)
	if malla_existente != null:
		malla_existente.mesh = _crear_malla_diamante()
		malla_existente.material_override = _material_cristal
	else:
		var cristal := MeshInstance3D.new()
		cristal.name = "CristalXP"
		cristal.mesh = _crear_malla_diamante()
		cristal.material_override = _material_cristal
		add_child(cristal)

	# Etiqueta flotante "XP" siempre orientada hacia la cámara
	if mostrar_etiqueta_xp:
		_etiqueta_3d = Label3D.new()
		_etiqueta_3d.name = "EtiquetaXP"
		_etiqueta_3d.text = ("+%d XP" % valor) if mostrar_valor_en_etiqueta else "XP"
		_etiqueta_3d.position = Vector3(0.0, 1.35, 0.0)
		_etiqueta_3d.font_size = 38
		_etiqueta_3d.pixel_size = 0.014
		_etiqueta_3d.outline_size = 8
		_etiqueta_3d.modulate = Color("#b8ffe0")
		_etiqueta_3d.outline_modulate = Color("#062619")
		_etiqueta_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_etiqueta_3d.no_depth_test = false
		add_child(_etiqueta_3d)


func _crear_malla_diamante() -> ArrayMesh:
	# Octaedro alargado (forma de gema/diamante) para evitar silueta circular
	var top := Vector3(0.0, 1.05, 0.0)
	var bottom := Vector3(0.0, -1.05, 0.0)
	var r := 0.65
	var v0 := Vector3(r, 0.0, 0.0)
	var v1 := Vector3(0.0, 0.0, r)
	var v2 := Vector3(-r, 0.0, 0.0)
	var v3 := Vector3(0.0, 0.0, -r)

	var caras := [
		[top, v1, v0],
		[top, v2, v1],
		[top, v3, v2],
		[top, v0, v3],
		[bottom, v0, v1],
		[bottom, v1, v2],
		[bottom, v2, v3],
		[bottom, v3, v0]
	]

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cara in caras:
		var a: Vector3 = cara[0]
		var b: Vector3 = cara[1]
		var c: Vector3 = cara[2]
		var normal := (b - a).cross(c - a).normalized()
		st.set_normal(normal)
		st.add_vertex(a)
		st.set_normal(normal)
		st.add_vertex(b)
		st.set_normal(normal)
		st.add_vertex(c)

	return st.commit()


func _buscar_malla(nodo: Node) -> MeshInstance3D:
	if nodo is MeshInstance3D:
		return nodo as MeshInstance3D
	for hijo in nodo.get_children():
		var encontrada := _buscar_malla(hijo)
		if encontrada != null:
			return encontrada
	return null


func _physics_process(delta: float) -> void:
	if _recogido:
		return

	_tiempo += delta
	_animar_gema(delta)

	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if jugador == null:
		return

	var distancia := global_position.distance_to(jugador.global_position)
	if distancia <= distancia_recoleccion:
		_recoger()
	elif distancia <= radio_iman:
		_velocidad_actual_iman = minf(_velocidad_actual_iman + velocidad_iman * 2.2 * delta, velocidad_iman * 1.45)
		global_position = global_position.move_toward(
			jugador.global_position, _velocidad_actual_iman * delta
		)
		if _material_cristal != null:
			_material_cristal.emission_energy_multiplier = lerpf(_material_cristal.emission_energy_multiplier, 2.4, 8.0 * delta)
	else:
		_velocidad_actual_iman = lerpf(_velocidad_actual_iman, velocidad_iman * 0.35, 6.0 * delta)
		if _material_cristal != null:
			_material_cristal.emission_energy_multiplier = lerpf(_material_cristal.emission_energy_multiplier, 1.65, 6.0 * delta)


func _animar_gema(delta: float) -> void:
	rotate_y(velocidad_rotacion * delta)
	position.y += cos(_tiempo * frecuencia_flotacion) * amplitud_flotacion * delta


func _al_entrar_cuerpo(cuerpo: Node3D) -> void:
	if cuerpo == jugador or cuerpo.is_in_group("jugador"):
		_recoger()


func _recoger() -> void:
	if _recogido:
		return
	_recogido = true

	if orbe_recogido.get_connections().is_empty():
		_entregar_exp_directa()
	else:
		orbe_recogido.emit(valor)

	queue_free()


func _entregar_exp_directa() -> void:
	var raiz := get_tree().current_scene
	if raiz == null:
		return

	for nodo in raiz.find_children("*", "Node", true, false):
		if nodo.has_method("sumar_experiencia"):
			nodo.sumar_experiencia(valor)
			return
