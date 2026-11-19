class_name Enemigo
extends CharacterBody3D

signal destruido(posicion_global: Vector3)

@export var velocidad: float = 15.0
@export var vida: float = 5.0
@export var dano_contacto: float = 10.0
@export var intervalo_ataque: float = 1.0
@export var rango_ataque: float = 3.4

var objetivo: Node3D = null
var _cooldown_ataque: float = 0.0
var _destruido: bool = false
var _retroceso: Vector3 = Vector3.ZERO

@onready var zona_ataque: Area3D = find_child("ZonaAtaque") as Area3D


func _ready() -> void:
	velocidad *= randf_range(0.85, 1.15)


func establecer_objetivo(nuevo_objetivo: Node3D) -> void:
	objetivo = nuevo_objetivo


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	if not is_instance_valid(objetivo):
		objetivo = get_tree().get_first_node_in_group("jugador") as Node3D
		if objetivo == null:
			return

	_perseguir(delta)
	_intentar_atacar(delta)


func _perseguir(delta: float) -> void:
	var distancia := global_position.distance_to(objetivo.global_position)

	var punto_intercepcion := objetivo.global_position
	if objetivo is CharacterBody3D and distancia > 10.0:
		var factor_pred := 0.15 if objetivo.get("propulsor_activo") == true else 0.35
		var tiempo_prediccion := clampf(distancia / maxf(velocidad, 1.0) * factor_pred, 0.0, 0.5)
		punto_intercepcion += objetivo.velocity * tiempo_prediccion

	var direccion := (punto_intercepcion - global_position).normalized()

	# Siempre avanza directo hasta impactar; solo se separa cuando recibe el impulso de retroceso tras golpear
	velocity = direccion * velocidad + _retroceso
	_retroceso = _retroceso.move_toward(Vector3.ZERO, 22.0 * delta)
	move_and_slide()

	if direccion.length() > 0.01:
		var arriba := Vector3.UP if absf(direccion.y) < 0.99 else Vector3.RIGHT
		look_at(global_position + direccion, arriba)


func _intentar_atacar(delta: float) -> void:
	_cooldown_ataque -= delta
	if _cooldown_ataque > 0.0:
		return

	var jugador_en_rango := global_position.distance_to(objetivo.global_position) <= rango_ataque
	if not jugador_en_rango and zona_ataque != null:
		for cuerpo in zona_ataque.get_overlapping_bodies():
			if cuerpo == objetivo or cuerpo.is_in_group("jugador"):
				jugador_en_rango = true
				break

	if jugador_en_rango and objetivo.has_method("recibir_dano"):
		objetivo.recibir_dano(dano_contacto)
		_cooldown_ataque = intervalo_ataque
		var direccion_atras := (global_position - objetivo.global_position).normalized()
		if direccion_atras == Vector3.ZERO:
			direccion_atras = Vector3.BACK
		_retroceso = direccion_atras * 15.0


func recibir_dano(cantidad: float) -> void:
	if _destruido:
		return
	vida -= cantidad
	_destellar_impacto()
	if vida <= 0.0:
		_destruido = true
		destruido.emit(global_position)
		queue_free()


func _destellar_impacto() -> void:
	for nodo in find_children("*", "MeshInstance3D", true, false):
		var mi := nodo as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			var mat := mi.get_active_material(s)
			if not (mat is BaseMaterial3D):
				continue
			var flash := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			flash.emission_enabled = true
			flash.emission = Color(1.0, 0.95, 0.9)
			flash.emission_energy_multiplier = 2.2
			mi.set_surface_override_material(s, flash)

			var tw := create_tween()
			tw.tween_property(flash, "emission_energy_multiplier", 0.0, 0.09)
			tw.tween_callback(_restaurar_material.bind(mi, s, mat))


func _restaurar_material(mi: MeshInstance3D, superficie: int, original: Material) -> void:
	if is_instance_valid(mi):
		mi.set_surface_override_material(superficie, original)
