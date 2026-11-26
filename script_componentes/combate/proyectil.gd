class_name Proyectil
extends Area3D
## Proyectil aliado u hostil.

signal impacto(cuerpo: Node3D)

@export var velocidad: float = 55.0
@export var dano: float = 5.0
@export var vida_maxima: float = 3.0
@export var hostil: bool = false

var direccion: Vector3 = Vector3.FORWARD
var _vida_restante: float = 0.0
var _destruido: bool = false


func _ready() -> void:
	_vida_restante = vida_maxima
	body_entered.connect(_al_entrar_cuerpo)


func configurar(nueva_direccion: Vector3, nuevo_dano: float) -> void:
	direccion = nueva_direccion.normalized()
	dano = nuevo_dano


func _physics_process(delta: float) -> void:
	if _destruido:
		return

	global_position += direccion * velocidad * delta
	_vida_restante -= delta
	if _vida_restante <= 0.0:
		queue_free()


func _al_entrar_cuerpo(cuerpo: Node3D) -> void:
	if _destruido or not is_instance_valid(cuerpo):
		return

	# Si golpea el StaticBody3D hijo ("Cobertura") de un asteroide, sube al nodo padre
	var objetivo: Node3D = cuerpo
	if not objetivo.has_method("recibir_dano") and objetivo.get_parent() is Node3D:
		objetivo = objetivo.get_parent() as Node3D

	if hostil:
		# Proyectil disparado por un Enemigo Artillero
		if objetivo.is_in_group("enemigos"):
			return
		if objetivo.is_in_group("jugador") and objetivo.has_method("recibir_dano"):
			_destruido = true
			objetivo.recibir_dano(dano)
			impacto.emit(objetivo)
			queue_free()
		elif objetivo.is_in_group("asteroides") or objetivo.is_in_group("planetas"):
			# Los asteroides y planetas sirven de cobertura contra disparos enemigos
			_destruido = true
			queue_free()
		return

	# Proyectil aliado del jugador
	if not (objetivo.is_in_group("enemigos") or objetivo.is_in_group("asteroides")):
		return

	_destruido = true
	if objetivo.has_method("recibir_dano"):
		objetivo.recibir_dano(dano)
	impacto.emit(objetivo)
	queue_free()
