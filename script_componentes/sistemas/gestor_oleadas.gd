class_name GestorOleadas
extends Node
## Controla las oleadas por bajas reales, reparte equitativamente los tipos de enemigos e invoca al jefe por oleada.

@export var spawner_enemigos: Node3D
## Arrastra aquí todas tus escenas de enemigos (.tscn) para que salgan de forma equitativa.
@export var escenas_enemigos: Array[PackedScene] = []

@export_group("Progresión de Oleadas")
@export var bajas_oleada_1: int = 8
@export var incremento_bajas_por_oleada: int = 6
@export var intervalo_inicial: float = 2.6
@export var intervalo_minimo: float = 0.9
@export var reduccion_intervalo_por_oleada: float = 0.35
@export var max_enemigos_simultaneos: int = 24
@export var max_refuerzos_por_grupo: int = 2 # Máximo +2 refuerzos por aparición (grupos de hasta 3)

@export_group("Jefe Orbital")
@export var escena_jefe: PackedScene = preload("res://escenas/jefe_orbital.tscn")
@export var oleada_aparicion_jefe: int = 4 # Aparece al llegar a esta oleada
@export var pausar_oleadas_con_jefe: bool = true
@export var modo_solo_jefe: bool = false

var tiempo_supervivencia: float = 0.0
var nivel_intensidad: int = 1 # Representa la oleada actual
var bajas_en_oleada: int = 0
var bajas_necesarias: int = 8

var _ultimo_segundo_emitido: int = -1
var _jugador: Node3D = null
var _bolsa_enemigos: Array[PackedScene] = []
var _jefe_invocado: bool = false
var _jefe_activo: Node3D = null


func _ready() -> void:
	await get_tree().process_frame
	_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
	bajas_necesarias = bajas_oleada_1

	if spawner_enemigos == null:
		spawner_enemigos = _buscar_spawner(get_tree().current_scene)

	# Si no asignaste escenas en el Inspector, toma la del spawner por defecto
	if escenas_enemigos.is_empty() and is_instance_valid(spawner_enemigos):
		var base: PackedScene = spawner_enemigos.get("escena_enemigo")
		if base != null:
			escenas_enemigos.append(base)

	if is_instance_valid(spawner_enemigos):
		if spawner_enemigos.has_signal("enemigo_generado"):
			spawner_enemigos.enemigo_generado.connect(_al_generar_enemigo_base)
	else:
		push_warning("GestorOleadas: no encontró a SpawnEnemigos en la escena.")

	# Escucha enemigos existentes y nuevos para contar las bajas de la oleada
	get_tree().node_added.connect(_al_agregar_nodo)
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		_conectar_enemigo(enemigo)

	_aplicar_escalado()
	_emitir_tiempo()
	if EventosJuego:
		EventosJuego.oleada_cambiada.emit(nivel_intensidad)

	if modo_solo_jefe:
		if is_instance_valid(spawner_enemigos):
			for hijo in spawner_enemigos.get_children():
				if hijo is Timer:
					hijo.stop()
		invocar_jefe()


func _process(delta: float) -> void:
	tiempo_supervivencia += delta

	var segundo_actual := int(tiempo_supervivencia)
	if segundo_actual != _ultimo_segundo_emitido:
		_ultimo_segundo_emitido = segundo_actual
		_emitir_tiempo()


# --- Conteo de bajas y avance de oleada ------------------------------------

func _al_agregar_nodo(nodo: Node) -> void:
	_conectar_enemigo(nodo)


func _conectar_enemigo(nodo: Node) -> void:
	if not nodo.is_in_group("enemigos") or nodo.is_in_group("jefe"):
		return
	if nodo.has_signal("destruido"):
		var cb := Callable(self, "_al_destruir_enemigo")
		if not nodo.is_connected("destruido", cb):
			nodo.connect("destruido", cb)


func _al_destruir_enemigo(_posicion: Vector3) -> void:
	if is_instance_valid(_jefe_activo):
		return

	bajas_en_oleada += 1
	if bajas_en_oleada >= bajas_necesarias:
		_subir_oleada()


func _subir_oleada() -> void:
	nivel_intensidad += 1
	bajas_en_oleada = 0
	bajas_necesarias = bajas_oleada_1 + (incremento_bajas_por_oleada * (nivel_intensidad - 1))

	_aplicar_escalado()
	if EventosJuego:
		EventosJuego.oleada_cambiada.emit(nivel_intensidad)

	if not _jefe_invocado and nivel_intensidad >= oleada_aparicion_jefe:
		invocar_jefe()


