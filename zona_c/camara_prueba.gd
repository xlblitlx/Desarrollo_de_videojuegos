extends Camera3D
## Sigue al jugador sin cambiar la camara de las otras zonas.

@export var objetivo: Node3D
@export var desfase := Vector3(0.0, 10.0, 15.0)


func _ready() -> void:
    if objetivo != null:
        global_position = objetivo.global_position + desfase
        look_at(objetivo.global_position + Vector3.UP * 0.5)


func _process(delta: float) -> void:
    if objetivo == null:
        return
    var posicion_deseada := objetivo.global_position + desfase
    global_position = global_position.lerp(posicion_deseada, minf(delta * 8.0, 1.0))
    look_at(objetivo.global_position + Vector3.UP * 0.5)
