class_name ReservaOrbital
extends Node
## Gestiona la reserva finita de un planeta, el color de su órbita 3D y el bloqueo al agotarse.

@export var regeneracion_por_seg: float = 2.2
@export var espera_antes_regenerar: float = 6.0 # Segundos sin uso antes de volver a recargarse
@export_range(0.1, 0.8) var umbral_reactivacion: float = 0.35

var energia_maxima: float = 220.0
var energia_actual: float = 220.0
var multiplicador_recarga_nave: float = 1.0
var agotado: bool = false

var _timer_espera_regen: float = 0.0
var _reparacion_base: float = 0.0
var _color_base: Color = Color(0.2, 0.92, 1.0, 1.0)
var _material_orbita: StandardMaterial3D = null


func configurar(
	p_energia_max: float,
	p_mult_recarga: float,
	p_reparacion_seg: float,
	p_color_base: Color,
	zona_orbita: Area3D
) -> void:
	energia_maxima = p_energia_max
	energia_actual = p_energia_max
	multiplicador_recarga_nave = p_mult_recarga
	_reparacion_base = p_reparacion_seg
	_color_base = p_color_base

	var malla := _buscar_malla_orbita(zona_orbita)
	if malla == null:
		malla = _buscar_malla_orbita(get_parent())

	if malla:
		var mat := malla.get_active_material(0) as StandardMaterial3D
		if mat:
			_material_orbita = mat.duplicate() as StandardMaterial3D
			malla.material_override = _material_orbita

	_actualizar_visual_orbita()


func _process(delta: float) -> void:
	if _timer_espera_regen > 0.0:
		_timer_espera_regen -= delta
		return

	if energia_actual < energia_maxima:
		energia_actual = minf(energia_maxima, energia_actual + regeneracion_por_seg * delta)
		if agotado and energia_actual >= energia_maxima * umbral_reactivacion:
			agotado = false
			_sincronizar_curacion_planeta()
		_actualizar_visual_orbita()


func extraer_energia(cantidad_solicitada: float) -> float:
	if agotado or energia_actual <= 0.0 or cantidad_solicitada <= 0.0:
		return 0.0

	# Reinicia el enfriamiento cada vez que la nave consume del planeta
	_timer_espera_regen = espera_antes_regenerar

	var demanda := cantidad_solicitada * multiplicador_recarga_nave
	var entregada := minf(energia_actual, demanda)
	energia_actual -= entregada

	if energia_actual <= 0.01:
		energia_actual = 0.0
		agotado = true
		_sincronizar_curacion_planeta()
		if EventosJuego:
			EventosJuego.planeta_agotado.emit(get_parent())

	_actualizar_visual_orbita()
	return entregada


func obtener_porcentaje() -> float:
	return clampf(energia_actual / maxf(energia_maxima, 1.0), 0.0, 1.0)


func obtener_color_estado() -> Color:
	if agotado:
		return Color(0.95, 0.2, 0.2, 0.9) # Rojo: agotado
	var pct := obtener_porcentaje()
	if pct < 0.35:
		return Color(1.0, 0.5, 0.12, 0.9) # Naranja: poca energía restante
	return _color_base.lerp(Color(1.0, 0.65, 0.15, 0.9), (1.0 - pct) * 0.45)


func _sincronizar_curacion_planeta() -> void:
	var planeta := get_parent()
	if planeta and "reparacion_casco_por_seg" in planeta:
		planeta.reparacion_casco_por_seg = 0.0 if agotado else _reparacion_base


func _actualizar_visual_orbita() -> void:
	if _material_orbita == null:
		return
	var col := obtener_color_estado()
	col.a = _material_orbita.albedo_color.a
	_material_orbita.albedo_color = col


func _buscar_malla_orbita(raiz: Node) -> MeshInstance3D:
	if raiz == null:
		return null
	for hijo in raiz.get_children():
		if hijo is MeshInstance3D:
			return hijo as MeshInstance3D
	return null
