class_name EscaladorNivel
extends Node
## Mejora las estadísticas del jugador y su arma automáticamente al subir de nivel.

@export var gestor_experiencia: GestorExperiencia
@export var jugador: Jugador
@export var control_disparo: ControlDisparo

@export_group("Mejoras por Nivel")
@export var bonus_dano: float = 2.5           # +2.5 de daño por nivel (6 -> 8.5 -> 11 -> 13.5...)
@export var reduccion_intervalo: float = 0.08 # Dispara más rápido cada nivel (tope 0.18s)
@export var bonus_alcance: float = 2.0        # +2m de alcance por nivel
@export var bonus_vida_maxima: float = 15.0   # +15 de vida máxima y curación parcial al subir


func _ready() -> void:
	if gestor_experiencia:
		gestor_experiencia.subio_nivel.connect(_al_subir_nivel)


func _al_subir_nivel(nivel: int) -> void:
	if control_disparo:
		control_disparo.dano += bonus_dano
		control_disparo.intervalo = maxf(0.18, control_disparo.intervalo - reduccion_intervalo)
		control_disparo.alcance += bonus_alcance

	if jugador:
		jugador.vida_maxima += bonus_vida_maxima
		jugador.vida_actual = minf(jugador.vida_maxima, jugador.vida_actual + 25.0)
		jugador.vida_cambiada.emit(jugador.vida_actual, jugador.vida_maxima)

	print("¡Nivel %d alcanzado! Daño: %.1f | Cadencia: %.2fs" % [
		nivel,
		control_disparo.dano if control_disparo else 0.0,
		control_disparo.intervalo if control_disparo else 0.0
	])
