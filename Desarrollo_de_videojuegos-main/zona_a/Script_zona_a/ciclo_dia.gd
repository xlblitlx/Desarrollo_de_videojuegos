class_name CicloDia
extends Node

# color de la luz cuando está baja (#F2F5FF de la paleta)
const NARANJA := Color("F2F5FF")

@export var hora := 10.0
@export var duracion_dia := 48.0  # segundos reales de un día completo
@export var pausado := true       # la estrella está fija

func avanzar(dt: float) -> void:
	if not pausado:
		# fposmod para que después de las 24 vuelva a 0
		hora = fposmod(hora + 24.0 * dt / duracion_dia, 24.0)

static func elevacion(h: float) -> float:
	return (h - 6.0) * 15.0

# sin pide radianes; el maxf evita energía negativa de noche
static func factor_sol(h: float) -> float:
	return maxf(0.0, sin(deg_to_rad(elevacion(h))))

static func color_sol(h: float) -> Color:
	return NARANJA.lerp(Color.WHITE, factor_sol(h))
