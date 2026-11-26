class_name EfectoCombate
extends Node3D
## Un destello sin física, luces o procesamiento permanente.
static func crear(padre: Node, posicion: Vector3, color: Color, tamano: float = 1.0) -> void:
	if not is_instance_valid(padre):
		return
	var efecto := EfectoCombate.new()
	padre.add_child(efecto)
	efecto.global_position = posicion
	var malla := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.5
	esfera.height = 1.0
	esfera.radial_segments = 12
	esfera.rings = 6
	malla.mesh = esfera
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	malla.material_override = mat
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	efecto.add_child(malla)
	var tw := efecto.create_tween().set_parallel(true)
	tw.tween_property(malla, "scale", Vector3.ONE * tamano * 5.0, 0.3).from(Vector3.ONE * tamano * 0.3)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(efecto.queue_free)
