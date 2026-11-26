extends Node3D

var aro := MeshInstance3D.new()
var linea := MeshInstance3D.new()
var material := StandardMaterial3D.new()
var tono: Color
var destello: Tween

func configurar(rol: int, color: Color) -> void:
	tono = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tono
	var circulo := TorusMesh.new()
	circulo.inner_radius = 2.65
	circulo.outer_radius = 2.78
	circulo.rings = 36
	circulo.ring_segments = 6
	aro.mesh = circulo
	aro.rotation.x = PI / 2
	_agregar(aro)
	linea.mesh = BoxMesh.new()
	linea.visible = false
	_agregar(linea)
	# Dos aletas, dos lanzas adelantadas o dos góndolas anchas.
	for lado in [-1.0, 1.0]:
		var pieza := MeshInstance3D.new()
		var caja := BoxMesh.new()
		match rol:
			0:
				caja.size = Vector3(0.32, 0.22, 1.55)
				pieza.position = Vector3(lado * 1.1, 0.16, 0.6)
				pieza.rotation.y = lado * 0.49
			1:
				caja.size = Vector3(0.28, 0.38, 2.8)
				pieza.position = Vector3(lado * 0.94, 0.16, -0.9)
			2:
				caja.size = Vector3(1.6, 0.26, 0.65)
				pieza.position = Vector3(lado * 1.85, 0.15, 0.35)
		pieza.mesh = caja
		_agregar(pieza)

func _agregar(pieza: MeshInstance3D) -> void:
	pieza.material_override = material
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pieza)

func entrada(restante: float) -> void:
	aro.scale = Vector3.ONE * (0.9 + 1.25 * restante)

func apuntar(distancia: float, mostrar_linea: bool) -> void:
	aro.visible = true
	linea.visible = mostrar_linea
	var largo := clampf(distancia, 2.0, 42.0)
	linea.scale = Vector3(0.085, 0.085, largo)
	linea.position.z = -largo * 0.5

func preparacion(progreso: float) -> void:
	aro.scale = Vector3.ONE * lerpf(1.35, 0.70, progreso)
	material.albedo_color = tono.lerp(Color.WHITE, progreso * 0.85)

func apagar() -> void:
	linea.visible = false
	aro.visible = false
	material.albedo_color = tono

func impacto() -> void:
	if destello:
		destello.kill()
	material.albedo_color = Color.WHITE
	destello = create_tween()
	destello.tween_property(material, "albedo_color", tono, 0.12)
