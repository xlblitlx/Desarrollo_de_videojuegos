class_name LuzJugador
extends OmniLight3D
## Luz reactiva de la nave: apagada en reposo y lanza un pulso dorado al subir de nivel.

@export var gestor_experiencia: GestorExperiencia
@export var luz_aura: OmniLight3D
@export var energia_base: float = 0.0 # En 0.0 para no manchar el cubo en reposo

var _destello: float = 0.0
var _progreso_actual: float = 0.0


func _ready() -> void:
	light_color = Color("#FFCB50") # Dorado brillante para el destello de nivel
	light_energy = energia_base
	omni_range = 12.0
	shadow_enabled = false

	if luz_aura == null:
		luz_aura = get_node_or_null("LuzAura") as OmniLight3D
	if luz_aura:
		luz_aura.light_color = Color("#38B6FF")
		luz_aura.omni_range = 8.0
		luz_aura.shadow_enabled = false

	# Espera un frame para garantizar que GestorExperiencia ya esté registrado en el árbol
	await get_tree().process_frame
	if gestor_experiencia == null:
		gestor_experiencia = get_tree().get_first_node_in_group("gestor_experiencia") as GestorExperiencia

	if gestor_experiencia:
		gestor_experiencia.experiencia_actualizada.connect(_al_actualizar_exp)
		gestor_experiencia.subio_nivel.connect(_al_subir_nivel)
	else:
		push_warning("LuzNave: no encontró al nodo en el grupo 'gestor_experiencia'")


func _process(delta: float) -> void:
	if _destello > 0.0:
		_destello = maxf(0.0, _destello - delta * 1.4)
		# Pulso fuerte de energía y expansión de radio
		light_energy = _destello * 8.0
		omni_range = lerpf(4.0, 22.0, _destello)
	else:
		light_energy = energia_base

	if luz_aura:
		luz_aura.light_energy = lerpf(0.0, 1.5, _progreso_actual) + _destello * 4.0


func _al_actualizar_exp(total: int, nivel: int) -> void:
	var inicio := GestorExperiencia.umbral_nivel(nivel)
	var siguiente := GestorExperiencia.umbral_nivel(nivel + 1)
	_progreso_actual = clampf(float(total - inicio) / float(max(1, siguiente - inicio)), 0.0, 1.0)


func _al_subir_nivel(_nivel: int) -> void:
	_destello = 1.0
