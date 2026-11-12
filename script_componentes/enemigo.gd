class_name Enemigo
extends CharacterBody3D

signal destruido(posicion_global: Vector3)

@export var velocidad: float = 12.0
@export var vida: float = 30.0
@export var dano_contacto: float = 10.0
@export var intervalo_ataque: float = 1.0

var objetivo: Node3D = null
var _cooldown_ataque: float = 0.0
var _destruido: bool = false

@onready var zona_ataque: Area3D = find_child("ZonaAtaque") as Area3D


func establecer_objetivo(nuevo_objetivo: Node3D) -> void:
	objetivo = nuevo_objetivo


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	# Si no me inyectaron el objetivo, lo busco por grupo
	if not is_instance_valid(objetivo):
		objetivo = get_tree().get_first_node_in_group("jugador") as Node3D
		if objetivo == null:
			return

	_perseguir()
	_intentar_atacar(delta)


func _perseguir() -> void:
	var vector_hacia_jugador := objetivo.global_position - global_position
	var distancia := vector_hacia_jugador.length()
	var direccion := vector_hacia_jugador.normalized()

	# Si está muy cerca (menos de 3m), frena para no superponerse con la nave
	if distancia > 3.0:
		velocity = direccion * velocidad
	else:
		velocity = Vector3.ZERO

	move_and_slide()

	if direccion.length() > 0.01:
		var arriba := Vector3.UP if absf(direccion.y) < 0.99 else Vector3.RIGHT
		look_at(global_position + direccion, arriba)


func _intentar_atacar(delta: float) -> void:
	_cooldown_ataque -= delta
	if _cooldown_ataque > 0.0 or zona_ataque == null:
		return

	for cuerpo in zona_ataque.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano_contacto)
			_cooldown_ataque = intervalo_ataque
			break


func recibir_dano(cantidad: float) -> void:
	if _destruido:
		return
	vida -= cantidad
	if vida <= 0.0:
		_destruido = true
		destruido.emit(global_position)
		queue_free()

func _ready() -> void:
	velocidad *= randf_range(0.85, 1.15)
