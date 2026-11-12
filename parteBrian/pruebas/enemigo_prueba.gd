class_name EnemigoPrueba
extends CharacterBody3D
## Enemigo temporal para probar el modulo hasta que llegue el de Diego.

signal destruido(posicion_global: Vector3)

@export var velocidad: float = 3.5
@export var vida: float = 30.0
@export var jugador: CharacterBody3D


func _ready() -> void:
    add_to_group("enemigos")


func _physics_process(_delta: float) -> void:
    if not is_instance_valid(jugador):
        jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
    if jugador == null:
        return

    var direccion := jugador.global_position - global_position
    if direccion.length() > 2.5:
        velocity = direccion.normalized() * velocidad
    else:
        velocity = Vector3.ZERO
    move_and_slide()


func recibir_dano(cantidad: float) -> void:
    if cantidad <= 0.0 or is_queued_for_deletion():
        return
    vida -= cantidad
    if vida <= 0.0:
        destruido.emit(global_position)
        queue_free()
