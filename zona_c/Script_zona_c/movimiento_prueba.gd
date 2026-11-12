extends CharacterBody3D
## Movimiento sencillo para probar la luz de la nave en la Zona C.
## Usa las acciones de teclado que ya estan en project.godot.

@export var velocidad := 6.0


func _physics_process(_delta: float) -> void:
    var entrada := Input.get_vector("left", "right", "up", "down")
    velocity = Vector3(entrada.x, 0.0, entrada.y) * velocidad
    move_and_slide()
