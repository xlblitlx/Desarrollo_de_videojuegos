class_name CampoAsteroides
extends Node3D

@export var asteroide_scene: PackedScene
@export var capsula_recurso_scene: PackedScene
@export var cantidad_asteroides: int = 16
@export var radio_dispersion: float = 85.0
@export var altura_dispersion: float = 48.0 # Volumen 3D real arriba y abajo
@export var probabilidad_reparacion_comun: float = 0.30

@export_group("Dinámica y Cosecha Estática")
@export var velocidad_deriva_orbital: float = 0.06 # Radianes/seg alrededor del centro del campo
@export var margen_cosecha_estatica: float = 11.0 # Distancia desde la superficie de rocas energéticas
@export var recarga_estatica_por_seg: float = 9.0

@export_group("Colisiones Ambientales")
@export var dano_impacto_nave: float = 18.0
@export var cooldown_golpe_nave: float = 0.8
@export var fuerza_rebote: float = 28.0
@export var dano_choque_enemigo: float = 4.0

var asteroides_instanciados: Array[Node3D] = []
var radios_asteroides: Array[float] = []
var velocidades_rotacion: Array[Vector3] = []

var _jugador: CharacterBody3D = null
var _timer_golpe_nave: float = 0.0
var _sentido_deriva: float = 1.0


func _ready() -> void:
	_sentido_deriva = 1.0 if randf() >= 0.5 else -1.0
	_generar_campo()


func _process(delta: float) -> void:
	var paso_orbital := velocidad_deriva_orbital * _sentido_deriva * delta
	for i in range(asteroides_instanciados.size()):
		var asteroide := asteroides_instanciados[i]
		if is_instance_valid(asteroide):
			asteroide.rotate_x(velocidades_rotacion[i].x * delta)
			asteroide.rotate_y(velocidades_rotacion[i].y * delta)
			# Deriva lenta del cinturón alrededor del centro local del campo
			if absf(paso_orbital) > 0.00001:
				asteroide.position = asteroide.position.rotated(Vector3.UP, paso_orbital)


func _physics_process(delta: float) -> void:
	if _timer_golpe_nave > 0.0:
		_timer_golpe_nave -= delta

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		if _jugador == null:
			return

	var radio_activo_sq := pow(radio_dispersion + 55.0, 2)
	if global_position.distance_squared_to(_jugador.global_position) > radio_activo_sq:
		return

	_procesar_interaccion_jugador(delta)
	_verificar_colision_enemigos(radio_activo_sq)
	_verificar_impactos_proyectiles(radio_activo_sq)


func _procesar_interaccion_jugador(delta: float) -> void:
	var cosecho_en_frame := false

	for i in range(asteroides_instanciados.size()):
		var asteroide := asteroides_instanciados[i]
		if not is_instance_valid(asteroide):
			continue

		var offset := _jugador.global_position - asteroide.global_position
		var dist_sq := offset.length_squared()
		var radio_choque := radios_asteroides[i] + 1.2

		# 1. Impacto físico con rebote
		if dist_sq <= radio_choque * radio_choque:
			if _timer_golpe_nave <= 0.0:
				var normal := offset.normalized() if dist_sq > 0.0001 else Vector3.UP
				_jugador.global_position = asteroide.global_position + normal * (radio_choque + 0.3)
				_jugador.velocity = normal * fuerza_rebote
				if _jugador.has_method("recibir_dano"):
					_jugador.recibir_dano(dano_impacto_nave)
				_timer_golpe_nave = cooldown_golpe_nave
			break

		# 2. Cosecha estática por proximidad en asteroides energéticos (cian)
		if not cosecho_en_frame and asteroide is Asteroide and asteroide.tipo == Asteroide.TipoAsteroide.ENERGETICO:
			var radio_cosecha := radios_asteroides[i] + margen_cosecha_estatica
			if dist_sq <= radio_cosecha * radio_cosecha:
				if "energia_actual" in _jugador and "energia_maxima" in _jugador:
					if _jugador.energia_actual < _jugador.energia_maxima:
						_jugador.energia_actual = minf(_jugador.energia_maxima, _jugador.energia_actual + recarga_estatica_por_seg * delta)
						asteroide.pulsar_cosecha()
						cosecho_en_frame = true


