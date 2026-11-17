class_name ModeloNave
extends Node3D

const Util = preload("res://script_componentes/utilidades/util_modelos.gd")

@export_group("Modelo")
@export var largo: float = 3.0
@export var giro_y: float = 180.0

@export_group("Neon")
@export var color_neon: Color = Color(0.1, 0.75, 1.0)
@export var color_casco: Color = Color(0.16, 0.19, 0.25)
@export var energia_neon: float = 1.1
@export var luces_neon: bool = false
@export var energia_luces: float = 0.45

@export_group("Propulsion")
@export var estela: bool = true
@export var estela_siempre_activa: bool = false
@export_range(0.0, 1.0) var nivel_reposo: float = 0.2
@export var longitud_estela: float = 1.2
@export var radio_estela: float = 0.16
@export var color_nucleo: Color = Color(1.0, 0.95, 0.7)
@export var color_borde: Color = Color(1.0, 0.25, 0.05)

@onready var _modelo: Node3D = get_node_or_null("Modelo")


func _ready() -> void:
	if _modelo == null:
		push_warning("ModeloNave: falta el nodo hijo 'Modelo'.")
		return

	_limpiar_nodos_extra()
	var caja := _ajustar_escala_y_orientacion()
	_aplicar_materiales()

	if luces_neon and caja.size != Vector3.ZERO:
		_agregar_luz_sutil(caja)

	if estela:
		var nodo_estela := EstelaPropulsion.new()
		nodo_estela.name = "EstelaPropulsion"
		var z_motor := caja.end.z if caja.size != Vector3.ZERO else largo * 0.5
		var y_motor := caja.get_center().y if caja.size != Vector3.ZERO else 0.0
		nodo_estela.position = Vector3(0.0, y_motor, z_motor)
		add_child(nodo_estela)
		nodo_estela.configurar(largo, longitud_estela, radio_estela, color_nucleo, color_borde, estela_siempre_activa, nivel_reposo)


func _limpiar_nodos_extra() -> void:
	for n in _modelo.find_children("*", "Camera3D", true, false):
		n.queue_free()
	for n in _modelo.find_children("*", "Light3D", true, false):
		n.queue_free()


func _ajustar_escala_y_orientacion() -> AABB:
	var rot := Basis.from_euler(Vector3(0.0, deg_to_rad(giro_y), 0.0))
	_modelo.transform = Transform3D(rot, Vector3.ZERO)

	var caja := Util.aabb_relativo(_modelo, self)
	var mayor := maxf(caja.size.x, maxf(caja.size.y, caja.size.z))
	if mayor < 0.0001:
		return AABB()

	var escala := largo / mayor
	_modelo.transform = Transform3D(rot.scaled(Vector3.ONE * escala), -caja.get_center() * escala)
	return Util.aabb_relativo(_modelo, self)


func _aplicar_materiales() -> void:
	for mi in Util.meshes_de(_modelo):
		for s in mi.get_surface_override_material_count():
			var mat := mi.get_active_material(s)
			if not (mat is BaseMaterial3D):
				continue
			var nuevo := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			# Solo convierte en neón las partes que ya venían emisivas en el FBX
			if nuevo.emission_enabled and nuevo.emission.get_luminance() > 0.05:
				nuevo.albedo_color = color_neon * 0.4
				nuevo.emission = color_neon
				nuevo.emission_energy_multiplier = minf(energia_neon, 1.3)
			else:
				nuevo.emission_enabled = false
				nuevo.albedo_color = color_casco
				nuevo.metallic = 0.45
				nuevo.roughness = 0.5
			mi.set_surface_override_material(s, nuevo)


func _agregar_luz_sutil(caja: AABB) -> void:
	var luz := OmniLight3D.new()
	luz.light_color = color_neon
	luz.light_energy = energia_luces
	luz.omni_range = largo * 1.1
	luz.shadow_enabled = false
	luz.position = caja.get_center()
	add_child(luz)
