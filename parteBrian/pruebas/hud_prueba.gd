extends CanvasLayer
## Muestra los datos de prueba sin poner UI dentro del jugador.

@export var experiencia: GestorExperiencia
@export var disparo: ControlDisparo

var _etiqueta: Label
var _tiempo: float = 0.0


func _ready() -> void:
    _etiqueta = find_child("Estado", true, false) as Label
    _actualizar()


func _process(delta: float) -> void:
    _tiempo -= delta
    if _tiempo <= 0.0:
        _tiempo = 0.2
        _actualizar()


func _actualizar() -> void:
    if _etiqueta == null or experiencia == null:
        return
    _etiqueta.text = "ORBITAL ATTACK | PRUEBA DE COMBATE (ALBA)\n"
    _etiqueta.text += "EXP: %d / %d  |  Nivel: %d\n" % [
        experiencia.experiencia_total,
        GestorExperiencia.umbral_nivel(experiencia.nivel_actual + 1),
        experiencia.nivel_actual
    ]
    _etiqueta.text += "WASD: mover | Mouse: camara | ESC: liberar mouse\n"
    _etiqueta.text += "Disparo: automatico al enemigo mas cercano (18 m)\n"
    _etiqueta.text += "Enemigos de prueba: rosados | Orbes de EXP: dorados"
