class_name DirectorEventos
extends Node
## Selecciona y temporiza eventos hijos sin conocer su lógica interna.

@export var eventos_juego: BusEventos
@export var tiempo_entre_eventos: float = 42.0
@export var primer_evento_en: float = 45.0

var _timer_espera: float = 20.0
var _evento_actual: EventoEspacial = null


func _ready() -> void:
	_timer_espera = primer_evento_en
	if eventos_juego == null:
		eventos_juego = EventosJuego


func _process(delta: float) -> void:
	if is_instance_valid(_evento_actual) and _evento_actual.activo:
		_evento_actual.actualizar(delta, eventos_juego)
		return

	_timer_espera -= delta
	if _timer_espera <= 0.0:
		_lanzar_aleatorio()


func _lanzar_aleatorio() -> void:
	var candidatos: Array[EventoEspacial] = []
	for hijo in get_children():
		if hijo is EventoEspacial:
			candidatos.append(hijo)

	if candidatos.is_empty():
		return

	_evento_actual = candidatos[randi() % candidatos.size()]
	if not _evento_actual.finalizado.is_connected(_al_finalizar_evento):
		_evento_actual.finalizado.connect(_al_finalizar_evento, CONNECT_ONE_SHOT)

	_evento_actual.iniciar(eventos_juego)


func _al_finalizar_evento(exito: bool) -> void:
	var id := _evento_actual.id_evento if is_instance_valid(_evento_actual) else ""
	_evento_actual = null
	_timer_espera = tiempo_entre_eventos
	if eventos_juego:
		eventos_juego.evento_finalizado.emit(id, exito)
