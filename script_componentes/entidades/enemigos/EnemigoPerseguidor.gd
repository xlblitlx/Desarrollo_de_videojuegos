class_name EnemigoPerseguidor
extends EnemigoBase
## Rol Blinky: Caza directa a la posición actual del jugador.


func _init() -> void:
	vida_base = 18.0
	velocidad_base = 15.5
	dano_contacto = 10.0
	alcance_ataque = 5.5
	duracion_aviso = 0.25
	duracion_recuperacion = 0.85
	color_rol = Color("#f0607e")
	escala_rol = Vector3(0.95, 0.95, 1.0)
	indice_senal = 0


func _procesar_aproximacion(distancia: float, _delta: float) -> Vector3:
	if distancia <= alcance_ataque and _sin_cobertura(objetivo.global_position) and get_tree().get_node_count_in_group("ataque_anunciado") < 3:
		_iniciar_preparacion(objetivo.global_position, false)
		return Vector3.ZERO

	# Persigue directamente la posición actual del jugador (sin rodeos)
	return _mover_hacia_punto(objetivo.global_position, 1.0)


func _procesar_preparacion(_delta: float) -> Vector3:
	var prog := 1.0 - maxf(0.0, _restante) / maxf(duracion_aviso, 0.01)
	if is_instance_valid(_senal):
		_senal.preparacion(prog)

	_direccion = global_position.direction_to(objetivo.global_position)
	_orientar(_direccion)

	if _restante <= 0.0:
		estado = Estado.ATACAR
		_restante = 0.45
	return _direccion * velocidad


func _procesar_ataque(delta: float) -> Vector3:
	var rumbo_actual := global_position.direction_to(objetivo.global_position)
	_direccion = _direccion.lerp(rumbo_actual, 8.5 * delta).normalized()
	_orientar(_direccion)
	return _direccion * (velocidad * 1.65)


func _post_movimiento(anterior: Vector3) -> void:
	if estado == Estado.ATACAR:
		_evaluar_impacto_cuerpo_a_cuerpo(anterior)
