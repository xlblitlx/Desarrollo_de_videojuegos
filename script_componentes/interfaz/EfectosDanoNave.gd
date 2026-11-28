class_name EfectosDanoNave
extends Node
## Gestiona el feedback visual 3D de daño sobre cualquier nave (jugador o enemigo):
## destello emisivo de impacto en el fuselaje, sacudida del modelo y humo al tener <= 40% de vida.

@export_range(5.0, 80.0) var umbral_casco_danado: float = 40.0
@export var color_impacto: Color = Color(1.0, 0.2, 0.1, 0.0)
@export var activar_humo: bool = true

var _entidad: Node3D = null
var _nodo_malla: Node3D = null
var _material_dano: StandardMaterial3D = null
var _particulas_humo: GPUParticles3D = null

var _vida_anterior: float = -1.0
var _alpha_flash: float = 0.0
var _tiempo: float = 0.0


func _ready() -> void:
	_entidad = get_parent() as Node3D
	if not is_instance_valid(_entidad):
		return
	await get_tree().process_frame
	_configurar_mallas_y_humo()


func _configurar_mallas_y_humo() -> void:
	_material_dano = StandardMaterial3D.new()
	_material_dano.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_dano.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_dano.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material_dano.albedo_color = color_impacto
	_material_dano.emission_enabled = true
	_material_dano.emission = Color(1.0, 0.18, 0.08)
	_material_dano.emission_energy_multiplier = 2.5

	var mallas: Array[MeshInstance3D] = []
	_buscar_mallas_recursivo(_entidad, mallas)
	for m in mallas:
		m.material_overlay = _material_dano

	_nodo_malla = _entidad.get_node_or_null("Mesh") as Node3D
	if _nodo_malla == null and not mallas.is_empty():
		_nodo_malla = mallas[0]
	if _nodo_malla == null:
		_nodo_malla = _entidad

	if activar_humo:
		_crear_particulas_humo()


func _crear_particulas_humo() -> void:
	_particulas_humo = GPUParticles3D.new()
	_particulas_humo.emitting = false
	_particulas_humo.amount = 32
	_particulas_humo.lifetime = 0.95
	_particulas_humo.local_coords = false

	var proc_mat := ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc_mat.emission_sphere_radius = 0.6
	proc_mat.direction = Vector3(0.0, 0.4, 1.0)
	proc_mat.spread = 45.0
	proc_mat.initial_velocity_min = 2.0
	proc_mat.initial_velocity_max = 5.0
	proc_mat.gravity = Vector3.ZERO
	proc_mat.scale_min = 0.45
	proc_mat.scale_max = 1.05
	proc_mat.color = Color(0.72, 0.68, 0.65, 0.85)
	_particulas_humo.process_material = proc_mat

	var esfera_humo := SphereMesh.new()
	esfera_humo.radius = 0.4
	esfera_humo.height = 0.8
	esfera_humo.radial_segments = 8
	esfera_humo.rings = 4

	var mat_humo := StandardMaterial3D.new()
	mat_humo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_humo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_humo.vertex_color_use_as_albedo = true
	esfera_humo.material = mat_humo

	_particulas_humo.draw_pass_1 = esfera_humo
	_nodo_malla.add_child(_particulas_humo)


func _process(delta: float) -> void:
	if not is_instance_valid(_entidad) or _material_dano == null:
		return

	_tiempo += delta

	var vida := _leer_propiedad_en_arbol(_entidad, ["vida_actual", "vida", "casco", "salud", "hp"], 100.0)
	var vida_max := _leer_propiedad_en_arbol(_entidad, ["vida_maxima", "max_vida", "casco_maximo", "salud_maxima", "hp_max"], 100.0)
	var pct_vida := (vida / maxf(vida_max, 1.0)) * 100.0
	var muriendo_vacio := _esta_muriendo_en_vacio(vida)
	var casco_critico := (pct_vida <= umbral_casco_danado) and (pct_vida > 0.0)

	if not muriendo_vacio and _vida_anterior >= 0.0 and vida < _vida_anterior - 0.25:
		disparar_impacto()
	_vida_anterior = vida

	_alpha_flash = maxf(_alpha_flash - delta * 4.0, 0.0)

	var pulso_base := 0.0
	if muriendo_vacio:
		pulso_base = 0.45 + 0.35 * sin(_tiempo * 12.0)
	elif casco_critico:
		pulso_base = 0.25 + 0.22 * sin(_tiempo * 7.0)

	_material_dano.albedo_color.a = maxf(_alpha_flash, pulso_base)

	# El humo solo se emite cuando el casco está en 40% o menos
	if is_instance_valid(_particulas_humo):
		_particulas_humo.emitting = casco_critico


func disparar_impacto() -> void:
	_alpha_flash = 0.95
	if is_instance_valid(_nodo_malla) and _nodo_malla != _entidad:
		var pos_orig := _nodo_malla.position
		var tw := _nodo_malla.create_tween()
		tw.tween_property(_nodo_malla, "position", pos_orig + Vector3(randf_range(-0.25, 0.25), randf_range(-0.15, 0.15), randf_range(-0.25, 0.25)), 0.04)
		tw.tween_property(_nodo_malla, "position", pos_orig, 0.07)


func _esta_muriendo_en_vacio(vida: float) -> bool:
	if vida <= 0.0:
		return false
	var gestor: Node = _entidad.get_node_or_null("GestorOrbita")
	if gestor == null:
		for hijo in _entidad.get_children():
			if hijo.has_method("esta_en_espacio_abierto"):
				gestor = hijo
				break
	if gestor == null:
		return false
	var energia := _leer_propiedad_en_arbol(_entidad, ["energia_actual", "energia", "propulsor", "combustible"], 100.0)
	return gestor.esta_en_espacio_abierto() and energia <= 0.01


func _buscar_mallas_recursivo(nodo: Node, resultado: Array[MeshInstance3D]) -> void:
	if nodo is MeshInstance3D:
		resultado.append(nodo as MeshInstance3D)
	for hijo in nodo.get_children():
		_buscar_mallas_recursivo(hijo, resultado)


func _leer_propiedad_en_arbol(raiz: Node, nombres: Array[String], defecto: float) -> float:
	var nodos := [raiz] + raiz.get_children()
	for n in nodos:
		for nombre in nombres:
			if nombre in n:
				var val = n.get(nombre)
				if val is float or val is int:
					return float(val)
	return defecto
