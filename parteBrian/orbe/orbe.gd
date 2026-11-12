class_name Orbe
extends Area3D
## Recompensa de energia. Se acerca al jugador y entrega EXP al tocarlo.

signal orbe_recogido(valor: int)

@export var valor: int = 1
@export var radio_iman: float = 15.0
@export var velocidad_iman: float = 14.0
@export var distancia_recoleccion: float = 1.1
@export var jugador: CharacterBody3D

var _recogido: bool = false


func _ready() -> void:
    add_to_group("orbes")
    body_entered.connect(_al_entrar_cuerpo)


func _physics_process(delta: float) -> void:
    if _recogido:
        return

    if not is_instance_valid(jugador):
        jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
    if jugador == null:
        return

    var distancia := global_position.distance_to(jugador.global_position)
    if distancia <= distancia_recoleccion:
        _recoger()
    elif distancia <= radio_iman:
        global_position = global_position.move_toward(
            jugador.global_position, velocidad_iman * delta
        )


func _al_entrar_cuerpo(cuerpo: Node3D) -> void:
    if cuerpo == jugador or cuerpo.is_in_group("jugador"):
        _recoger()


func _recoger() -> void:
    if _recogido:
        return
    _recogido = true
    orbe_recogido.emit(valor)
    queue_free()
