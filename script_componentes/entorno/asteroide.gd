class_name Asteroide
extends Node3D
## Asteroide individual con variantes tácticas y respuesta visual al daño o cosecha.

enum TipoAsteroide { COMUN, VOLATIL, ENERGETICO, MINERAL }

signal destruido(posicion: Vector3, tipo: TipoAsteroide)

@export var vida_base: float = 15.0
@export var radio_explosion_volatil: float = 26.0
@export var dano_explosion_volatil: float = 35.0
@export var escena_orbe: PackedScene = preload("res://escenas/orbe.tscn")
@export var velocidad_orbita: float = 0.25
@export var radio_orbita_local: float = 4.5

var _orbita_inicializada: bool = false
var _centro_orbita: Vector3 = Vector3.ZERO
var _angulo_orbita: float = 0.0
var _eje_rotacion: Vector3 = Vector3.UP
var _vel_rotacion: float = 0.25
var tipo: TipoAsteroide = TipoAsteroide.COMUN
var vida_actual: float = 15.0
var _material_instancia: ShaderMaterial
var _color_base: Color = Color(0.55, 0.55, 0.58, 1.0)
var _timer_flash: float = 0.0
var _destruido := false


func _ready() -> void:
	add_to_group("asteroides")
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Cobertura"
	cuerpo.collision_layer = 8
	cuerpo.collision_mask = 0
	var forma := CollisionShape3D.new()
	forma.shape = SphereShape3D.new()
	(forma.shape as SphereShape3D).radius = 0.5
	cuerpo.add_child(forma)
	add_child(cuerpo)


func configurar(escala: float) -> void:
	var factor_tamano := clampf(escala / 8.0, 0.7, 2.0)

	var dado := randf()
	if dado < 0.40:
		tipo = TipoAsteroide.COMUN
		vida_actual = vida_base * factor_tamano
		_color_base = Color(0.55, 0.55, 0.58, 1.0)
		add_to_group("asteroides_comunes")
	elif dado < 0.65:
		tipo = TipoAsteroide.VOLATIL
		vida_actual = vida_base * 0.75 * factor_tamano
		_color_base = Color(0.95, 0.32, 0.18, 1.0)
		add_to_group("asteroides_objetivo")
	elif dado < 0.90:
		tipo = TipoAsteroide.ENERGETICO
		vida_actual = vida_base * factor_tamano
		_color_base = Color(0.18, 0.88, 1.0, 1.0)
		add_to_group("asteroides_comunes")
	else:
		tipo = TipoAsteroide.MINERAL
		vida_actual = vida_base * 1.45 * factor_tamano
		_color_base = Color(1.0, 0.82, 0.22, 1.0)
		add_to_group("asteroides_objetivo")

	_aplicar_color(_color_base)


func _process(delta: float) -> void:
	if _timer_flash > 0.0:
		_timer_flash -= delta
		if _timer_flash <= 0.0:
			_aplicar_color(_color_base)

	if not _orbita_inicializada:
		_orbita_inicializada = true
		_angulo_orbita = randf() * TAU
		var dir_radio := Vector3(cos(_angulo_orbita), randf_range(-0.15, 0.15), sin(_angulo_orbita)).normalized()
		_centro_orbita = global_position - dir_radio * radio_orbita_local
		_centro_orbita.y = global_position.y
		var sentido := -1.0 if randf() < 0.5 else 1.0
		velocidad_orbita *= randf_range(0.7, 1.3) * sentido
		_eje_rotacion = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		_vel_rotacion = randf_range(0.15, 0.45)

	_angulo_orbita += velocidad_orbita * delta
	global_position = _centro_orbita + Vector3(
		cos(_angulo_orbita) * radio_orbita_local,
		sin(_angulo_orbita * 2.0) * 0.4,
		sin(_angulo_orbita) * radio_orbita_local
	)
	rotate(_eje_rotacion, _vel_rotacion * delta)


func pulsar_cosecha() -> void:
	if _timer_flash <= 0.0:
		_aplicar_color(Color(0.65, 0.98, 1.0, 1.0))
		_timer_flash = 0.06


func recibir_dano(cantidad: float) -> bool:
	if _destruido or cantidad <= 0:
		return false
	vida_actual -= cantidad
	_aplicar_color(Color.WHITE)
	_timer_flash = 0.07

	if vida_actual <= 0.0:
		_destruido = true
		_ejecutar_efecto_destruccion()
		destruido.emit(global_position, tipo)
		queue_free()
		return true
	return false


func _ejecutar_efecto_destruccion() -> void:
	match tipo:
		TipoAsteroide.VOLATIL:
			_detonar_onda_expansiva()
		TipoAsteroide.MINERAL:
			_soltar_orbes_experiencia(3)


func _detonar_onda_expansiva() -> void:
	var radio_sq := radio_explosion_volatil * radio_explosion_volatil
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := nodo as Node3D
		if not is_instance_valid(enemigo):
			continue
		var offset := enemigo.global_position - global_position
		if offset.length_squared() <= radio_sq:
			if enemigo.has_method("recibir_dano"):
				enemigo.recibir_dano(dano_explosion_volatil)
			if enemigo is CharacterBody3D:
				var empujon := offset.normalized() if offset.length() > 0.05 else Vector3.UP
				if enemigo.has_method("aplicar_impulso"):
					enemigo.aplicar_impulso(empujon * 32.0)
				else:
					enemigo.velocity += empujon * 32.0


func _soltar_orbes_experiencia(cantidad: int) -> void:
	if escena_orbe == null or get_tree().current_scene == null:
		return
	var gestor := get_tree().get_first_node_in_group("gestor_recompensas")
	if gestor == null:
		return
	for i in range(cantidad):
		var disperso := Vector3(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0), randf_range(-4.0, 4.0))
		gestor.crear_orbe(global_position + disperso)


func _aplicar_color(color: Color) -> void:
	if _material_instancia == null:
		_material_instancia = ShaderMaterial.new()
		_material_instancia.shader = preload("res://assets/modelos/roca.gdshader")
		_material_instancia.set_shader_parameter("semilla", randf() * TAU)
		$MeshInstance3D.material_override = _material_instancia
	_material_instancia.set_shader_parameter("veta", color)
	var brillo := 0.0 if tipo == TipoAsteroide.COMUN else 1.0
	_material_instancia.set_shader_parameter("intensidad", brillo)
