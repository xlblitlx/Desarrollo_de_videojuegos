extends Node3D

@onready var zona_orbita: Area3D = $ZonaOrbita

func _ready() -> void:
	# Agrega este planeta al grupo global para búsquedas de respaldo
	add_to_group("planetas")
	
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
