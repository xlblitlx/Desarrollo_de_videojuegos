class_name GestorOleadas
extends Node
## Escala la dificultad por tiempo: acelera el spawner de Diego y añade refuerzos en grupo.

@export var spawner_enemigos: Node3D
@export var segundos_por_escalado: float = 25.0 # Sube intensidad cada 25s (0:25, 0:50, 1:15, 1:40...)

@export_group("Escalado Progresivo")
@export var intervalo_inicial: float = 2.8
@export var intervalo_minimo: float = 0.85
@export var reduccion_intervalo_por_nivel: float = 0.45
@export var max_enemigos_inicial: int = 18
@export var incremento_max_enemigos: int = 6
@export var tope_max_enemigos: int = 50
@export var max_refuerzos_por_oleada: int = 3 # Hasta +3 enemigos extra por aparición (grupos de 4)

var tiempo_supervivencia: float = 0.0
var nivel_intensidad: int = 1
var _ultimo_segundo_emitido: int = -1
var _jugador: Node3D = null


func _ready() -> void:
	await get_tree().process_frame
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D

	if spawner_enemigos == null:
		spawner_enemigos = _buscar_spawner(get_tree().current_scene)

	if is_instance_valid(spawner_enemigos):
		if spawner_enemigos.has_signal("enemigo_generado"):
			spawner_enemigos.enemigo_generado.connect(_al_generar_enemigo_base)
	else:
		push_warning("GestorOleadas: no encontró a SpawnEnemigos en la escena.")

	_aplicar_escalado()
	_emitir_tiempo()


func _process(delta: float) -> void:
	tiempo_supervivencia += delta

	var nuevo_nivel := int(tiempo_supervivencia / maxf(segundos_por_escalado, 1.0)) + 1
	if nuevo_nivel > nivel_intensidad:
		nivel_intensidad = nuevo_nivel
		_aplicar_escalado()
		if EventosJuego:
			EventosJuego.oleada_cambiada.emit(nivel_intensidad)

	var segundo_actual := int(tiempo_supervivencia)
	if segundo_actual != _ultimo_segundo_emitido:
		_ultimo_segundo_emitido = segundo_actual
		_emitir_tiempo()


func _al_generar_enemigo_base(enemigo_base: Node3D) -> void:
	# En nivel 1 (0:00 - 0:24) salen de 1 en 1; a partir de 0:25 salen en grupos de 2, 3 y hasta 4
	var refuerzos := mini(nivel_intensidad - 1, max_refuerzos_por_oleada)
	if refuerzos <= 0 or not is_instance_valid(spawner_enemigos) or not is_instance_valid(enemigo_base):
		return

	var escena: PackedScene = spawner_enemigos.get("escena_enemigo")
	var tope: int = spawner_enemigos.get("max_enemigos") if "max_enemigos" in spawner_enemigos else 30
	if escena == null:
		return

	for i in range(refuerzos):
		if get_tree().get_nodes_in_group("enemigos").size() >= tope:
			break

		var clon := escena.instantiate() as Node3D
		if clon == null:
			continue

		spawner_enemigos.add_child(clon)
		var offset := Vector3(randf_range(-7.0, 7.0), randf_range(-2.0, 2.0), randf_range(-7.0, 7.0))
		clon.global_position = enemigo_base.global_position + offset

		if clon.has_method("establecer_objetivo") and is_instance_valid(_jugador):
			clon.establecer_objetivo(_jugador)


func _emitir_tiempo() -> void:
	if EventosJuego:
		EventosJuego.tiempo_supervivencia_actualizado.emit(tiempo_supervivencia, nivel_intensidad)


func _aplicar_escalado() -> void:
	if not is_instance_valid(spawner_enemigos):
		return

	var paso := nivel_intensidad - 1
	var nuevo_intervalo := maxf(intervalo_minimo, intervalo_inicial - (reduccion_intervalo_por_nivel * paso))
	var nuevo_max := mini(tope_max_enemigos, max_enemigos_inicial + (incremento_max_enemigos * paso))

	if "intervalo_spawn" in spawner_enemigos:
		spawner_enemigos.intervalo_spawn = nuevo_intervalo
	if "max_enemigos" in spawner_enemigos:
		spawner_enemigos.max_enemigos = nuevo_max

	for hijo in spawner_enemigos.get_children():
		if hijo is Timer:
			hijo.wait_time = nuevo_intervalo
			break


func _buscar_spawner(raiz: Node) -> Node3D:
	if raiz == null:
		return null
	if raiz is SpawnEnemigos:
		return raiz as Node3D
	for hijo in raiz.get_children():
		var encontrado := _buscar_spawner(hijo)
		if encontrado != null:
			return encontrado
	return null