func _verificar_colision_enemigos(radio_activo_sq: float) -> void:
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := nodo as CharacterBody3D
		if not is_instance_valid(enemigo):
			continue
		if global_position.distance_squared_to(enemigo.global_position) > radio_activo_sq:
			continue

		for i in range(asteroides_instanciados.size()):
			var asteroide := asteroides_instanciados[i]
			if not is_instance_valid(asteroide):
				continue

			var offset := enemigo.global_position - asteroide.global_position
			var radio_choque := radios_asteroides[i] + 1.0
			if offset.length_squared() <= radio_choque * radio_choque:
				var normal := offset.normalized() if offset.length() > 0.01 else Vector3.UP
				enemigo.global_position = asteroide.global_position + normal * (radio_choque + 0.3)
				enemigo.velocity = normal * (fuerza_rebote * 0.75)
				if enemigo.has_method("recibir_dano"):
					enemigo.recibir_dano(dano_choque_enemigo)
				break


func _verificar_impactos_proyectiles(radio_activo_sq: float) -> void:
	var raiz := get_tree().current_scene
	if raiz == null:
		return

	for nodo in raiz.get_children():
		if not (nodo is Proyectil) or nodo.is_queued_for_deletion():
			continue

		var proyectil := nodo as Proyectil
		if global_position.distance_squared_to(proyectil.global_position) > radio_activo_sq:
			continue

		for i in range(asteroides_instanciados.size() - 1, -1, -1):
			var asteroide := asteroides_instanciados[i]
			if not is_instance_valid(asteroide):
				_eliminar_registro(i)
				continue

			var radio_impacto := radios_asteroides[i] + 0.85
			if proyectil.global_position.distance_squared_to(asteroide.global_position) <= radio_impacto * radio_impacto:
				var pos_roca := asteroide.global_position
				var tipo_roca: int = asteroide.tipo if "tipo" in asteroide else 0
				var roto := false

				if asteroide.has_method("recibir_dano"):
					roto = asteroide.recibir_dano(proyectil.dano)
				else:
					asteroide.queue_free()
					roto = true

				proyectil.queue_free()

				if roto:
					_eliminar_registro(i)
					_soltar_recompensa_segun_tipo(pos_roca, tipo_roca)
				break


func _eliminar_registro(indice: int) -> void:
	asteroides_instanciados.remove_at(indice)
	radios_asteroides.remove_at(indice)
	velocidades_rotacion.remove_at(indice)


func _soltar_recompensa_segun_tipo(posicion: Vector3, tipo_roca: int) -> void:
	if capsula_recurso_scene == null or get_tree().current_scene == null:
		return

	if tipo_roca == Asteroide.TipoAsteroide.ENERGETICO:
		var celda := capsula_recurso_scene.instantiate() as CapsulaRecurso
		if celda:
			get_tree().current_scene.add_child(celda)
			celda.global_position = posicion
			celda.configurar_tipo(CapsulaRecurso.TipoRecurso.ENERGIA_PROPULSOR, 30.0)
	elif tipo_roca == Asteroide.TipoAsteroide.COMUN and randf() <= probabilidad_reparacion_comun:
		var reparacion := capsula_recurso_scene.instantiate() as CapsulaRecurso
		if reparacion:
			get_tree().current_scene.add_child(reparacion)
			reparacion.global_position = posicion
			reparacion.configurar_tipo(CapsulaRecurso.TipoRecurso.REPARACION_CASCO, 15.0)


func _generar_campo() -> void:
	if not asteroide_scene:
		return

	for i in range(cantidad_asteroides):
		var inst := asteroide_scene.instantiate() as Node3D
		add_child(inst)

		var angulo := randf_range(0.0, TAU)
		var dist := randf_range(8.0, radio_dispersion)
		var offset_y := randf_range(-altura_dispersion, altura_dispersion)

		inst.position = Vector3(cos(angulo) * dist, offset_y, sin(angulo) * dist)

		var escala_random := randf_range(6.0, 14.0)
		inst.scale = Vector3.ONE * escala_random
		inst.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))

		if inst.has_method("configurar"):
			inst.configurar(escala_random)

		asteroides_instanciados.append(inst)
		radios_asteroides.append(escala_random * 0.5)
		velocidades_rotacion.append(Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3)
		))
