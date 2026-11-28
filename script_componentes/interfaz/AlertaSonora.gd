class_name AlertaSonora
extends Node
## Módulo de audio dedicado a la sirena de emergencia de cabina ("wiu-wiu").

@export var sonido_personalizado: AudioStream = null # Opcional: asigna un .ogg/.wav propio
@export_range(-40.0, 0.0) var volumen_db: float = -18.0
@export_range(0.5, 3.0) var velocidad: float = 1.15 # Ciclos por segundo

var _reproductor: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _fase: float = 0.0
var _tiempo: float = 0.0


func _ready() -> void:
	_reproductor = AudioStreamPlayer.new()
	_reproductor.bus = "Master"
	_reproductor.volume_db = volumen_db

	if sonido_personalizado != null:
		_reproductor.stream = sonido_personalizado
	else:
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = 22050.0
		gen.buffer_length = 0.1
		_reproductor.stream = gen

	add_child(_reproductor)


func actualizar_sirena(activa: bool) -> void:
	if not is_instance_valid(_reproductor):
		return

	_reproductor.volume_db = volumen_db

	if not activa:
		if _reproductor.playing:
			_reproductor.stop()
		_playback = null
		_tiempo = 0.0
		return

	if not _reproductor.playing:
		_reproductor.play()
		if sonido_personalizado == null:
			_playback = _reproductor.get_stream_playback() as AudioStreamGeneratorPlayback

	if sonido_personalizado == null and _playback != null:
		var mix_rate := 22050.0
		var frames_disponibles := _playback.get_frames_available()
		for i in frames_disponibles:
			_tiempo += 1.0 / mix_rate
			var onda := sin(_tiempo * TAU * velocidad)
			var modulacion := 0.5 + 0.5 * onda
			var freq := lerpf(330.0, 540.0, modulacion)
			_fase = fmod(_fase + (freq / mix_rate), 1.0)
			var envolvente := lerpf(0.12, 0.26, modulacion)
			var muestra := sin(_fase * TAU) * envolvente
			_playback.push_frame(Vector2(muestra, muestra))
