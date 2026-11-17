extends Node3D
## Fondo de espacio profundo: estrellas nítidas y nebulosas sutiles.

@export_group("Estrellas")
@export var cantidad_estrellas: int = 1200
@export var radio_cielo: float = 500.0
@export var rotacion_cielo: float = 0.002

@export_group("Nebulosas y galaxias")
@export var cantidad_nebulosas: int = 2
@export var cantidad_galaxias: int = 10
@export_range(0.0, 1.0) var opacidad_nebulosas: float = 0.06

@export_group("Panorama (step_2.jpg)")
@export var usar_panorama: bool = true
@export var textura_panorama: Texture2D
@export var energia_panorama: float = 0.14
@export var entorno: WorldEnvironment

@export var semilla: int = 12345

const COLOR_AZUL := Color(0.2, 0.4, 0.85)
const COLOR_ROJO := Color(0.75, 0.2, 0.2)
const COLOR_DORADO := Color(0.85, 0.65, 0.25)

var _rng := RandomNumberGenerator.new()
var _pivote: Node3D


func _ready() -> void:
	_rng.seed = semilla
	_pivote = Node3D.new()
	_pivote.name = "Cielo"
	add_child(_pivote)
	_crear_estrellas()
	_crear_nebulosas()
	_crear_galaxias()
	if usar_panorama:
		_activar_panorama()


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		global_position = cam.global_position
	_pivote.rotate_y(rotacion_cielo * delta)


func _activar_panorama() -> void:
	if entorno == null or entorno.environment == null or textura_panorama == null:
		return
	var mat := PanoramaSkyMaterial.new()
	mat.panorama = textura_panorama
	mat.energy_multiplier = energia_panorama
	var cielo := Sky.new()
	cielo.sky_material = mat
	entorno.environment.sky = cielo
	entorno.environment.background_mode = Environment.BG_SKY


func _dir_aleatoria() -> Vector3:
	var z := _rng.randf_range(-1.0, 1.0)
	var a := _rng.randf_range(0.0, TAU)
	var r := sqrt(1.0 - z * z)
	return Vector3(r * cos(a), z, r * sin(a))


func _crear_estrellas() -> void:
	var malla := QuadMesh.new()
	malla.size = Vector2(1.0, 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.4, 1.4, 1.4)
	mat.disable_fog = true
	malla.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = malla
	mm.instance_count = cantidad_estrellas

	var tonos: Array[Color] = [
		Color(1.0, 1.0, 1.0),
		Color(0.82, 0.9, 1.0),
		Color(1.0, 0.96, 0.85)
	]
	for i in cantidad_estrellas:
		var pos := _dir_aleatoria() * radio_cielo * _rng.randf_range(0.9, 1.0)
		var tam := _rng.randf_range(0.3, 1.1) * (radio_cielo / 500.0)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * tam), pos))
		mm.set_instance_color(i, tonos[_rng.randi() % tonos.size()] * _rng.randf_range(0.45, 0.95))

	var nodo := MultiMeshInstance3D.new()
	nodo.name = "Estrellas"
	nodo.multimesh = mm
	nodo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivote.add_child(nodo)


func _textura_radial(colores: PackedColorArray, offsets: PackedFloat32Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = offsets
	g.colors = colores
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


func _material_aditivo(tex: Texture2D, alfa: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = tex
	m.albedo_color = Color(1, 1, 1, alfa)
	m.disable_fog = true
	return m


func _poner_quad(mat: Material, pos: Vector3, tam: Vector2, giro: float) -> void:
	var qm := QuadMesh.new()
	qm.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivote.add_child(mi)
	mi.look_at_from_position(pos, Vector3.ZERO, Vector3.UP)
	mi.rotate_object_local(Vector3.BACK, giro)


func _color_aleatorio() -> Color:
	var colores: Array[Color] = [COLOR_AZUL, COLOR_ROJO, COLOR_DORADO]
	return colores[_rng.randi() % colores.size()]


func _crear_nebulosas() -> void:
	if cantidad_nebulosas <= 0 or opacidad_nebulosas <= 0.0:
		return
	var escala := radio_cielo / 500.0
	for i in cantidad_nebulosas:
		var color := _color_aleatorio()
		var tex := _textura_radial(
			PackedColorArray([Color(color, 0.35), Color(color, 0.1), Color(color, 0.0)]),
			PackedFloat32Array([0.0, 0.45, 1.0])
		)
		var mat := _material_aditivo(tex, opacidad_nebulosas)
		var centro := _dir_aleatoria()
		for j in _rng.randi_range(2, 4):
			var d := (centro + _dir_aleatoria() * 0.15).normalized()
			var base := _rng.randf_range(70.0, 130.0) * escala
			var tam := Vector2(base, base * _rng.randf_range(0.5, 0.9))
			_poner_quad(mat, d * radio_cielo * 0.88, tam, _rng.randf_range(0.0, TAU))


func _crear_galaxias() -> void:
	var escala := radio_cielo / 500.0
	for i in cantidad_galaxias:
		var color := _color_aleatorio()
		var tex := _textura_radial(
			PackedColorArray([Color(1, 1, 1, 0.8), Color(color, 0.4), Color(color, 0.08), Color(color, 0.0)]),
			PackedFloat32Array([0.0, 0.12, 0.45, 1.0])
		)
		var mat := _material_aditivo(tex, 0.35)
		var base := _rng.randf_range(6.0, 15.0) * escala
		var tam := Vector2(base, base * _rng.randf_range(0.3, 0.6))
		_poner_quad(mat, _dir_aleatoria() * radio_cielo * 0.95, tam, _rng.randf_range(0.0, TAU))
