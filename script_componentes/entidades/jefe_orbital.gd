class_name JefeOrbital
extends CharacterBody3D

signal destruido(posicion: Vector3)

const BALA_DEFECTO := preload("res://escenas/proyectil.tscn")

@export var nombre_jefe: String = "ACORAZADO LEVIATÁN"
@export var vida_maxima: float = 600.0
@export var velocidad_movimiento: float = 9.0
@export var distancia_combate: float = 22.0
@export var escala_modelo: float = 0.34
@export var radio_colision: float = 3.2
@export var escena_proyectil: PackedScene = BALA_DEFECTO
@export var intervalo_ataque: float = 2.4
@export var dano_proyectil: float = 12.0
@export var dano_contacto: float = 28.0

var vida_actual: float
var _fase_2: bool = false
var _destruido: bool = false
var _timer_ataque: float = 1.2
var _ultimo_ataque: int = -1
var _atacando: bool = false
var _embistiendo: bool = false
var _golpeo_en_embestida: bool = false
var _direccion_embestida: Vector3 = Vector3.ZERO
var _jugador: Node3D = null
var _impulso: Vector3 = Vector3.ZERO
var _sentido_orbita: float = 1.0

var _capa_hud: CanvasLayer = null
var _barra_vida: ProgressBar = null
var _etiqueta_fase: Label = null
var _propulsor_cono: MeshInstance3D = null
var _propulsor_particulas: GPUParticles3D = null


func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("jefe")

	collision_layer = 0
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(4, true)

	var modelo := get_node_or_null("UAV+Trident") as Node3D
	if modelo:
		modelo.scale = Vector3.ONE * escala_modelo

	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape is SphereShape3D:
		(col.shape as SphereShape3D).radius = radio_colision

	vida_actual = vida_maxima
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
	_crear_barra_hud()
	_crear_efecto_propulsion()


func _crear_barra_hud() -> void:
	_capa_hud = CanvasLayer.new()
	_capa_hud.layer = 10
	add_child(_capa_hud)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_top = 106.0
	panel.offset_left = 420.0
	panel.offset_right = -420.0
	panel.add_theme_stylebox_override("panel", _crear_caja(Color("#0c1a28eb"), Color("#395267"), 1, 10, 14, 8))
	_capa_hud.add_child(panel)

	var contenedor := VBoxContainer.new()
	contenedor.add_theme_constant_override("separation", 5)
	panel.add_child(contenedor)

	var fila_titulo := HBoxContainer.new()
	contenedor.add_child(fila_titulo)

	var titulo := Label.new()
	titulo.text = nombre_jefe
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 13)
	titulo.modulate = Color("#f0607e")
	fila_titulo.add_child(titulo)

	_etiqueta_fase = Label.new()
	_etiqueta_fase.text = "FASE I"
	_etiqueta_fase.add_theme_font_size_override("font_size", 12)
	_etiqueta_fase.modulate = Color("#cbd8e0")
	fila_titulo.add_child(_etiqueta_fase)

	_barra_vida = ProgressBar.new()
	_barra_vida.max_value = vida_maxima
	_barra_vida.value = vida_actual
	_barra_vida.custom_minimum_size = Vector2(0.0, 9.0)
	_barra_vida.show_percentage = false
	_barra_vida.add_theme_stylebox_override("background", _crear_caja(Color("#263948"), Color.TRANSPARENT, 0, 4))
	_barra_vida.add_theme_stylebox_override("fill", _crear_caja(Color("#f0607e"), Color.TRANSPARENT, 0, 4))
	contenedor.add_child(_barra_vida)


func _crear_caja(fondo: Color, borde: Color, grosor: int, radio: int, mh: int = 0, mv: int = 0) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(grosor)
	caja.set_corner_radius_all(radio)
	if mh > 0 or mv > 0:
		caja.content_margin_left = mh
		caja.content_margin_right = mh
		caja.content_margin_top = mv
		caja.content_margin_bottom = mv
	return caja


