class_name CapsulaRecurso
extends Node3D
## Cápsula magnética que restaura casco o energía de propulsor al recogerla.

enum TipoRecurso { REPARACION_CASCO, ENERGIA_PROPULSOR }

@export var tipo_recurso: TipoRecurso = TipoRecurso.REPARACION_CASCO
@export var cantidad: float = 15.0
@export var radio_iman: float = 25.0
@export var velocidad_iman: float = 26.0
@export var distancia_recoleccion: float = 2.6
@export var tiempo_vida: float = 28.0

var _jugador: Node3D = null
var _edad: float = 0.0


func configurar_tipo(nuevo_tipo: TipoRecurso, valor: float) -> void:
	tipo_recurso = nuevo_tipo
	cantidad = valor
	var malla := find_child("*", true, false) as MeshInstance3D
	if malla:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 1.0, 0.45, 1.0) if tipo_recurso == TipoRecurso.REPARACION_CASCO else Color(0.2, 0.9, 1.0, 1.0)
		malla.material_override = mat


func _physics_process(delta: float) -> void:
	_edad += delta
	if _edad >= tiempo_vida:
		queue_free()
		return

	rotate_y(2.2 * delta)

	if not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("jugador") as Node3D
		if _jugador == null:
			return

	var dist := global_position.distance_to(_jugador.global_position)
	if dist <= distancia_recoleccion:
		_aplicar_beneficio()
		queue_free()
	elif dist <= radio_iman:
		global_position = global_position.move_toward(_jugador.global_position, velocidad_iman * delta)


func _aplicar_beneficio() -> void:
	if tipo_recurso == TipoRecurso.REPARACION_CASCO:
		if _jugador.has_method("curar"):
			_jugador.curar(cantidad)
	else:
		if "energia_actual" in _jugador and "energia_maxima" in _jugador:
			_jugador.energia_actual = minf(_jugador.energia_maxima, _jugador.energia_actual + cantidad)
