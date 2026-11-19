class_name GestorPartida
extends Node

signal bajas_cambiadas(total: int)
signal partida_finalizada(estadisticas: Dictionary, victoria: bool)

@export var pantalla_final: PantallaGameOver
@export var hud_bajas: HudBajas
## Segundos que hay que sobrevivir para ganar. 0 = sin victoria (modo infinito).
@export var duracion_victoria: float = 300.0
@export_file("*.tscn") var escena_menu: String = "res://escenas/menu_principal.tscn"

var bajas: int = 0
var nivel_alcanzado: int = 1
var tiempo_supervivencia: float = 0.0
var oleada_actual: int = 1

var _terminada: bool = false


func _ready() -> void:
	add_to_group("gestor_partida")

	if pantalla_final == null:
		pantalla_final = find_child("PantallaGameOver", true, false) as PantallaGameOver
	if hud_bajas == null:
		hud_bajas = find_child("HudBajas", true, false) as HudBajas

	if pantalla_final:
		pantalla_final.reinicio_solicitado.connect(_reiniciar_partida)
		pantalla_final.menu_solicitado.connect(_volver_al_menu)
	else:
		push_warning("GestorPartida: no encontró PantallaGameOver.")

	if hud_bajas:
		bajas_cambiadas.connect(hud_bajas.actualizar_bajas)
		hud_bajas.actualizar_bajas(bajas)

	if EventosJuego:
		EventosJuego.partida_terminada.connect(_al_terminar_partida)
		EventosJuego.tiempo_supervivencia_actualizado.connect(_al_actualizar_tiempo)

	get_tree().node_added.connect(_al_agregar_nodo)
	call_deferred("_registrar_enemigos_existentes")
	call_deferred("_conectar_experiencia")


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_al_agregar_nodo):
		get_tree().node_added.disconnect(_al_agregar_nodo)
	if EventosJuego:
		if EventosJuego.partida_terminada.is_connected(_al_terminar_partida):
			EventosJuego.partida_terminada.disconnect(_al_terminar_partida)
		if EventosJuego.tiempo_supervivencia_actualizado.is_connected(_al_actualizar_tiempo):
			EventosJuego.tiempo_supervivencia_actualizado.disconnect(_al_actualizar_tiempo)


# --- Bajas -----------------------------------------------------------------

func _registrar_enemigos_existentes() -> void:
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		_escuchar_enemigo(enemigo)


func _al_agregar_nodo(nodo: Node) -> void:
	_escuchar_enemigo(nodo)


func _escuchar_enemigo(nodo: Node) -> void:
	# Contrato: todo enemigo está en el grupo "enemigos" y emite destruido(posicion)
	if not nodo.is_in_group("enemigos") or not nodo.has_signal("destruido"):
		return
	var escuchar := Callable(self, "_al_destruir_enemigo")
	if not nodo.is_connected("destruido", escuchar):
		nodo.connect("destruido", escuchar)


func _al_destruir_enemigo(_posicion: Vector3) -> void:
	if _terminada:
		return
	bajas += 1
	bajas_cambiadas.emit(bajas)


# --- Nivel y tiempo --------------------------------------------------------

func _conectar_experiencia() -> void:
	var gestor := get_tree().get_first_node_in_group("gestor_experiencia") as GestorExperiencia
	if gestor == null:
		push_warning("GestorPartida: no hay GestorExperiencia; el nivel final será 1.")
		return
	nivel_alcanzado = gestor.nivel_actual
	gestor.subio_nivel.connect(_al_subir_nivel)


func _al_subir_nivel(nivel: int) -> void:
	nivel_alcanzado = nivel


func _al_actualizar_tiempo(segundos_totales: float, nivel_intensidad: int) -> void:
	tiempo_supervivencia = segundos_totales
	oleada_actual = nivel_intensidad
	if duracion_victoria > 0.0 and segundos_totales >= duracion_victoria:
		_cerrar_partida({}, true)


# --- Fin de partida --------------------------------------------------------

func _al_terminar_partida(estadisticas: Dictionary) -> void:
	# Lo emite Jugador cuando su vida llega a 0 (y luego pausa el árbol)
	_cerrar_partida(estadisticas, false)


func _cerrar_partida(base: Dictionary, victoria: bool) -> void:
	if _terminada:
		return
	_terminada = true

	var resumen := {
		"tiempo": float(base.get("tiempo", tiempo_supervivencia)),
		"oleada": int(base.get("oleada", oleada_actual)),
		"nivel": nivel_alcanzado,
		"bajas": bajas,
	}

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	if pantalla_final:
		pantalla_final.mostrar(resumen, victoria)
	partida_finalizada.emit(resumen, victoria)


func _reiniciar_partida() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _volver_al_menu() -> void:
	get_tree().paused = false
	if escena_menu.is_empty():
		push_error("GestorPartida: escena_menu está vacía.")
		return
	get_tree().change_scene_to_file(escena_menu)