func _crear_efecto_propulsion() -> void:
	var contenedor_motor := Node3D.new()
	contenedor_motor.position = Vector3(0.0, 0.0, 2.4)
	add_child(contenedor_motor)

	# 1. Llama volumétrica del propulsor
	_propulsor_cono = MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.05
	cono.bottom_radius = 0.75
	cono.height = 3.6
	_propulsor_cono.mesh = cono
	_propulsor_cono.rotation_degrees.x = 90.0
	_propulsor_cono.position.z = 1.8

	var mat_llama := StandardMaterial3D.new()
	mat_llama.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_llama.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_llama.albedo_color = Color(1.0, 0.45, 0.1, 0.85)
	mat_llama.emission_enabled = true
	mat_llama.emission = Color(1.0, 0.35, 0.05)
	mat_llama.emission_energy_multiplier = 3.5
	_propulsor_cono.material_override = mat_llama
	_propulsor_cono.visible = false
	contenedor_motor.add_child(_propulsor_cono)

	# 2. Estela de partículas en espacio mundial
	_propulsor_particulas = GPUParticles3D.new()
	_propulsor_particulas.amount = 48
	_propulsor_particulas.lifetime = 0.45
	_propulsor_particulas.local_coords = false
	_propulsor_particulas.emitting = false

	var mat_proc := ParticleProcessMaterial.new()
	mat_proc.direction = Vector3(0.0, 0.0, 1.0)
	mat_proc.spread = 18.0
	mat_proc.initial_velocity_min = 10.0
	mat_proc.initial_velocity_max = 18.0
	mat_proc.gravity = Vector3.ZERO
	mat_proc.scale_min = 0.35
	mat_proc.scale_max = 0.75
	_propulsor_particulas.process_material = mat_proc

	var esfera := SphereMesh.new()
	esfera.radius = 0.25
	esfera.height = 0.5
	var mat_part := StandardMaterial3D.new()
	mat_part.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_part.albedo_color = Color(1.0, 0.65, 0.15)
	mat_part.emission_enabled = true
	mat_part.emission = Color(1.0, 0.4, 0.05)
	mat_part.emission_energy_multiplier = 3.0
	esfera.material = mat_part
	_propulsor_particulas.draw_pass_1 = esfera
	contenedor_motor.add_child(_propulsor_particulas)


func _activar_propulsion(activo: bool) -> void:
	if _propulsor_particulas:
		_propulsor_particulas.emitting = activo
	if _propulsor_cono:
		if activo:
			_propulsor_cono.visible = true
			_propulsor_cono.scale = Vector3(0.4, 0.4, 0.4)
			var tw := create_tween()
			tw.tween_property(_propulsor_cono, "scale", Vector3(1.3, 1.5, 1.3) if _fase_2 else Vector3.ONE, 0.14)
		else:
			var tw := create_tween()
			tw.tween_property(_propulsor_cono, "scale", Vector3(0.1, 0.1, 0.1), 0.15)
			tw.tween_callback(_ocultar_propulsor)


func _ocultar_propulsor() -> void:
	if is_instance_valid(_propulsor_cono):
		_propulsor_cono.visible = false


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		return

	if _embistiendo:
		var vel_carga := 60.0 if _fase_2 else 46.0
		velocity = _direccion_embestida * vel_carga
		move_and_slide()
		_verificar_impacto_fisico()
		return

	var hacia_jugador := _jugador.global_position - global_position
	var dist := hacia_jugador.length()
	var dir := hacia_jugador.normalized() if dist > 0.01 else -global_transform.basis.z
	var lateral := dir.cross(Vector3.UP).normalized() * _sentido_orbita

	var vel_radial := Vector3.ZERO
	if dist > distancia_combate + 4.0:
		vel_radial = dir * velocidad_movimiento
	elif dist < distancia_combate - 4.0:
		vel_radial = -dir * velocidad_movimiento * 0.7

	var factor_mov := 0.2 if _atacando else (1.15 if _fase_2 else 1.0)
	var vel_objetivo := (vel_radial + lateral * (velocidad_movimiento * 0.65)) * factor_mov + _impulso
	velocity = velocity.lerp(vel_objetivo, 4.5 * delta)
	_impulso = _impulso.move_toward(Vector3.ZERO, 24.0 * delta)
	move_and_slide()

	if dist > 0.5:
		var objetivo_basis := Basis.looking_at(dir, Vector3.UP)
		global_transform.basis = global_transform.basis.orthonormalized().slerp(objetivo_basis, 6.5 * delta)

	if not _atacando:
		_timer_ataque -= delta
		if _timer_ataque <= 0.0:
			_ejecutar_ataque_aleatorio()


