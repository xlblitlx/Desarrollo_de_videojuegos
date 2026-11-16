class_name GestorMejoras
extends Node
## Controla el catálogo de mejoras roguelike, pausa el juego al subir de nivel y aplica las selecciones.

signal mostrar_menu_mejoras(opciones: Array[Dictionary], nivel: int)

@export var gestor_experiencia: GestorExperiencia
@export var jugador: CharacterBody3D
@export var control_disparo: ControlDisparo

var _catalogo: Array[Dictionary] = [
	{
		"id": "dano",
		"titulo": "Núcleo de Plasma",
		"descripcion": "+35% de daño en todos tus proyectiles.",
		"color": Color("#FF595E")
	},
	{
		"id": "cadencia",
		"titulo": "Sobrecarga de Cañón",
		"descripcion": "+20% de velocidad de disparo.",
		"color": Color("#FFCA3A")
	},
	{
		"id": "multidisparo",
		"titulo": "Cañón Dividido",
		"descripcion": "+1 proyectil adicional en abanico.",
		"color": Color("#8AC926")
	},
	{
		"id": "alcance",
		"titulo": "Radar Táctico",
		"descripcion": "+6m de alcance de detección y disparo.",
		"color": Color("#1982C4")
	},
	{
		"id": "propulsor",
		"titulo": "Turbinas Iónicas",
		"descripcion": "+15% de velocidad máxima y empuje.",
		"color": Color("#6A4C93")
	},
	{
		"id": "casco",
		"titulo": "Blindaje Reforzado",
		"descripcion": "+25 Vida Máxima y repara 40 HP al instante.",
		"color": Color("#2EC4B6")
	},
	{
		"id": "iman",
		"titulo": "Campo Gravitatorio",
		"descripcion": "Duplica el radio de atracción de los orbes.",
		"color": Color("#FF9F1C")
	}
]


func _ready() -> void:
	await get_tree().process_frame
	if gestor_experiencia == null:
		gestor_experiencia = get_tree().get_first_node_in_group("gestor_experiencia") as GestorExperiencia
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if control_disparo == null and jugador != null:
		control_disparo = jugador.find_child("ControlDisparo", true, false) as ControlDisparo

	if gestor_experiencia:
		gestor_experiencia.subio_nivel.connect(_al_subir_nivel)


func _al_subir_nivel(nivel: int) -> void:
	var baraja := _catalogo.duplicate()
	baraja.shuffle()
	var opciones: Array[Dictionary] = []
	for i in range(mini(3, baraja.size())):
		opciones.append(baraja[i])

	get_tree().paused = true
	mostrar_menu_mejoras.emit(opciones, nivel)


func aplicar_mejora(id_mejora: String) -> void:
	match id_mejora:
		"dano":
			if control_disparo:
				control_disparo.dano = roundf(control_disparo.dano * 1.35 * 10.0) / 10.0
		"cadencia":
			if control_disparo:
				control_disparo.intervalo = maxf(0.12, control_disparo.intervalo * 0.80)
		"multidisparo":
			if control_disparo:
				control_disparo.cantidad_proyectiles += 1
		"alcance":
			if control_disparo:
				control_disparo.alcance += 6.0
		"propulsor":
			if jugador:
				if "velocidad_normal" in jugador:
					jugador.velocidad_normal *= 1.15
				if "velocidad_propulsion" in jugador:
					jugador.velocidad_propulsion *= 1.15
		"casco":
			if jugador and "vida_maxima" in jugador and "vida_actual" in jugador:
				jugador.vida_maxima += 25.0
				jugador.vida_actual = minf(jugador.vida_maxima, jugador.vida_actual + 40.0)
				if jugador.has_signal("vida_cambiada"):
					jugador.vida_cambiada.emit(jugador.vida_actual, jugador.vida_maxima)
		"iman":
			# Aumenta el radio de imán de los orbes activos y futuros
			for nodo in get_tree().get_nodes_in_group("orbes"):
				if "radio_iman" in nodo:
					nodo.radio_iman *= 1.5

	get_tree().paused = false
