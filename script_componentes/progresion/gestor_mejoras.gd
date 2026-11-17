class_name GestorMejoras
extends Node
## Controla el catálogo de mejoras roguelike, pausa el juego al subir de nivel y aplica las selecciones.

signal mostrar_menu_mejoras(opciones: Array[Dictionary], nivel: int)

@export var gestor_experiencia: GestorExperiencia
@export var jugador: CharacterBody3D
@export var control_disparo: ControlDisparo

var _nivel_sifon_orbital: int = 0
var _bono_cosecha_asteroides: float = 0.0

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
		"id": "propulsor",
		"titulo": "Turbinas Iónicas",
		"descripcion": "+15% velocidad y -20% consumo de propulsor.",
		"color": Color("#6A4C93")
	},
	{
		"id": "casco",
		"titulo": "Blindaje Reforzado",
		"descripcion": "+25 Vida Máxima y repara 40 HP al instante.",
		"color": Color("#2EC4B6")
	},
	{
		"id": "sifon_orbital",
		"titulo": "Sifón Planetario",
		"descripcion": "Agotar un planeta repara +15 HP y recarga +25 energía.",
		"color": Color("#00E5FF")
	},
	{
		"id": "cosecha_estatica",
		"titulo": "Cosecha Magnética",
		"descripcion": "+50% radio de orbes y +35% recarga en asteroides.",
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

	if EventosJuego and EventosJuego.has_signal("planeta_agotado"):
		EventosJuego.planeta_agotado.connect(_al_agotar_planeta)


func _al_subir_nivel(nivel: int) -> void:
	var baraja := _catalogo.duplicate()
	baraja.shuffle()
	var opciones: Array[Dictionary] = []
	for i in range(mini(3, baraja.size())):
		opciones.append(baraja[i])

	get_tree().paused = true
	mostrar_menu_mejoras.emit(opciones, nivel)


func _al_agotar_planeta(_planeta: Node3D) -> void:
	if _nivel_sifon_orbital <= 0 or not is_instance_valid(jugador):
		return
	if jugador.has_method("curar"):
		jugador.curar(15.0 * _nivel_sifon_orbital)
	if "energia_actual" in jugador and "energia_maxima" in jugador:
		jugador.energia_actual = minf(jugador.energia_maxima, jugador.energia_actual + 25.0 * _nivel_sifon_orbital)


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
		"propulsor":
			if jugador:
				if "velocidad_normal" in jugador:
					jugador.velocidad_normal *= 1.15
				if "velocidad_propulsion" in jugador:
					jugador.velocidad_propulsion *= 1.15
				if "multiplicador_consumo" in jugador:
					jugador.multiplicador_consumo *= 0.80
		"casco":
			if jugador and "vida_maxima" in jugador and "vida_actual" in jugador:
				jugador.vida_maxima += 25.0
				jugador.vida_actual = minf(jugador.vida_maxima, jugador.vida_actual + 40.0)
				if jugador.has_signal("vida_cambiada"):
					jugador.vida_cambiada.emit(jugador.vida_actual, jugador.vida_maxima)
		"sifon_orbital":
			_nivel_sifon_orbital += 1
		"cosecha_estatica":
			_bono_cosecha_asteroides += 0.35
			for nodo in get_tree().get_nodes_in_group("orbes"):
				if "radio_iman" in nodo:
					nodo.radio_iman *= 1.5
			for ast in get_tree().get_nodes_in_group("asteroides"):
				if "recarga_energia" in ast:
					ast.recarga_energia *= 1.35

	get_tree().paused = false
