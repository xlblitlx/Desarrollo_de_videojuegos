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
var _datos_planetas: Array[Dictionary] = []

@onready var zona_ataque: Area3D = find_child("ZonaAtaque") as Area3D


func _ready() -> void:
	velocidad *= randf_range(0.85, 1.15)


func establecer_objetivo(nuevo_objetivo: Node3D) -> void:
	objetivo = nuevo_objetivo


func _cargar_planetas() -> void:
	if not _datos_planetas.is_empty():
		return
	for nodo in get_tree().get_nodes_in_group("planetas"):
		var planeta := nodo as Node3D
		if planeta == null:
			continue
		# Usa exactamente el radio del colisionador físico del núcleo que ya creaste
		var col := planeta.get_node_or_null("CuerpoSolido/CollisionShape3D") as CollisionShape3D
		if col and col.shape is SphereShape3D:
			var radio_real: float = col.shape.radius * col.global_transform.basis.get_scale().x
			_datos_planetas.append({
				"nodo": planeta,
				"radio": radio_real
			})


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
	_cargar_planetas()

	var distancia := global_position.distance_to(objetivo.global_position)
	
	# Calculamos el punto futuro donde estará el jugador según su velocidad
	var punto_intercepcion := objetivo.global_position
	if objetivo is CharacterBody3D and distancia > 6.0:
		# A mayor distancia, predice un poco más adelante (hasta 0.75 segundos)
		var tiempo_prediccion := clampf(distancia / maxf(velocidad, 1.0) * 0.45, 0.0, 0.75)
		punto_intercepcion += objetivo.velocity * tiempo_prediccion

	var direccion := (punto_intercepcion - global_position).normalized()
	
	# Si está muy cerca (menos de 3m), frena para no superponerse con la nave
	if distancia > 3.0:
		velocity = direccion * velocidad
	else:
		velocity = Vector3.ZERO

	# Desvía la velocidad suavemente si va a entrar en el núcleo sólido de un planeta
	for dato in _datos_planetas:
		var planeta: Node3D = dato["nodo"]
		if not is_instance_valid(planeta):
			continue
		var radio: float = dato["radio"]
		var desde_centro := global_position - planeta.global_position
		var dist := desde_centro.length()
		var limite := radio + 2.0
		if dist < limite and dist > 0.001:
			var normal := desde_centro / dist
			# Si está intentando meterse hacia el centro, desliza la velocidad por fuera de la esfera
			if velocity.dot(normal) < 0.0:
				velocity = velocity.slide(normal).normalized() * velocidad
			# Empuje suave hacia afuera si llegó a rozar el borde
			velocity += normal * (limite - dist) * 10.0

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
