extends Node3D
## Visual de un planeta: elige un planeta de ToyPlanets.fbx, lo escala al tamaño del planeta original
## (diámetro 50 = radio 25, el que usan la colisión y la gravedad), genera biomas procedurales y lo hace girar.

const Util = preload("res://script_componentes/utilidades/util_modelos.gd")

@export var diametro: float = 50.0
@export_range(0, 10) var planeta_fijo: int = 0
@export var rango_giro: Vector2 = Vector2(0.02, 0.12)
@export var usar_biomas_procedurales: bool = true

# Cada bioma define: [color_bajo, color_medio, color_alto, color_atmosfera, es_gaseoso]
const BIOMAS: Array[Dictionary] = [
	{ # 1. Terráqueo (océanos, tierra y nubes/cumbres)
		"c1": Color("#1d4e89"), "c2": Color("#4ea8de"), "c3": Color("#70e000"),
		"atm": Color("#48cae4"), "gaseoso": false, "rugosidad": 0.65
	},
	{ # 2. Desértico / Marciano
		"c1": Color("#7f2704"), "c2": Color("#d94801"), "c3": Color("#fdae6b"),
		"atm": Color("#fd8d3c"), "gaseoso": false, "rugosidad": 0.92
	},
	{ # 3. Selva / Exótico
		"c1": Color("#1b4332"), "c2": Color("#40916c"), "c3": Color("#b7e4c7"),
		"atm": Color("#74c69d"), "gaseoso": false, "rugosidad": 0.78
	},
	{ # 4. Gigante Gaseoso Dorado (estilo Saturno/Júpiter)
		"c1": Color("#9c6644"), "c2": Color("#e6ccb2"), "c3": Color("#ddb892"),
		"atm": Color("#ede0d4"), "gaseoso": true, "rugosidad": 0.55
	},
	{ # 5. Amatista / Cristalino
		"c1": Color("#3c096c"), "c2": Color("#7b2cbf"), "c3": Color("#e0aaff"),
		"atm": Color("#c77dff"), "gaseoso": false, "rugosidad": 0.5
	},
	{ # 6. Oceánico / Glacial
		"c1": Color("#023e8a"), "c2": Color("#0096c7"), "c3": Color("#caf0f8"),
		"atm": Color("#90e0ef"), "gaseoso": false, "rugosidad": 0.45
	},
	{ # 7. Coral / Nebulosa
		"c1": Color("#800f2f"), "c2": Color("#ff4d6d"), "c3": Color("#ffb3c1"),
		"atm": Color("#ff758f"), "gaseoso": true, "rugosidad": 0.6
	},
	{ # 8. Lunar / Rocoso
		"c1": Color("#343a40"), "c2": Color("#6c757d"), "c3": Color("#ced4da"),
		"atm": Color("#adb5bd"), "gaseoso": false, "rugosidad": 0.95
	},
	{ # 9. Volcánico / Ámbar
		"c1": Color("#370617"), "c2": Color("#dc2f02"), "c3": Color("#ffba08"),
		"atm": Color("#f48c06"), "gaseoso": false, "rugosidad": 0.82
	},
	{ # 10. Gigante Helado Cian
		"c1": Color("#184e77"), "c2": Color("#1e6091"), "c3": Color("#99d98c"),
		"atm": Color("#52b69a"), "gaseoso": true, "rugosidad": 0.5
	},
]

var _vel: float = 0.05

@onready var _toy: Node3D = get_node_or_null("Toy")


func _ready() -> void:
	if _toy == null:
		return
	var id := planeta_fijo if planeta_fijo > 0 else randi_range(1, 10)
	var nombre := "Toy_Planet_%d" % id
	var elegido := _toy.find_child(nombre, true, false) as Node3D
	var anillos := _toy.find_child(nombre + "_Rings", true, false) as Node3D

	if elegido == null:
		var lista := Util.meshes_de(_toy)
		if lista.is_empty():
			return
		elegido = lista[randi() % lista.size()]

	for mi in Util.meshes_de(_toy):
		var propio := mi == elegido or elegido.is_ancestor_of(mi)
		if anillos != null:
			propio = propio or mi == anillos or anillos.is_ancestor_of(mi)
		mi.visible = propio
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var caja := Util.aabb_relativo(elegido, self, "Ring")
	var mayor := maxf(caja.size.x, maxf(caja.size.y, caja.size.z))
	if mayor > 0.0001:
		var s := diametro / mayor
		_toy.transform = Transform3D(Basis.from_scale(Vector3.ONE * s), -caja.get_center() * s)

	var bioma := BIOMAS[(id - 1) % BIOMAS.size()]
	_aplicar_aspecto_natural(elegido, bioma, id)
	if anillos != null:
		_aplicar_aspecto_anillos(anillos, bioma, id)

	_vel = randf_range(rango_giro.x, rango_giro.y) * (1.0 if randf() > 0.5 else -1.0)
	rotation.x = randf_range(-0.32, 0.32)
	rotation.z = randf_range(-0.18, 0.18)