func _elegir_patron() -> int:
	var candidatos: Array[int] = [0, 1, 2, 3]
	candidatos.erase(_ultimo_ataque)

	if _ultimo_ataque != 3 and is_instance_valid(_jugador):
		var dist := global_position.distance_to(_jugador.global_position)
		if dist < 17.0 or _fase_2:
			candidatos.append(3)

	return candidatos.pick_random()


func _ejecutar_ataque_aleatorio() -> void:
	_atacando = true
	var patron := _elegir_patron()
	_ultimo_ataque = patron

	match patron:
		0:
			await _ataque_abanico()
		1:
			await _ataque_rafaga_dirigida()
		2:
			await _ataque_anillo_orbital()
		3:
			await _ataque_embestida_fisica()

	if not is_instance_valid(self) or _destruido:
		return

	_atacando = false
	if randf() < 0.35:
		_sentido_orbita *= -1.0
	_timer_ataque = intervalo_ataque * (0.72 if _fase_2 else 1.0)


# --- Patrón 1: Abanico de plasma ------------------------------------------

func _ataque_abanico() -> void:
	var oleadas := 2 if _fase_2 else 1
	var vel_bala := 30.0 if _fase_2 else 26.0
	for r in range(oleadas):
		if _destruido or not is_instance_valid(_jugador):
			return
		var cantidad := 7 if _fase_2 else 5
		var apertura := deg_to_rad(44.0 if _fase_2 else 34.0)
		var frente := _direccion_predictiva(vel_bala, 0.85)
		var origen := global_position + frente * 2.2

		for i in range(cantidad):
			var t := (float(i) / float(cantidad - 1)) - 0.5
			var dir_disparo := frente.rotated(Vector3.UP, t * apertura).normalized()
			_instanciar_bala(origen, dir_disparo, vel_bala, dano_proyectil)

		if oleadas > 1 and r == 0:
			await get_tree().create_timer(0.45).timeout


# --- Patrón 2: Ráfaga rápida con predicción real ---------------------------

func _ataque_rafaga_dirigida() -> void:
	await get_tree().create_timer(0.3).timeout
	var disparos := 6 if _fase_2 else 4
	var vel_bala := 36.0 if _fase_2 else 31.0

	for i in range(disparos):
		if _destruido or not is_instance_valid(_jugador):
			return
		var dir_disparo := _direccion_predictiva(vel_bala, 0.95)
		var origen := global_position + dir_disparo * 2.2
		_instanciar_bala(origen, dir_disparo, vel_bala, dano_proyectil * 0.85)
		await get_tree().create_timer(0.16).timeout


# --- Patrón 3: Anillo radial 360° ------------------------------------------

func _ataque_anillo_orbital() -> void:
	await get_tree().create_timer(0.35).timeout
	if _destruido:
		return

	var cantidad := 16 if _fase_2 else 12
	var desfase := randf() * TAU
	for i in range(cantidad):
		var angulo := desfase + (TAU * float(i) / float(cantidad))
		var dir_disparo := Vector3(cos(angulo), 0.0, sin(angulo)).normalized()
		var origen := global_position + dir_disparo * 2.2
		_instanciar_bala(origen, dir_disparo, 24.0 if _fase_2 else 20.0, dano_proyectil * 0.9)


# --- Patrón 4: Embestida física con propulsión -----------------------------

func _ataque_embestida_fisica() -> void:
	if not is_instance_valid(_jugador):
		return

	_destellar_color(Color(1.0, 0.15, 0.15), 2.8, 0.65)
	var objetivo := _jugador.global_position
	if _jugador is CharacterBody3D:
		objetivo += (_jugador as CharacterBody3D).velocity * 0.35
	_direccion_embestida = global_position.direction_to(objetivo)
	if _direccion_embestida.length_squared() < 0.01:
		_direccion_embestida = -global_transform.basis.z.normalized()

	look_at(global_position + _direccion_embestida, Vector3.UP)
	await get_tree().create_timer(0.65).timeout

	if _destruido or not is_instance_valid(self):
		return

	_golpeo_en_embestida = false
	_embistiendo = true
	_activar_propulsion(true)
	await get_tree().create_timer(0.72).timeout
	_embistiendo = false
	_activar_propulsion(false)

	if _destruido or not is_instance_valid(self):
		return

	if _fase_2:
		for i in range(8):
			var ang := TAU * float(i) / 8.0
			var d := Vector3(cos(ang), 0.0, sin(ang)).normalized()
			_instanciar_bala(global_position + d * 2.2, d, 22.0, dano_proyectil * 0.8)

	velocity = Vector3.ZERO
	await get_tree().create_timer(0.55).timeout


