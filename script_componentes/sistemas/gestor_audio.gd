class_name GestorAudio
extends Node
## Reproductor de SFX desacoplado usando clips .ogg / .wav del proyecto.

@export_group("Clips de Audio (.ogg / .wav)")
@export var sfx_disparo: AudioStream
@export var sfx_explosion: AudioStream
@export var sfx_nivel: AudioStream
@export var sfx_planeta_agotado: AudioStream

@export_group("Volumen (dB)")
@export var volumen_disparo_db: float = -12.0
@export var volumen_general_db: float = -6.0

var _pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

	if EventosJuego:
		if EventosJuego.has_signal("enemigo_eliminado"):
			EventosJuego.enemigo_eliminado.connect(func(_pos): reproducir_explosion())
		if EventosJuego.has_signal("partida_terminada"):
			EventosJuego.partida_terminada.connect(func(_stats): reproducir_explosion())
		if EventosJuego.has_signal("jugador_destruido"):
			EventosJuego.jugador_destruido.connect(func(_t): reproducir_explosion())
		if EventosJuego.has_signal("planeta_agotado"):
			EventosJuego.planeta_agotado.connect(func(_p): reproducir_alerta())

	await get_tree().process_frame

	var exp_node := get_tree().get_first_node_in_group("gestor_experiencia")
	if exp_node and exp_node.has_signal("subio_nivel"):
		exp_node.subio_nivel.connect(func(_lvl): reproducir_nivel())

	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador:
		var disparo := jugador.find_child("ControlDisparo", true, false)
		if disparo and disparo.has_signal("disparo_realizado"):
			disparo.disparo_realizado.connect(func(_destino): reproducir_disparo())


func reproducir_disparo() -> void:
	_reproducir(sfx_disparo, volumen_disparo_db, 0.94, 1.08)


func reproducir_explosion() -> void:
	_reproducir(sfx_explosion, volumen_general_db, 0.88, 1.12)


func reproducir_nivel() -> void:
	_reproducir(sfx_nivel, volumen_general_db, 1.0, 1.0)


func reproducir_alerta() -> void:
	_reproducir(sfx_planeta_agotado, volumen_general_db, 0.95, 1.05)


func _reproducir(stream: AudioStream, vol_db: float, pitch_min: float, pitch_max: float) -> void:
	if stream == null:
		return
	var player := _obtener_libre()
	player.stream = stream
	player.volume_db = vol_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()


func _obtener_libre() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	return _pool[0]
