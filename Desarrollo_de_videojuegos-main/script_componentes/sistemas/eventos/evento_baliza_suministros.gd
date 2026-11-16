class_name EventoBalizaSuministros
extends EventoEspacial

@export var radio_captura: float = 22.0
@export var tiempo_descarga: float = 4.5
@export var distancia_aparicion: float = 95.0 # Dentro del alcance visual y de radar

var _baliza: Node3D = null
var _progreso: float = 0.0


func _init() -> void:
	id_evento = "baliza_suministros"
	titulo = "📡 BALIZA DE SUMINISTROS (Sigue la flecha dorada)"
	duracion = 30.0


func iniciar(bus: BusEventos) -> void:
	var jugador := get_tree().get_first_node_in_group("jugador") as Node3D
	if not is_instance_valid(jugador):
		return

	super.iniciar(bus)
	_progreso = 0.0
	var angulo := randf_range(0.0, TAU)

	_baliza = _crear_nodo_visual_baliza()
	_baliza.add_to_group("puntos_interes")
	get_tree().current_scene.add_child(_baliza)
	_baliza.global_position = jugador.global_position + Vector3(cos(angulo), 0.0, sin(angulo)) * distancia_aparicion

	if bus:
		bus.evento_iniciado.emit(id_evento, titulo, _baliza, duracion)


func _crear_nodo_visual_baliza() -> Node3D:
	var raiz := Node3D.new()

	# Halo translúcido que marca el radio real de captura (sin OmniLight3D para mantener 60 FPS)
	var malla := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = radio_captura
	esfera.height = radio_captura * 2.0
	esfera.radial_segments = 24
	esfera.rings = 12
	malla.mesh = esfera
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.15, 0.22)
	malla.material_override = mat

	raiz.add_child(malla)
	return raiz


func actualizar(delta: float, bus: BusEventos) -> void:
	if not activo or not is_instance_valid(_baliza):
		return

	var jugador := get_tree().get_first_node_in_group("jugador") as Node3D
	if is_instance_valid(jugador):
		var dist := jugador.global_position.distance_to(_baliza.global_position)
		if dist <= radio_captura:
			_progreso += delta
			if bus:
				bus.evento_progreso.emit("📡 DESCARGANDO... %d%%" % int((_progreso / tiempo_descarga) * 100.0), _progreso / tiempo_descarga)
			if _progreso >= tiempo_descarga:
				if jugador.has_method("curar"):
					jugador.curar(35.0)
				if "energia_actual" in jugador and "energia_maxima" in jugador:
					jugador.energia_actual = minf(jugador.energia_maxima, jugador.energia_actual + 60.0)
				cerrar(true)
				return
		else:
			_progreso = maxf(0.0, _progreso - delta * 0.5)
			if bus:
				bus.evento_progreso.emit("Distancia: %dm (%ds)" % [int(dist), int(ceilf(tiempo_restante))], tiempo_restante / duracion)

	super.actualizar(delta, bus)


func cerrar(exito: bool) -> void:
	if is_instance_valid(_baliza):
		_baliza.queue_free()
	_baliza = null
	super.cerrar(exito)