func _verificar_impacto_fisico() -> void:
	if _golpeo_en_embestida or not is_instance_valid(_jugador):
		return

	var golpeo := global_position.distance_to(_jugador.global_position) <= radio_colision + 1.6
	if not golpeo:
		for i in get_slide_collision_count():
			if get_slide_collision(i).get_collider() == _jugador:
				golpeo = true
				break

	if golpeo:
		_golpeo_en_embestida = true
		if _jugador.has_method("recibir_dano"):
			_jugador.recibir_dano(dano_contacto)
		if _jugador.has_method("aplicar_impulso"):
			_jugador.aplicar_impulso(_direccion_embestida * 26.0)


func _direccion_predictiva(vel_bala: float, precision: float) -> Vector3:
	if not is_instance_valid(_jugador):
		return -global_transform.basis.z.normalized()
	var dist := global_position.distance_to(_jugador.global_position)
	var tiempo_vuelo := dist / maxf(vel_bala, 1.0)
	var objetivo := _jugador.global_position
	if _jugador is CharacterBody3D:
		objetivo += (_jugador as CharacterBody3D).velocity * (tiempo_vuelo * precision)
	return global_position.direction_to(objetivo)


func _instanciar_bala(origen: Vector3, direccion: Vector3, vel: float, dano: float) -> void:
	if escena_proyectil == null or get_tree().current_scene == null:
		return

	var p := escena_proyectil.instantiate() as Node3D
	if p == null:
		return

	if p is Proyectil:
		p.hostil = true
		p.velocidad = vel
		p.vida_maxima = 3.2

	if p is CollisionObject3D:
		var col := p as CollisionObject3D
		col.set_collision_mask_value(1, true)
		col.set_collision_mask_value(2, false)

	get_tree().current_scene.add_child(p)
	p.global_position = origen
	p.scale = Vector3.ONE * 2.4

	if p.has_method("configurar"):
		p.configurar(direccion, dano)


func aplicar_impulso(impulso: Vector3) -> void:
	if not _embistiendo:
		_impulso = (_impulso + impulso * 0.25).limit_length(14.0)


func recibir_dano(cantidad: float) -> void:
	if _destruido or cantidad <= 0.0:
		return

	vida_actual = maxf(0.0, vida_actual - cantidad)
	if _barra_vida:
		_barra_vida.value = vida_actual

	_destellar_color(Color(1.0, 0.95, 0.9), 2.0, 0.08)

	if not _fase_2 and vida_actual <= vida_maxima * 0.5:
		_activar_fase_2()

	if vida_actual <= 0.0:
		_destruido = true
		destruido.emit(global_position)
		if EventosJuego and EventosJuego.has_signal("enemigo_eliminado"):
			EventosJuego.enemigo_eliminado.emit(global_position)
		queue_free()


func _activar_fase_2() -> void:
	_fase_2 = true
	_sentido_orbita *= -1.0
	if _etiqueta_fase:
		_etiqueta_fase.text = "FASE II · SOBRECARGA"
		_etiqueta_fase.modulate = Color("#ffae52")
	if _barra_vida:
		_barra_vida.add_theme_stylebox_override("fill", _crear_caja(Color("#ffae52"), Color.TRANSPARENT, 0, 4))


func _destellar_color(color: Color, energia: float, duracion: float) -> void:
	for nodo in find_children("*", "MeshInstance3D", true, false):
		var mi := nodo as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			var mat := mi.get_active_material(s)
			if not (mat is BaseMaterial3D):
				continue
			var flash := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			flash.emission_enabled = true
			flash.emission = color
			flash.emission_energy_multiplier = energia
			mi.set_surface_override_material(s, flash)

			var tw := create_tween()
			tw.tween_property(flash, "emission_energy_multiplier", 0.0, duracion)
			tw.tween_callback(_restaurar_material.bind(mi, s, mat))


func _restaurar_material(mi: MeshInstance3D, superficie: int, original: Material) -> void:
	if is_instance_valid(mi):
		mi.set_surface_override_material(superficie, original)
