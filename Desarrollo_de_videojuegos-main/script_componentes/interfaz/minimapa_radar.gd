class_name MinimapaRadar
extends Control
## Radar circular táctico que muestra enemigos y planetas cercanos al jugador.

@export var rango_deteccion: float = 110.0
@export var rotar_con_camara: bool = true

@export_group("Colores")
@export var color_fondo: Color = Color(0.03, 0.08, 0.14, 0.72)
@export var color_borde: Color = Color(0.2, 0.9, 1.0, 0.65)
@export var color_jugador: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var color_enemigo: Color = Color(1.0, 0.25, 0.25, 0.95)
@export var color_planeta_defecto: Color = Color(0.2, 0.92, 1.0, 0.85)

var _jugador: Node3D = null
var _puntos_enemigos: PackedVector2Array = PackedVector2Array()
var _puntos_planetas: Array[Dictionary] = []
var _timer_actualizacion: float = 0.0


func _process(delta: float) -> void:
	_timer_actualizacion -= delta
	if _timer_actualizacion <= 0.0:
		_timer_actualizacion = 0.05
		_recopilar_contactos()
		queue_redraw()


func _recopilar_contactos() -> void:
	_puntos_enemigos.clear()
	_puntos_planetas.clear()

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		if _jugador == null:
			return

	var radio_ui := minf(size.x, size.y) * 0.5 - 6.0
	var origen := _jugador.global_position

	var angulo_cam := 0.0
	if rotar_con_camara:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var frente_cam := -cam.global_transform.basis.z
			angulo_cam = atan2(frente_cam.x, frente_cam.z)

	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := nodo as Node3D
		if not is_instance_valid(enemigo):
			continue
		var pos_radar := _proyectar_a_radar(enemigo.global_position - origen, radio_ui, angulo_cam)
		if pos_radar != Vector2.INF:
			_puntos_enemigos.append(pos_radar)

	for nodo in get_tree().get_nodes_in_group("planetas"):
		var planeta := nodo as Node3D
		if not is_instance_valid(planeta):
			continue
		var pos_radar := _proyectar_a_radar(planeta.global_position - origen, radio_ui, angulo_cam)
		if pos_radar != Vector2.INF:
			var col: Color = planeta.obtener_color_estado() if planeta.has_method("obtener_color_estado") else color_planeta_defecto
			_puntos_planetas.append({ "pos": pos_radar, "color": col })

	# 3. Objetivos de eventos (fijados al borde del radar si están fuera de rango)
	for nodo in get_tree().get_nodes_in_group("puntos_interes"):
		var objetivo := nodo as Node3D
		if not is_instance_valid(objetivo):
			continue
		var delta_3d := objetivo.global_position - origen
		var plano := Vector2(delta_3d.x, delta_3d.z)
		if plano.length() > rango_deteccion:
			plano = plano.normalized() * rango_deteccion
		if rotar_con_camara:
			plano = plano.rotated(angulo_cam - PI)
			plano.x = -plano.x
		var pos_radar := (plano / rango_deteccion) * radio_ui
		_puntos_planetas.append({ "pos": pos_radar, "color": Color(1.0, 0.85, 0.15, 1.0) })


func _proyectar_a_radar(delta_3d: Vector3, radio_ui: float, angulo_cam: float) -> Vector2:
	var plano := Vector2(delta_3d.x, delta_3d.z)
	if plano.length() > rango_deteccion:
		return Vector2.INF

	if rotar_con_camara:
		plano = plano.rotated(angulo_cam - PI)
		plano.x = -plano.x

	return (plano / rango_deteccion) * radio_ui


func _draw() -> void:
	var centro := size * 0.5
	var radio := minf(size.x, size.y) * 0.5 - 4.0

	draw_circle(centro, radio, color_fondo)
	draw_arc(centro, radio, 0.0, TAU, 48, color_borde, 2.0, true)
	draw_arc(centro, radio * 0.5, 0.0, TAU, 36, Color(color_borde.r, color_borde.g, color_borde.b, 0.25), 1.0, true)

	for item in _puntos_planetas:
		draw_circle(centro + item["pos"], 5.0, item["color"])

	for e in _puntos_enemigos:
		draw_circle(centro + e, 3.0, color_enemigo)

	draw_circle(centro, 3.5, color_jugador)
