class_name EventoTormentaMagnetica
extends EventoEspacial

var _respaldos: Array[Dictionary] = []


func _init() -> void:
	id_evento = "tormenta_magnetica"
	titulo = "⚡ TORMENTA MAGNÉTICA: Gravedad +35%"
	duracion = 18.0


func iniciar(bus: BusEventos) -> void:
	super.iniciar(bus)
	_respaldos.clear()

	for p in get_tree().get_nodes_in_group("planetas"):
		if p is Node3D and "fuerza_gravedad" in p:
			_respaldos.append({ "planeta": p, "gravedad": p.fuerza_gravedad })
			p.fuerza_gravedad *= 1.35

	if bus:
		bus.evento_iniciado.emit(id_evento, titulo, null, duracion)


func cerrar(exito: bool) -> void:
	for item in _respaldos:
		var p: Node3D = item["planeta"]
		if is_instance_valid(p):
			p.fuerza_gravedad = item["gravedad"]
	_respaldos.clear()
	super.cerrar(exito)
