class_name MinimapaRadar
extends Control

@export var rango_deteccion: float = 110.0 # Metros en el mundo 3D que abarca el radio del radar
@export var rotar_con_camara: bool = true  # True = "arriba" en el radar es hacia donde mira la cámara

@export_group("Colores")
@export var color_fondo: Color = Color(0.03, 0.08, 0.14, 0.72)
@export var color_borde: Color = Color(0.2, 0.9, 1.0, 0.65)
@export var color_jugador: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var color_enemigo: Color = Color(1.0, 0.25, 0.25, 0.95)
@export var color_planeta: Color = Color(0.2, 0.92, 1.0, 0.85)

var _jugador: Node3D = null
var _puntos_enemigos: PackedVector2Array = PackedVector2Array()
var _puntos_planetas: PackedVector2Array = PackedVector2Array()
var _timer_actualizacion: float = 0.0


func _process(delta: float) -> void:
	# Actualiza posiciones a 20 Hz (cada 0.05 s): visualmente fluido y costo casi cero en CPU
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

	# Ángulo de referencia según la cámara o el mundo
	var angulo_cam := 0.0
	if rotar_con_camara:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var frente_cam := -cam.global_transform.basis.z
			angulo_cam = atan2(frente_cam.x, frente_cam.z)

	# 1. Enemigos cercanos (en grupo "enemigos")
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := nodo as Node3D
		if not is_instance_valid(enemigo):
			continue
		var pos_radar := _proyectar_a_radar(enemigo.global_position - origen, radio_ui, angulo_cam)
		if pos_radar != Vector2.INF:
			_puntos_enemigos.append(pos_radar)

	# 2. Planetas cercanos (en grupo "planetas")
	for nodo in get_tree().get_nodes_in_group("planetas"):
		var planeta := nodo as Node3D
		if not is_instance_valid(planeta):
			continue
		var pos_radar := _proyectar_a_radar(planeta.global_position - origen, radio_ui, angulo_cam)
		if pos_radar != Vector2.INF:
			_puntos_planetas.append(pos_radar)


func _proyectar_a_radar(delta_3d: Vector3, radio_ui: float, angulo_cam: float) -> Vector2:
	# Usa plano XZ (ajusta a Vector2(delta_3d.x, -delta_3d.y) si tu juego es en plano XY)
	var plano := Vector2(delta_3d.x, delta_3d.z)
	var dist := plano.length()
	if dist > rango_deteccion:
		return Vector2.INF

	if rotar_con_camara:
		# Orienta para que el frente de la cámara quede arriba (-Y en UI)
		plano = plano.rotated(angulo_cam - PI)
		plano.x = -plano.x

	return (plano / rango_deteccion) * radio_ui


func _draw() -> void:
	var centro := size * 0.5
	var radio := minf(size.x, size.y) * 0.5 - 4.0

	# Fondo circular y anillos de radar
	draw_circle(centro, radio, color_fondo)
	draw_arc(centro, radio, 0.0, TAU, 48, color_borde, 2.0, true)
	draw_arc(centro, radio * 0.5, 0.0, TAU, 36, Color(color_borde.r, color_borde.g, color_borde.b, 0.25), 1.0, true)

	# Planetas dentro del rango (círculos cian)
	for p in _puntos_planetas:
		draw_circle(centro + p, 5.0, color_planeta)

	# Enemigos dentro del rango (puntos rojos)
	for e in _puntos_enemigos:
		draw_circle(centro + e, 3.0, color_enemigo)

	# Nave del jugador en el centro
	draw_circle(centro, 3.5, color_jugador)
