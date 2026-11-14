class_name Asteroide
extends Node3D
## Asteroide individual con variantes tácticas y respuesta visual al daño o cosecha.

enum TipoAsteroide { COMUN, VOLATIL, ENERGETICO, MINERAL }

signal destruido(posicion: Vector3, tipo: TipoAsteroide)

@export var vida_base: float = 15.0
@export var radio_explosion_volatil: float = 26.0
@export var dano_explosion_volatil: float = 35.0
@export var escena_orbe: PackedScene = preload("res://escenas/orbe.tscn")

var tipo: TipoAsteroide = TipoAsteroide.COMUN
var vida_actual: float = 15.0
var _material_instancia: StandardMaterial3D = null
var _color_base: Color = Color(0.55, 0.55, 0.58, 1.0)
var _timer_flash: float = 0.0


func configurar(escala: float) -> void:
	var factor_tamano := clampf(escala / 8.0, 0.7, 2.0)

	var dado := randf()
	if dado < 0.40:
		tipo = TipoAsteroide.COMUN
		vida_actual = vida_base * factor_tamano
		_color_base = Color(0.55, 0.55, 0.58, 1.0)
	elif dado < 0.65:
		tipo = TipoAsteroide.VOLATIL
		vida_actual = vida_base * 0.75 * factor_tamano
		_color_base = Color(0.95, 0.32, 0.18, 1.0)
	elif dado < 0.90:
		tipo = TipoAsteroide.ENERGETICO
		vida_actual = vida_base * factor_tamano
		_color_base = Color(0.18, 0.88, 1.0, 1.0)
	else:
		tipo = TipoAsteroide.MINERAL
		vida_actual = vida_base * 1.45 * factor_tamano
		_color_base = Color(1.0, 0.82, 0.22, 1.0)

	_aplicar_color(_color_base)


func _process(delta: float) -> void:
	if _timer_flash > 0.0:
		_timer_flash -= delta
		if _timer_flash <= 0.0:
			_aplicar_color(_color_base)


func pulsar_cosecha() -> void:
	# Destello breve para que el jugador note que está absorbiendo energía
	if _timer_flash <= 0.0:
		_aplicar_color(Color(0.65, 0.98, 1.0, 1.0))
		_timer_flash = 0.06


func recibir_dano(cantidad: float) -> bool:
	vida_actual -= cantidad
	_aplicar_color(Color.WHITE)
	_timer_flash = 0.07

	if vida_actual <= 0.0:
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
				enemigo.velocity += empujon * 32.0


func _soltar_orbes_experiencia(cantidad: int) -> void:
	if escena_orbe == null or get_tree().current_scene == null:
		return
	var jugador := get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	for i in range(cantidad):
		var orbe := escena_orbe.instantiate() as Orbe
		if orbe == null:
			continue
		orbe.jugador = jugador
		get_tree().current_scene.add_child(orbe)
		var disperso := Vector3(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0), randf_range(-4.0, 4.0))
		orbe.global_position = global_position + disperso


func _aplicar_color(color: Color) -> void:
	if _material_instancia == null:
		var malla := find_child("*", true, false) as MeshInstance3D
		if malla:
			var mat := malla.get_active_material(0) as StandardMaterial3D
			if mat:
				_material_instancia = mat.duplicate() as StandardMaterial3D
				malla.material_override = _material_instancia
			else:
				_material_instancia = StandardMaterial3D.new()
				malla.material_override = _material_instancia

	if _material_instancia:
		_material_instancia.albedo_color = color
		if tipo != TipoAsteroide.COMUN:
			_material_instancia.emission_enabled = true
			_material_instancia.emission = color
			_material_instancia.emission_energy_multiplier = 0.45
