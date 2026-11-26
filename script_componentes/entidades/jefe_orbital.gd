class_name JefeOrbital
extends CharacterBody3D

signal destruido(posicion: Vector3)

@export var nombre_jefe: String = "ACORAZADO LEVIATÁN"
@export var vida_maxima: float = 450.0
@export var velocidad_movimiento: float = 15.0
@export var distancia_combate: float = 34.0
@export var escena_proyectil: PackedScene
@export var intervalo_ataque: float = 2.4
@export var dano_contacto: float = 20.0

var vida_actual: float
var _fase_2: bool = false
var _timer_ataque: float = 0.0
var _timer_flash: float = 0.0
var _jugador: Node3D = null
var _material_instancia: StandardMaterial3D = null
var _color_base: Color = Color(0.85, 0.22, 0.25)

# Barra HUD creada automáticamente al aparecer
var _capa_hud: CanvasLayer = null
var _barra_vida: ProgressBar = null


func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("jefe")
	vida_actual = vida_maxima
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
	_configurar_material()
	_crear_barra_hud()


func _configurar_material() -> void:
	var malla := find_child("*", true, false) as MeshInstance3D
	if malla:
		_material_instancia = StandardMaterial3D.new()
		_material_instancia.albedo_color = _color_base
		_material_instancia.emission_enabled = true
		_material_instancia.emission = _color_base
		_material_instancia.emission_energy_multiplier = 0.9
		malla.material_override = _material_instancia


func _crear_barra_hud() -> void:
	_capa_hud = CanvasLayer.new()
	_capa_hud.layer = 10
	add_child(_capa_hud)

	var contenedor := VBoxContainer.new()
	contenedor.set_anchors_preset(Control.PRESET_TOP_WIDE)
	contenedor.offset_top = 58.0
	contenedor.offset_left = 260.0
	contenedor.offset_right = -260.0
	_capa_hud.add_child(contenedor)

	var titulo := Label.new()
	titulo.text = "⚠ %s ⚠" % nombre_jefe
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.modulate = Color(1.0, 0.35, 0.35)
	contenedor.add_child(titulo)

	_barra_vida = ProgressBar.new()
	_barra_vida.max_value = vida_maxima
	_barra_vida.value = vida_actual
	_barra_vida.custom_minimum_size = Vector2(0, 22)
	_barra_vida.show_percentage = false
	contenedor.add_child(_barra_vida)


func _physics_process(delta: float) -> void:
	if _timer_flash > 0.0:
		_timer_flash -= delta
		if _timer_flash <= 0.0 and _material_instancia:
			_material_instancia.albedo_color = _color_base
			_material_instancia.emission = _color_base

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		return

	# Orbita alrededor del jugador manteniendo distancia de disparo
	var hacia_jugador := _jugador.global_position - global_position
	var dist := hacia_jugador.length()
	var dir := hacia_jugador.normalized()
	var lateral := dir.cross(Vector3.UP).normalized()

	var vel_radial := Vector3.ZERO
	if dist > distancia_combate + 6.0:
		vel_radial = dir * velocidad_movimiento
	elif dist < distancia_combate - 6.0:
		vel_radial = -dir * velocidad_movimiento * 0.8

	velocity = vel_radial + lateral * (velocidad_movimiento * 0.9)
	move_and_slide()
	look_at(_jugador.global_position, Vector3.UP)

	# Disparo en abanico
	_timer_ataque += delta
	var cd := intervalo_ataque * (0.65 if _fase_2 else 1.0)
	if _timer_ataque >= cd:
		_timer_ataque = 0.0
		_disparar_abanico()


func _disparar_abanico() -> void:
	if escena_proyectil == null or get_tree().current_scene == null:
		return
	var cantidad := 7 if _fase_2 else 5
	var apertura := deg_to_rad(42.0)
	var origen := global_position + (-global_transform.basis.z * 3.5)

	for i in range(cantidad):
		var t := (float(i) / float(cantidad - 1)) - 0.5
		var dir_disparo := (-global_transform.basis.z).rotated(Vector3.UP, t * apertura).normalized()
		var p := escena_proyectil.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_position = origen
		if p.has_method("configurar"):
			p.configurar(dir_disparo, 12.0)


func recibir_dano(cantidad: float) -> void:
	vida_actual = maxf(0.0, vida_actual - cantidad)
	if _barra_vida:
		_barra_vida.value = vida_actual

	# Destello blanco al recibir impacto
	if _material_instancia:
		_material_instancia.albedo_color = Color.WHITE
		_material_instancia.emission = Color.WHITE
		_timer_flash = 0.07

	# Activa Fase 2 al bajar del 50% de vida
	if not _fase_2 and vida_actual <= vida_maxima * 0.5:
		_fase_2 = true
		_color_base = Color(1.0, 0.1, 0.55)
		scale *= 1.15

	if vida_actual <= 0.0:
		destruido.emit(global_position)
		queue_free()
