class_name Enemigo
extends EnemigoBase
## Wrapper de compatibilidad: delega cada enemigo a su clase especializada
## sin invalidar la referencia del nodo durante set_script().

enum Rol { PERSEGUIDOR, EMBESTIDOR, ARTILLERO }

const COSTES := [1, 2, 3]
const SCRIPTS_ROL := [
	preload("res://script_componentes/entidades/enemigos/EnemigoPerseguidor.gd"),
	preload("res://script_componentes/entidades/enemigos/EnemigoEmbestidor.gd"),
	preload("res://script_componentes/entidades/enemigos/EnemigoArtillero.gd")
]

@export var rol: Rol = Rol.PERSEGUIDOR


func _ready() -> void:
	configurar_rol(rol)


func configurar_rol(nuevo_rol: Rol) -> void:
	rol = nuevo_rol
	var idx := clampi(int(rol), 0, SCRIPTS_ROL.size() - 1)

	# Guardamos la referencia al nodo C++ antes de reemplazar el script GDScript
	var nodo: Node3D = self
	var objetivo_guardado := objetivo

	nodo.set_script(SCRIPTS_ROL[idx])

	# A partir de aquí usamos siempre 'nodo', nunca 'self'
	if is_instance_valid(objetivo_guardado):
		nodo.set("objetivo", objetivo_guardado)

	nodo.set_process(true)
	nodo.set_physics_process(true)

	# Si el nodo ya estaba dentro del árbol de escena, inicializamos el nuevo script
	if nodo.is_inside_tree() and nodo.has_method("_ready"):
		nodo.call("_ready")
