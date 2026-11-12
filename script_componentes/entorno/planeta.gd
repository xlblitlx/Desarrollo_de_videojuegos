extends Node3D


@onready var zona_orbita: Area3D = $ZonaOrbita

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
