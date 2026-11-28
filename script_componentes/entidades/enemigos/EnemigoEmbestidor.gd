class_name EnemigoEmbestidor
extends EnemigoBase
## Rol Pinky: Predice la trayectoria del jugador para cortarle el paso y embestirlo.

@export var tiempo_prediccion: float = 1.15


func _init() -> void:
	vida_base = 36.0
	velocidad_base = 13.0
	dano_contacto = 16.0
	alcance_ataque = 28.0
	duracion_aviso = 0.72
	duracion_recuperacion = 1.35
	color_rol = Color("#ffae52")
	escala_rol = Vector3(1.10, 1.15, 1.35)
	indice_senal = 1


func _procesar_aproximacion(distancia: float, _delta: float) -> Vector3:
	# Se adelanta al punto futuro del jugador para cerrarle la salida
	var punto_corte := _calcular_punto_intercepcion(tiempo_prediccion)

	if distancia <= alcance_ataque and _sin_cobertura(objetivo.global_position) and get_tree().get_node_count_in_group("ataque_anunciado") < 3:
		_iniciar_preparacion(_calcular_punto_intercepcion(0.45), true)
		return Vector3.ZERO

	return _mover_hacia_punto(punto_corte, 1.05)


func _procesar_preparacion(_delta: float) -> Vector3:
	var prog := 1.0 - maxf(0.0, _restante) / maxf(duracion_aviso, 0.01)
	if is_instance_valid(_senal):
		_senal.preparacion(prog)

	if prog < 0.70:
		var punto_embestida := _calcular_punto_intercepcion(0.45)
		_direccion = global_position.direction_to(punto_embestida)
		_orientar(_direccion)
		if is_instance_valid(_senal):
			_senal.apuntar(global_position.distance_to(punto_embestida), true)

	if _restante <= 0.0:
		estado = Estado.ATACAR
		_restante = 0.75
	return Vector3.ZERO


func _procesar_ataque(_delta: float) -> Vector3:
	return _direccion * 54.0


func _post_movimiento(anterior: Vector3) -> void:
	if estado == Estado.ATACAR:
		_evaluar_impacto_cuerpo_a_cuerpo(anterior)


func aplicar_impulso(impulso: Vector3) -> void:
	# Imparable mientras embiste
	if estado == Estado.ATACAR:
		return
	super.aplicar_impulso(impulso)
