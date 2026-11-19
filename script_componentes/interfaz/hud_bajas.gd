class_name HudBajas
extends CanvasLayer
## Contador de enemigos eliminados. Solo pinta el número que le entrega GestorPartida.

@onready var etiqueta: Label = find_child("EtiquetaBajas") as Label


func actualizar_bajas(total: int) -> void:
	if not is_node_ready():
		await ready
	if etiqueta:
		etiqueta.text = "BAJAS: %d" % total
