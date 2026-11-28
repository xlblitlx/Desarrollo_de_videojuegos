class_name EnemigoArtillero
extends EnemigoBase
## Rol Inky/Clyde: Flanquea en pinza lateral y bloquea el planeta de refugio si al jugador le queda poca energía.

const BALA := preload("res://escenas/proyectil.tscn")

@export var distancia_flanqueo: float = 26.0
@export var umbral_bloqueo_energia: float = 40.0


func _init() -> void:
	vida_base = 24.0
	velocidad_base = 12.5
	dano_contacto = 10.0
	alcance_ataque = 38.0
	duracion_aviso = 0.85
	duracion_recuperacion = 1.65
	color_rol = Color("#be94ff")
	escala_rol = Vector3(1.25, 0.85, 0.95)
	indice_senal = 2


func _procesar_aproximacion(distancia: float, _delta: float) -> Vector3:
	var tiene_vision := distancia <= alcance_ataque and _sin_cobertura(objetivo.global_position)

	if tiene_vision and get_tree().get_node_count_in_group("ataque_anunciado") < 3:
		_iniciar_preparacion(_calcular_punto_intercepcion(0.28), true)
		return Vector3.ZERO

	# Si ya está en rango de tiro, orbita lateralmente disparando en pinza
	if tiene_vision:
		var rumbo := (objetivo.global_position - global_position).normalized()
		_orientar(rumbo)
		return rumbo.cross(Vector3.UP) * _lado * velocidad

	# Si el jugador tiene poca energía (<40%), bloquea la ruta hacia el planeta más cercano
	if _energia_jugador() < umbral_bloqueo_energia:
		var planeta_refugio := _buscar_planeta_cercano(objetivo.global_position)
		if is_instance_valid(planeta_refugio):
			var punto_bloqueo := objetivo.global_position.lerp(planeta_refugio.global_position, 0.45)
			return _mover_hacia_punto(punto_bloqueo, 1.1)

	# Flanqueo en pinza: abre un ángulo lateral mientras se acerca
	var dir_al_jugador := (objetivo.global_position - global_position).normalized()
	var lateral := dir_al_jugador.cross(Vector3.UP).normalized() * _lado
	var factor_apertura := clampf((distancia - 18.0) / 40.0, 0.0, 1.0)
	var punto_flanco := objetivo.global_position + lateral * (distancia_flanqueo * factor_apertura)
	return _mover_hacia_punto(punto_flanco, 1.0)


func _procesar_preparacion(_delta: float) -> Vector3:
	var prog := 1.0 - maxf(0.0, _restante) / maxf(duracion_aviso, 0.01)
	if is_instance_valid(_senal):
		_senal.preparacion(prog)

	if _restante <= 0.0:
		_disparar()
		_finalizar_ataque()
	return Vector3.ZERO


func _disparar() -> void:
	var escena := get_tree().current_scene as Node3D
	if escena == null or BALA == null:
		return
	var bala := BALA.instantiate() as Proyectil
	if bala == null:
		return
	bala.hostil = true
	bala.velocidad = 34.0
	bala.vida_maxima = 2.2
	bala.configurar(_direccion, dano_contacto)
	escena.add_child(bala)
	bala.global_position = global_position + _direccion * 1.6


func _buscar_planeta_cercano(pos: Vector3) -> Node3D:
	var mejor: Node3D = null
	var dist_min := INF
	for p in get_tree().get_nodes_in_group("planetas"):
		if p is Node3D:
			var d := pos.distance_to((p as Node3D).global_position)
			if d < dist_min:
				dist_min = d
				mejor = p as Node3D
	return mejor


func _energia_jugador() -> float:
	if not is_instance_valid(objetivo):
		return 100.0
	for nombre in ["energia_actual", "energia", "propulsor", "combustible"]:
		if nombre in objetivo:
			var val = objetivo.get(nombre)
			if val is float or val is int:
				return float(val)
	return 100.0
