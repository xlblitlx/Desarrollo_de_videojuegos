class_name ControlDisparo
extends Node3D
## Busca el enemigo mas cercano y dispara sin apuntado manual.

signal disparo_realizado(destino: Node3D)

@export var jugador: CharacterBody3D
@export var contenedor_proyectiles: Node3D
@export var escena_proyectil: PackedScene = preload("res://parteBrian/proyectil/proyectil.tscn")
@export var intervalo: float = 0.5
@export var alcance: float = 18.0
@export var dano: float = 15.0
@export var altura_salida: float = 0.2

var _espera: float = 0.0


func _physics_process(delta: float) -> void:
    if jugador == null or contenedor_proyectiles == null or escena_proyectil == null:
        return

    _espera = maxf(0.0, _espera - delta)
    if _espera > 0.0:
        return

    var enemigo := _encontrar_enemigo()
    if enemigo == null:
        return

    _disparar(enemigo)
    _espera = maxf(intervalo, 0.05)


func _encontrar_enemigo() -> Node3D:
    var objetivo: Node3D = null
    var distancia_minima := alcance * alcance

    for nodo in get_tree().get_nodes_in_group("enemigos"):
        if not nodo is Node3D or nodo.is_queued_for_deletion():
            continue
        var candidato := nodo as Node3D
        var distancia := jugador.global_position.distance_squared_to(candidato.global_position)
        if distancia < distancia_minima:
            objetivo = candidato
            distancia_minima = distancia

    return objetivo


func _disparar(enemigo: Node3D) -> void:
    var proyectil := escena_proyectil.instantiate() as Proyectil
    if proyectil == null:
        push_error("La escena de proyectil debe tener Proyectil en la raiz.")
        return

    var origen := jugador.global_position + Vector3.UP * altura_salida
    var direccion := (enemigo.global_position - origen).normalized()
    if direccion == Vector3.ZERO:
        proyectil.free()
        return

    proyectil.configurar(direccion, dano)
    contenedor_proyectiles.add_child(proyectil)
    proyectil.global_position = origen + direccion * 1.4
    disparo_realizado.emit(enemigo)
