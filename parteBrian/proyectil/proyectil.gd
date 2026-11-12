class_name Proyectil
extends Area3D
## Proyectil aliado. Avanza recto y solo causa dano a los enemigos.

signal impacto(cuerpo: Node3D)

@export var velocidad: float = 32.0
@export var dano: float = 15.0
@export var vida_maxima: float = 3.0

var direccion: Vector3 = Vector3.FORWARD
var _vida_restante: float = 0.0
var _destruido: bool = false


func _ready() -> void:
    _vida_restante = vida_maxima
    body_entered.connect(_al_entrar_cuerpo)


func configurar(nueva_direccion: Vector3, nuevo_dano: float) -> void:
    direccion = nueva_direccion.normalized()
    dano = nuevo_dano


func _physics_process(delta: float) -> void:
    if _destruido:
        return

    global_position += direccion * velocidad * delta
    _vida_restante -= delta
    if _vida_restante <= 0.0:
        queue_free()


func _al_entrar_cuerpo(cuerpo: Node3D) -> void:
    if _destruido or not is_instance_valid(cuerpo):
        return

    # No impacta al jugador ni a los planetas.
    if not cuerpo.is_in_group("enemigos") and not cuerpo.has_method("recibir_dano"):
        return

    _destruido = true
    if cuerpo.has_method("recibir_dano"):
        cuerpo.call("recibir_dano", dano)
    impacto.emit(cuerpo)
    queue_free()
