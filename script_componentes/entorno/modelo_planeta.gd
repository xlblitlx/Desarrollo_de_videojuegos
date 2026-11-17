extends Node3D
## Visual de un planeta: elige un planeta de ToyPlanets.fbx, lo escala al tama├▒o del planeta original
## (di├ímetro 50 = radio 25, el que usan la colisi├│n y la gravedad) y lo hace girar despacio.
## La l├│gica (planeta.gd, ├│rbita, reserva) no se toca.

const Util = preload("res://script_componentes/utilidades/util_modelos.gd")

## Di├ímetro del cuerpo del planeta (sin anillos). 50 = igual que la esfera original.
@export var diametro: float = 50.0
## 0 = aleatorio entre Toy_Planet_1 y Toy_Planet_10. Para fijar uno, pon su n├║mero.
@export_range(0, 10) var planeta_fijo: int = 0
@export var rango_giro: Vector2 = Vector2(0.02, 0.12)

const PALETA: Array[Color] = [
	Color(0.35, 0.6, 1.0), Color(0.95, 0.45, 0.3), Color(0.5, 0.85, 0.5),
	Color(0.9, 0.8, 0.4), Color(0.7, 0.5, 0.9), Color(0.4, 0.85, 0.85),
	Color(0.95, 0.6, 0.75), Color(0.75, 0.75, 0.8), Color(0.9, 0.7, 0.45),
	Color(0.6, 0.7, 0.9),
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
		# Plan B si los nombres cambiaron al importar: una malla cualquiera.
		var lista := Util.meshes_de(_toy)
		if lista.is_empty():
			return
		elegido = lista[randi() % lista.size()]

	# Oculta todo lo que no sea el planeta elegido (y sus anillos).
	for mi in Util.meshes_de(_toy):
		var propio := mi == elegido or elegido.is_ancestor_of(mi)
		if anillos != null:
			propio = propio or mi == anillos or anillos.is_ancestor_of(mi)
		mi.visible = propio
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Escala y centra seg├║n el cuerpo (los anillos no cuentan para el tama├▒o).
	var caja := Util.aabb_relativo(elegido, self, "Ring")
	var mayor := maxf(caja.size.x, maxf(caja.size.y, caja.size.z))
	if mayor > 0.0001:
		var s := diametro / mayor
		_toy.transform = Transform3D(Basis.from_scale(Vector3.ONE * s), -caja.get_center() * s)

	_asegurar_material(elegido, PALETA[id % PALETA.size()])
	if anillos != null:
		_asegurar_material(anillos, Color(0.9, 0.8, 0.6))

	_vel = randf_range(rango_giro.x, rango_giro.y) * (1.0 if randf() > 0.5 else -1.0)
	rotation.x = randf_range(-0.3, 0.3)


func _process(delta: float) -> void:
	rotation.y += _vel * delta


## Si el FBX lleg├│ sin texturas, pinta con un color s├│lido para que no se vea blanco.
func _asegurar_material(raiz: Node3D, color: Color) -> void:
	for mi in Util.meshes_de(raiz):
		for s in mi.get_surface_override_material_count():
			var m := mi.get_active_material(s)
			var sin_diseno := true
			if m is BaseMaterial3D:
				var bm := m as BaseMaterial3D
				var c := bm.albedo_color
				var casi_gris := absf(c.r - c.g) < 0.1 and absf(c.g - c.b) < 0.1
				sin_diseno = bm.albedo_texture == null and casi_gris
			if sin_diseno:
				var nm := StandardMaterial3D.new()
				nm.albedo_color = color
				nm.roughness = 0.8
				mi.set_surface_override_material(s, nm)
