class_name GestorExperiencia
extends Node
## Guarda la EXP total y calcula el nivel sin mezclar UI ni luces.

signal experiencia_actualizada(total: int, nivel: int)
signal subio_nivel(nivel: int)

@export var fuente_orbes: GestorRecompensas

var experiencia_total: int = 0
var nivel_actual: int = 1


func _ready() -> void:
    if fuente_orbes != null:
        fuente_orbes.orbe_recogido.connect(sumar_experiencia)
    experiencia_actualizada.emit(experiencia_total, nivel_actual)


func sumar_experiencia(valor: int) -> void:
    if valor <= 0:
        return

    experiencia_total += valor
    while experiencia_total >= umbral_nivel(nivel_actual + 1):
        nivel_actual += 1
        subio_nivel.emit(nivel_actual)

    experiencia_actualizada.emit(experiencia_total, nivel_actual)


static func umbral_nivel(nivel: int) -> int:
    if nivel <= 1:
        return 0
    if nivel == 2:
        return 50
    if nivel == 3:
        return 110
    if nivel == 4:
        return 180

    var extra := nivel - 4
    return 180 + 80 * extra + 5 * extra * (extra - 1)
