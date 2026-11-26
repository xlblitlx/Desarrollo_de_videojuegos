class_name ControlDisparo
extends Node3D
## Busca el enemigo más cercano y dispara automáticamente (estilo Vampire Survivors).

signal disparo_realizado(destino: Node3D)

@export var jugador: CharacterBody3D
@export var contenedor_proyectiles: Node3D
@export var escena_proyectil: PackedScene = preload("res://escenas/proyectil.tscn")
@export var intervalo: float = 0.85
@export var alcance: float = 30.0
@export var dano: float = 5.0
@export var altura_salida: float = 0.2
@export var cantidad_proyectiles: int = 1
@export var angulo_abanico_grados: float = 12.0

var _espera: float = 0.0
var _objetivo_fijado: Node3D = null
var _marcador_prioridad: Label3D = null


func _ready() -> void:
	if jugador == null:
		jugador = get_parent() as CharacterBody3D
	if contenedor_proyectiles == null:
		contenedor_proyectiles = get_tree().current_scene
	_crear_marcador_unico()


func _crear_marcador_unico() -> void:
	_marcador_prioridad = Label3D.new()
	_marcador_prioridad.text = "▼ OBJETIVO ▼"
	_marcador_prioridad.font_size = 26
	_marcador_prioridad.outline_size = 8
	_marcador_prioridad.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	_marcador_prioridad.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_marcador_prioridad.shaded = false
	_marcador_prioridad.fixed_size = true
	_marcador_prioridad.pixel_size = 0.0014
	_marcador_prioridad.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marcador_prioridad.no_depth_test = true
	_marcador_prioridad.visible = false
	if contenedor_proyectiles:
		contenedor_proyectiles.add_child.call_deferred(_marcador_prioridad)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if get_tree().paused:
			return
		_alternar_fijado_asteroide()


func _physics_process(delta: float) -> void:
	if jugador == null or contenedor_proyectiles == null or escena_proyectil == null:
		return

	var objetivo := _encontrar_objetivo()
	_actualizar_marcador(objetivo)

	_espera = maxf(0.0, _espera - delta)
	if _espera > 0.0 or objetivo == null:
		return

	_disparar(objetivo)
	_espera = maxf(intervalo, 0.05)


func _actualizar_marcador(objetivo: Node3D) -> void:
	if _marcador_prioridad == null:
		return

	var es_especial := is_instance_valid(objetivo) and objetivo.is_in_group("asteroides_objetivo")
	var es_fijado_manual := is_instance_valid(_objetivo_fijado) and objetivo == _objetivo_fijado

	if es_especial or es_fijado_manual:
		_marcador_prioridad.visible = true
		var radio_visual := maxf(objetivo.scale.y, 1.5)
		var flotacion := sin(Time.get_ticks_msec() * 0.008) * 0.5
		_marcador_prioridad.global_position = objetivo.global_position + Vector3.UP * (radio_visual * 1.35 + flotacion)

		if "tipo" in objetivo:
			match objetivo.tipo:
				Asteroide.TipoAsteroide.VOLATIL:
					_marcador_prioridad.text = "▼ DETONAR ▼"
					_marcador_prioridad.modulate = Color(1.0, 0.95, 0.3)
				Asteroide.TipoAsteroide.MINERAL:
					_marcador_prioridad.text = "▼ MINERAL ▼"
					_marcador_prioridad.modulate = Color(0.35, 1.0, 0.85)
				_:
					_marcador_prioridad.text = "▼ CURACIÓN ▼"
					_marcador_prioridad.modulate = Color(0.45, 1.0, 0.55)
	else:
		_marcador_prioridad.visible = false


func _encontrar_objetivo() -> Node3D:
	# 1. Prioridad absoluta: asteroide fijado con clic derecho
	if is_instance_valid(_objetivo_fijado) and not _objetivo_fijado.is_queued_for_deletion():
		if jugador.global_position.distance_squared_to(_objetivo_fijado.global_position) <= (alcance * 1.4) * (alcance * 1.4):
			return _objetivo_fijado
	_objetivo_fijado = null

	# 2. Enemigo más cercano
	var enemigo := _buscar_mas_cercano("enemigos")
	if enemigo != null:
		return enemigo

	# 3. Asteroides rojos o dorados
	var especial := _buscar_mas_cercano("asteroides_objetivo")
	if especial != null:
		return especial

	# 4. Asteroides grises (sueltan cápsulas de vida)
	return _buscar_mas_cercano("asteroides_comunes")


func _buscar_mas_cercano(grupo: String) -> Node3D:
	var objetivo: Node3D = null
	var distancia_minima := alcance * alcance

	for nodo in get_tree().get_nodes_in_group(grupo):
		if not nodo is Node3D or nodo.is_queued_for_deletion():
			continue
		var candidato := nodo as Node3D
		var distancia := jugador.global_position.distance_squared_to(candidato.global_position)
		if distancia < distancia_minima:
			objetivo = candidato
			distancia_minima = distancia

	return objetivo


func _alternar_fijado_asteroide() -> void:
	var anterior := _objetivo_fijado
	_objetivo_fijado = null

	var candidato := _buscar_asteroide_en_mira()
	if candidato != null and candidato != anterior:
		_objetivo_fijado = candidato


func _buscar_asteroide_en_mira() -> Node3D:
	var cam := get_viewport().get_camera_3d()
	if cam == null or jugador == null:
		return null

	var centro_pantalla := get_viewport().get_visible_rect().size * 0.5
	var mejor: Node3D = null
	var menor_dist_mira: float = 160.0
	var rango_max_sq := (alcance * 1.4) * (alcance * 1.4)

	var candidatos: Array[Node] = []
	candidatos.append_array(get_tree().get_nodes_in_group("asteroides_objetivo"))
	candidatos.append_array(get_tree().get_nodes_in_group("asteroides_comunes"))

	for nodo in candidatos:
		var ast := nodo as Node3D
		if not is_instance_valid(ast) or ast.is_queued_for_deletion():
			continue
		if cam.is_position_behind(ast.global_position):
			continue
		if jugador.global_position.distance_squared_to(ast.global_position) > rango_max_sq:
			continue

		var dist_mira := cam.unproject_position(ast.global_position).distance_to(centro_pantalla)
		if dist_mira < menor_dist_mira:
			menor_dist_mira = dist_mira
			mejor = ast

	return mejor


func _disparar(destino: Node3D) -> void:
	var origen := jugador.global_position + Vector3.UP * altura_salida
	var dir_base := (destino.global_position - origen).normalized()
	if dir_base == Vector3.ZERO:
		return

	var total := maxi(1, cantidad_proyectiles)
	var paso_rad := deg_to_rad(angulo_abanico_grados)
	var angulo_inicial := -paso_rad * float(total - 1) * 0.5

	for i in range(total):
		var proyectil := escena_proyectil.instantiate() as Proyectil
		if proyectil == null:
			continue

		var rotacion := angulo_inicial + paso_rad * float(i)
		var dir_final := dir_base.rotated(Vector3.UP, rotacion).normalized()

		proyectil.configurar(dir_final, dano)
		contenedor_proyectiles.add_child(proyectil)
		proyectil.global_position = origen + dir_final * 1.4

	disparo_realizado.emit(destino)
