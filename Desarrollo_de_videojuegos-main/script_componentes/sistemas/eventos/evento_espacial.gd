class_name EventoEspacial
extends Node
## Contrato base para cualquier evento temporal gestionado por DirectorEventos.

signal finalizado(exito: bool)

@export var id_evento: String = "evento_base"
@export var titulo: String = "Evento Espacial"
@export var duracion: float = 20.0

var activo: bool = false
var tiempo_restante: float = 0.0


func iniciar(_bus: BusEventos) -> void:
	activo = true
	tiempo_restante = duracion


func actualizar(delta: float, _bus: BusEventos) -> void:
	if not activo:
		return
	tiempo_restante -= delta
	if tiempo_restante <= 0.0:
		cerrar(false)


func cerrar(exito: bool) -> void:
	if not activo:
		return
	activo = false
	finalizado.emit(exito)
