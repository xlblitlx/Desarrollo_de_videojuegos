extends Node3D


@onready var zona_orbita: Area3D = $ZonaOrbita

@export_group("Gravedad Orbital")
@export var fuerza_gravedad: float = 65.0
@export var radio_nucleo_seguro: float = 16.0
@export var radio_orbita_referencia: float = 45.0
@export var multiplicador_escape: float = 2.1

func calcular_atraccion_sobre(pos_nave: Vector3, vel_nave: Vector3, impulso_escape: float = 0.0) -> Vector3:
	var hacia_centro := global_position - pos_nave
	var distancia := hacia_centro.length()
	
	if distancia <= radio_nucleo_seguro or distancia < 0.01:
		return Vector3.ZERO
	
	var dir_centro := hacia_centro / distancia
	var factor_cercania := clampf(1.0 - ((distancia - radio_nucleo_seguro) / maxf(radio_orbita_referencia - radio_nucleo_seguro, 1.0)), 0.0, 1.0)
	var fuerza := fuerza_gravedad * (1.0 + factor_cercania * 0.85)
	
	# Si intenta salir hacia afuera, la gravedad resiste según cuánto impulso haya acumulado
	if vel_nave.dot(dir_centro) < 0.0:
		var resistencia := lerpf(multiplicador_escape, 0.45, clampf(impulso_escape, 0.0, 1.0))
		fuerza *= resistencia
		
	return dir_centro * fuerza

func _ready() -> void:
	# Agrega este planeta al grupo global para búsquedas de respaldo
	add_to_group("planetas")
	
	# Ajusta automáticamente el radio de la colisión física al tamaño de la malla visual
	var colision := get_node_or_null("CuerpoSolido/CollisionShape3D") as CollisionShape3D
	var malla := find_child("*", true, false) as MeshInstance3D
	if colision and colision.shape is SphereShape3D and malla and malla.mesh:
		colision.shape.radius = malla.get_aabb().size.x * 0.5 * malla.scale.x
	
	if zona_orbita:
		zona_orbita.body_entered.connect(_on_body_entered)
		zona_orbita.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		var gestor = body.find_child("GestorOrbita", true, false) as GestorOrbita
		if gestor:
			gestor.registrar_planeta_entrante(self)

func _on_body_exited(body: Node3D) -> void:
	if body is Jugador:
		var gestor = body.find_child("GestorOrbita", true, false) as GestorOrbita
		if gestor:
			gestor.registrar_planeta_saliente(self)
