class_name EventoSobrecargaSolar
extends EventoEspacial

var _planeta: Node3D = null
var _reserva: Node = null
var _mult_original: float = 1.0
var _regen_original: float = 9.0


func _init() -> void:
	id_evento = "sobrecarga_solar"
	titulo = "☀️ SOBRECARGA SOLAR: Planeta recarga 2x"
	duracion = 22.0


func iniciar(bus: BusEventos) -> void:
	var planetas := get_tree().get_nodes_in_group("planetas")
	if planetas.is_empty():
		return

	_planeta = planetas[randi() % planetas.size()] as Node3D
	_reserva = _planeta.get_node_or_null("ReservaOrbital")
	if _reserva == null:
		_planeta = null
		return

	super.iniciar(bus)
	_planeta.add_to_group("puntos_interes")

	_mult_original = _reserva.multiplicador_recarga_nave
	_regen_original = _reserva.regeneracion_por_seg
	_reserva.multiplicador_recarga_nave *= 2.0
	_reserva.regeneracion_por_seg *= 2.5
	_reserva.energia_actual = _reserva.energia_maxima

	if bus:
		bus.evento_iniciado.emit(id_evento, titulo, _planeta, duracion)


func cerrar(exito: bool) -> void:
	if is_instance_valid(_planeta) and _planeta.is_in_group("puntos_interes"):
		_planeta.remove_from_group("puntos_interes")

	if is_instance_valid(_reserva):
		_reserva.multiplicador_recarga_nave = _mult_original
		_reserva.regeneracion_por_seg = _regen_original

	_planeta = null
	_reserva = null
	super.cerrar(exito)
