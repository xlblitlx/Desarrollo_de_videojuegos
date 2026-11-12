class_name Enemigo
extends CharacterBody3D

signal destruido(posicion_global: Vector3)

@export var velocidad: float = 15.0
@export var vida: float = 40.0
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


var _ultima_normal_planeta: Vector3 = Vector3.ZERO

func _perseguir() -> void:
	var distancia := global_position.distance_to(objetivo.global_position)
	
	var punto_intercepcion := objetivo.global_position
	if objetivo is CharacterBody3D and distancia > 6.0:
		var tiempo_prediccion := clampf(distancia / maxf(velocidad, 1.0) * 0.45, 0.0, 0.75)
		punto_intercepcion += objetivo.velocity * tiempo_prediccion

	var direccion := (punto_intercepcion - global_position).normalized()
	
	if distancia > 3.0:
		velocity = direccion * velocidad
	else:
		velocity = Vector3.ZERO

	# Si el frame anterior rozó un planeta, desvía la velocidad antes del único move_and_slide()
	if _ultima_normal_planeta != Vector3.ZERO and velocity.dot(_ultima_normal_planeta) < 0.0:
		var tangente := _ultima_normal_planeta.cross(Vector3.UP).normalized()
		if tangente.length_squared() < 0.01:
			tangente = _ultima_normal_planeta.cross(Vector3.RIGHT).normalized()
		velocity = (velocity.slide(_ultima_normal_planeta) + tangente * (velocidad * 0.65)).normalized() * velocidad

	move_and_slide()

	# Registra si chocó contra algo sólido para esquivarlo en el siguiente frame
	if get_slide_collision_count() > 0:
		_ultima_normal_planeta = get_slide_collision(0).get_normal()
	else:
		_ultima_normal_planeta = Vector3.ZERO

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