# --- Spawn equitativo (Shuffle Bag) ----------------------------------------

func _siguiente_escena_equitativa() -> PackedScene:
	if escenas_enemigos.is_empty():
		return null
	if _bolsa_enemigos.is_empty():
		_bolsa_enemigos = escenas_enemigos.duplicate()
		_bolsa_enemigos.shuffle()
	return _bolsa_enemigos.pop_back()


func _al_generar_enemigo_base(enemigo_base: Node3D) -> void:
	if not is_instance_valid(spawner_enemigos) or not is_instance_valid(enemigo_base):
		return

	# Si tenemos varias escenas, reemplaza el enemigo base por uno equitativo de la bolsa
	if escenas_enemigos.size() > 1:
		var escena_equitativa := _siguiente_escena_equitativa()
		if escena_equitativa != null and escena_equitativa.resource_path != enemigo_base.scene_file_path:
			var pos := enemigo_base.global_position
			enemigo_base.queue_free()
			_instanciar_enemigo(escena_equitativa, pos)

	# Refuerzos en grupo limitados para evitar acumulaciones gigantes
	var refuerzos := mini(nivel_intensidad - 1, max_refuerzos_por_grupo)
	for i in range(refuerzos):
		if get_tree().get_nodes_in_group("enemigos").size() >= max_enemigos_simultaneos:
			break
		var escena := _siguiente_escena_equitativa()
		if escena == null:
			break
		var offset := Vector3(randf_range(-8.0, 8.0), randf_range(-2.5, 2.5), randf_range(-8.0, 8.0))
		_instanciar_enemigo(escena, enemigo_base.global_position + offset)


func _instanciar_enemigo(escena: PackedScene, posicion: Vector3) -> void:
	var clon := escena.instantiate() as Node3D
	if clon == null:
		return
	spawner_enemigos.add_child(clon)
	clon.global_position = posicion
	if clon.has_method("establecer_objetivo") and is_instance_valid(_jugador):
		clon.establecer_objetivo(_jugador)


# --- Jefe Orbital ----------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J:
		invocar_jefe()


func invocar_jefe() -> void:
	if _jefe_invocado or escena_jefe == null:
		return
	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		if _jugador == null:
			return

	_jefe_invocado = true
	var jefe := escena_jefe.instantiate() as Node3D
	get_tree().current_scene.add_child(jefe)
	_jefe_activo = jefe

	var angulo := randf() * TAU
	jefe.global_position = _jugador.global_position + Vector3(cos(angulo), 0.0, sin(angulo)) * 55.0

	if jefe.has_signal("destruido"):
		jefe.destruido.connect(_al_derrotar_jefe)

	if pausar_oleadas_con_jefe and is_instance_valid(spawner_enemigos):
		for hijo in spawner_enemigos.get_children():
			if hijo is Timer:
				hijo.stop()


func _al_derrotar_jefe(posicion: Vector3) -> void:
	_jefe_activo = null

	if pausar_oleadas_con_jefe and is_instance_valid(spawner_enemigos):
		_aplicar_escalado()
		for hijo in spawner_enemigos.get_children():
			if hijo is Timer:
				hijo.start()

	var gestor_exp := get_tree().get_first_node_in_group("gestor_recompensas")
	if gestor_exp and gestor_exp.has_method("crear_orbe"):
		for i in range(12):
			var disperso := Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))
			gestor_exp.crear_orbe(posicion + disperso)


# --- Utilidades ------------------------------------------------------------

func _emitir_tiempo() -> void:
	if EventosJuego:
		EventosJuego.tiempo_supervivencia_actualizado.emit(tiempo_supervivencia, nivel_intensidad)


func _aplicar_escalado() -> void:
	if not is_instance_valid(spawner_enemigos):
		return

	var paso := nivel_intensidad - 1
	var nuevo_intervalo := maxf(intervalo_minimo, intervalo_inicial - (reduccion_intervalo_por_oleada * paso))

	if "intervalo_spawn" in spawner_enemigos:
		spawner_enemigos.intervalo_spawn = nuevo_intervalo
	if "max_enemigos" in spawner_enemigos:
		spawner_enemigos.max_enemigos = max_enemigos_simultaneos

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