func _process(delta: float) -> void:
	rotation.y += _vel * delta


func _aplicar_aspecto_natural(raiz: Node3D, bioma: Dictionary, semilla_base: int) -> void:
	var mat := _crear_material_planetario(bioma, semilla_base)
	for mi in Util.meshes_de(raiz):
		var superficies := maxi(1, mi.get_surface_override_material_count())
		for s in range(superficies):
			var actual := mi.get_active_material(s)
			if not usar_biomas_procedurales and actual is BaseMaterial3D and (actual as BaseMaterial3D).albedo_texture != null:
				continue
			mi.set_surface_override_material(s, mat)


func _crear_material_planetario(bioma: Dictionary, semilla_base: int) -> StandardMaterial3D:
	var nm := StandardMaterial3D.new()
	var es_gaseoso: bool = bioma["gaseoso"]

	# 1. Ruido fractal para continentes / nubes / bandas
	var ruido := FastNoiseLite.new()
	ruido.seed = semilla_base * 137 + randi_range(1, 50)
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.fractal_type = FastNoiseLite.FRACTAL_FBM
	ruido.fractal_octaves = 4
	ruido.frequency = 0.018 if es_gaseoso else 0.012

	# 2. Degradado de 3 colores del bioma
	var grad := Gradient.new()
	grad.set_color(0, bioma["c1"])
	grad.set_offset(0, 0.25)
	grad.set_color(1, bioma["c3"])
	grad.set_offset(1, 0.82)
	grad.add_point(0.55, bioma["c2"])

	var tex_color := NoiseTexture2D.new()
	tex_color.width = 256
	tex_color.height = 128
	tex_color.seamless = true
	tex_color.noise = ruido
	tex_color.color_ramp = grad

	# Estira horizontalmente si es gigante gaseoso para formar bandas atmosféricas
	if es_gaseoso:
		nm.uv1_scale = Vector3(0.35, 3.2, 1.0)
	else:
		nm.uv1_scale = Vector3(1.5, 1.5, 1.0)

	nm.albedo_texture = tex_color
	nm.roughness = bioma["rugosidad"]
	nm.metallic = 0.05

	# 3. Relieve sutil en planetas rocosos
	if not es_gaseoso:
		var tex_relieve := NoiseTexture2D.new()
		tex_relieve.width = 256
		tex_relieve.height = 128
		tex_relieve.seamless = true
		tex_relieve.as_normal_map = true
		tex_relieve.bump_strength = 3.5
		tex_relieve.noise = ruido
		nm.normal_enabled = true
		nm.normal_texture = tex_relieve
		nm.normal_scale = 0.65

	# 4. Halo atmosférico en los bordes (Rim Light)
	nm.rim_enabled = true
	nm.rim = 0.65
	nm.rim_tint = 0.75

	# 5. Emisión muy tenue para que no se vean completamente negros en la sombra
	nm.emission_enabled = true
	nm.emission = (bioma["atm"] as Color).darkened(0.65)
	nm.emission_energy_multiplier = 0.28

	return nm


func _aplicar_aspecto_anillos(anillos: Node3D, bioma: Dictionary, semilla_base: int) -> void:
	var ruido := FastNoiseLite.new()
	ruido.seed = semilla_base * 91
	ruido.frequency = 0.08

	var base_c: Color = bioma["c2"]
	var grad := Gradient.new()
	grad.set_color(0, base_c.darkened(0.35))
	grad.set_color(1, (bioma["c3"] as Color).lightened(0.15))

	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = ruido
	tex.color_ramp = grad

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.75
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.88)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	for mi in Util.meshes_de(anillos):
		var superficies := maxi(1, mi.get_surface_override_material_count())
		for s in range(superficies):
			mi.set_surface_override_material(s, mat)
