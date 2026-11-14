class_name Planeta
extends Node3D
## Entidad planetaria: define tipo procedural, gravedad escalada y registro de órbita.

enum TipoPlaneta { ESTANDAR, ENERGETICO, DENSO }

@onready var zona_orbita: Area3D = $ZonaOrbita
@onready var reserva_orbital: ReservaOrbital = get_node_or_null("ReservaOrbital")

@export_group("Configuración Procedural")
@export var tipo_aleatorio_al_iniciar: bool = true
@export var tipo_planeta: TipoPlaneta = TipoPlaneta.ESTANDAR

@export_group("Gravedad Orbital")
@export var fuerza_gravedad: float = 65.0
@export var radio_nucleo_seguro: float = 16.0
@export var radio_orbita_referencia: float = 45.0
@export var multiplicador_escape: float = 2.1
@export var tiempo_escape_base: float = 1.8

var reparacion_casco_por_seg: float = 0.0


func _ready() -> void:
	add_to_group("planetas")
	_ajustar_colision_nucleo()

	if zona_orbita:
		zona_orbita.body_entered.connect(_on_body_entered)
		zona_orbita.body_exited.connect(_on_body_exited)

	if tipo_aleatorio_al_iniciar:
		var dado := randf()
		if dado < 0.50:
			tipo_planeta = TipoPlaneta.ESTANDAR
		elif dado < 0.80:
			tipo_planeta = TipoPlaneta.ENERGETICO
		else:
			tipo_planeta = TipoPlaneta.DENSO

	_inicializar_tipo()


func _inicializar_tipo() -> void:
	var energia_max := 340.0
	var mult_recarga := 1.0
	var color_base := Color(0.2, 0.92, 1.0, 1.0)

	match tipo_planeta:
		TipoPlaneta.ESTANDAR:
			energia_max = 220.0 # ~3.4 recargas completas
			mult_recarga = 1.0
			reparacion_casco_por_seg = 0.0
			fuerza_gravedad = 65.0
			tiempo_escape_base = 1.8
			color_base = Color(0.2, 0.92, 1.0, 1.0) # Cian: energía estándar
		TipoPlaneta.ENERGETICO:
			energia_max = 160.0 # ~2.6 recargas ultrarrápidas
			mult_recarga = 1.8
			reparacion_casco_por_seg = 0.0
			fuerza_gravedad = 48.0
			tiempo_escape_base = 1.2
			color_base = Color(1.0, 0.8, 0.2, 1.0) # Ámbar: recarga rápida
		TipoPlaneta.DENSO:
			energia_max = 240.0 # Gran reserva + reparación de casco
			mult_recarga = 0.85
			reparacion_casco_por_seg = 2.5
			fuerza_gravedad = 82.0
			tiempo_escape_base = 2.4
			color_base = Color(0.2, 1.0, 0.45, 1.0) # Verde: repara casco

	if reserva_orbital:
		reserva_orbital.configurar(energia_max, mult_recarga, reparacion_casco_por_seg, color_base, zona_orbita)

func extraer_energia_orbital(cantidad: float) -> float:
	return reserva_orbital.extraer_energia(cantidad) if reserva_orbital else cantidad


func obtener_porcentaje_carga() -> float:
	return reserva_orbital.obtener_porcentaje() if reserva_orbital else 1.0


func obtener_color_estado() -> Color:
	return reserva_orbital.obtener_color_estado() if reserva_orbital else Color(0.2, 0.92, 1.0, 1.0)


func calcular_atraccion_sobre(pos_nave: Vector3, vel_nave: Vector3, impulso_escape: float = 0.0) -> Vector3:
	var hacia_centro := global_position - pos_nave
	var distancia := hacia_centro.length()

	var escala_planeta := scale.x
	var nucleo_real := radio_nucleo_seguro * escala_planeta
	var orbita_real := radio_orbita_referencia * escala_planeta

	if distancia <= nucleo_real or distancia < 0.01:
		return Vector3.ZERO

	var dir_centro := hacia_centro / distancia
	var factor_cercania := clampf(1.0 - ((distancia - nucleo_real) / maxf(orbita_real - nucleo_real, 1.0)), 0.0, 1.0)
	var fuerza := fuerza_gravedad * (1.0 + factor_cercania * 0.85)

	if vel_nave.dot(dir_centro) < 0.0:
		var resistencia := lerpf(multiplicador_escape, 0.45, clampf(impulso_escape, 0.0, 1.0))
		fuerza *= resistencia

	return dir_centro * fuerza


func _ajustar_colision_nucleo() -> void:
	var colision := get_node_or_null("CuerpoSolido/CollisionShape3D") as CollisionShape3D
	var malla := find_child("*", true, false) as MeshInstance3D
	if colision and colision.shape is SphereShape3D and malla and malla.mesh:
		colision.shape.radius = malla.get_aabb().size.x * 0.5 * malla.scale.x


func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		var gestor := body.find_child("GestorOrbita", true, false) as GestorOrbita
		if gestor:
			gestor.registrar_planeta_entrante(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Jugador:
		var gestor := body.find_child("GestorOrbita", true, false) as GestorOrbita
		if gestor:
			gestor.registrar_planeta_saliente(self)
