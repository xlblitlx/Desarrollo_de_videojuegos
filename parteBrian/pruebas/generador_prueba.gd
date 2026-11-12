class_name GeneradorEnemigosPrueba
extends Node
## Enemigos de practica. No es el spawner real de Diego.

@export var jugador: CharacterBody3D
@export var contenedor_enemigos: Node3D
@export var escena_enemigo: PackedScene = preload("res://parteBrian/pruebas/enemigo_prueba.tscn")
@export var intervalo: float = 2.5
@export var maximo_enemigos: int = 7

var _tiempo: float = 0.0


func _ready() -> void:
    _tiempo = intervalo
    call_deferred("_crear_enemigo")
    call_deferred("_crear_enemigo")


func _process(delta: float) -> void:
    _tiempo -= delta
    if _tiempo <= 0.0:
        _tiempo = intervalo
        _crear_enemigo()


func _crear_enemigo() -> void:
    if jugador == null or contenedor_enemigos == null or escena_enemigo == null:
        return
    if contenedor_enemigos.get_child_count() >= maximo_enemigos:
        return

    var enemigo := escena_enemigo.instantiate() as EnemigoPrueba
    if enemigo == null:
        return
    enemigo.jugador = jugador
    contenedor_enemigos.add_child(enemigo)
    # Aparecen al lado de la orbita para no quedar dentro del planeta central.
    var radial := Vector3(jugador.global_position.x, 0.0, jugador.global_position.z).normalized()
    if radial == Vector3.ZERO:
        radial = Vector3.BACK
    var tangente := Vector3(radial.z, 0.0, -radial.x)
    var lado := -1.0 if randf() < 0.5 else 1.0
    var distancia := randf_range(8.0, 13.0)
    enemigo.global_position = (jugador.global_position
        + tangente * lado * distancia
        + radial * randf_range(-1.0, 1.0)
        + Vector3.UP * randf_range(-0.4, 0.4))
