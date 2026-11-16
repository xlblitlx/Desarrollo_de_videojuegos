class_name ModeloNave
extends Node3D
## Visual de una nave (FBX). Se usa tanto para el jugador (azul) como para los enemigos (rojo).
## Auto-escala el modelo, lo orienta, recolorea el neón, añade luces y una estela de propulsión.
## NO toca la lógica del juego: el CharacterBody3D, sus colisiones y scripts siguen igual.

const Util = preload("res://script_componentes/utilidades/util_modelos.gd")

const SHADER_ESTELA := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.25, 0.05, 1.0);
uniform float intensity = 1.0;
uniform float cone_length = 4.0;
uniform float scroll_speed = 7.0;

varying float v_along;
varying float v_ang;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	v_along = clamp(0.5 - VERTEX.y / cone_length, 0.0, 1.0);
	v_ang = atan(VERTEX.x, VERTEX.z);
}

void fragment() {
	float s1 = vnoise(vec2(v_ang * 3.0, v_along * 6.0 - TIME * scroll_speed));
	float s2 = vnoise(vec2(v_ang * 7.0, v_along * 14.0 - TIME * scroll_speed * 1.7));
	float streak = s1 * 0.6 + s2 * 0.4;
	float fade = pow(1.0 - v_along, 1.4);
	float core = pow(1.0 - v_along, 4.0);
	vec3 col = mix(edge_color.rgb, core_color.rgb, core);
	ALBEDO = col * (0.5 + streak * 1.2) * (0.6 + fade * 2.0) * intensity;
	ALPHA = clamp(fade * (0.3 + streak) * intensity, 0.0, 1.0);
}
"""

@export_group("Modelo")
## Largo deseado de la nave en unidades de Godot (el FBX se escala solo).
@export var largo: float = 3.0
## Giro en Y (grados). El morro del FBX apunta a +Z, así que 180 lo deja mirando a -Z (el "frente" en Godot).
## Si ves la nave volando de espaldas, pon 0. Si va de lado, prueba 90 o -90.
@export var giro_y: float = 180.0

@export_group("Neon")
@export var color_neon: Color = Color(0.1, 0.75, 1.0)
@export var color_casco: Color = Color(0.09, 0.11, 0.15)
@export var energia_neon: float = 4.0
@export var luces_neon: bool = true
@export var energia_luces: float = 1.2

@export_group("Propulsion")
@export var estela: bool = true
## true = la estela siempre está encendida (enemigos). false = reacciona al propulsor del Jugador.
@export var estela_siempre_activa: bool = false
@export_range(0.0, 1.0) var nivel_reposo: float = 0.2
@export var longitud_estela: float = 1.6  # en múltiplos del largo de la nave
@export var radio_estela: float = 0.22    # en múltiplos del largo de la nave
@export var color_nucleo: Color = Color(1.0, 0.95, 0.7)
@export var color_borde: Color = Color(1.0, 0.25, 0.05)

var _jugador: Jugador = null
var _pivote_estela: Node3D = null
var _material_estela: ShaderMaterial = null
var _luz_motor: OmniLight3D = null
var _nivel: float = 0.0

@onready var _modelo: Node3D = get_node_or_null("Modelo")


func _ready() -> void:
	if _modelo == null:
		push_warning("ModeloNave: falta el nodo hijo 'Modelo' (instancia del FBX).")
		return

	_limpiar_modelo()
	var caja := _ajustar_modelo()
	_pintar_neon()

	if luces_neon:
		_crear_luces_neon(caja)
	if estela:
		_crear_estela(caja)

	var n: Node = get_parent()
	while n != null:
		if n is Jugador:
			_jugador = n as Jugador
			break
		n = n.get_parent()


func _process(delta: float) -> void:
	if _pivote_estela == null:
		return

	var objetivo := nivel_reposo
	if estela_siempre_activa:
		objetivo = maxf(nivel_reposo, 0.6)
	elif _jugador != null:
		if _jugador.propulsor_activo:
			objetivo = 1.0
		elif _jugador.velocity.length() > 1.0:
			objetivo = 0.45

	_nivel = lerpf(_nivel, objetivo, clampf(6.0 * delta, 0.0, 1.0))
	var ancho := lerpf(0.55, 1.0, _nivel)
	_pivote_estela.scale = Vector3(ancho, ancho, lerpf(0.25, 1.0, _nivel))
	_material_estela.set_shader_parameter("intensity", lerpf(0.5, 1.6, _nivel))
	_luz_motor.light_energy = lerpf(0.4, 3.0, _nivel)


## Quita la cámara y las luces que vienen dentro del FBX (estorbarían a las del juego).
func _limpiar_modelo() -> void:
	for n in _modelo.find_children("*", "Camera3D", true, false):
		n.queue_free()
	for n in _modelo.find_children("*", "Light3D", true, false):
		n.queue_free()


## Escala el modelo a `largo`, lo centra y lo gira. Devuelve su caja (en el espacio de este nodo).
func _ajustar_modelo() -> AABB:
	var rot := Basis.from_euler(Vector3(0.0, deg_to_rad(giro_y), 0.0))
	_modelo.transform = Transform3D(rot, Vector3.ZERO)

	var caja := Util.aabb_relativo(_modelo, self)
	var mayor := maxf(caja.size.x, maxf(caja.size.y, caja.size.z))
	if mayor < 0.0001:
		push_warning("ModeloNave: no se encontraron mallas en el FBX.")
		return AABB()

	var s := largo / mayor
	_modelo.transform = Transform3D(rot.scaled(Vector3.ONE * s), -caja.get_center() * s)
	return Util.aabb_relativo(_modelo, self)


## El FBX ya trae materiales emisivos (franjas de neón). Aquí se recolorean al color de la nave
## y el casco oscuro se aclara un poco para que se vea con la luz del sol.
func _pintar_neon() -> void:
	for mi in Util.meshes_de(_modelo):
		for s in mi.get_surface_override_material_count():
			var m := mi.get_active_material(s)
			if not (m is BaseMaterial3D):
				continue
			var nm := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
			var c := nm.albedo_color
			var brillante := maxf(c.r, maxf(c.g, c.b)) > 0.3
			if nm.emission_enabled or brillante:
				nm.albedo_color = color_neon * 0.35
				nm.emission_enabled = true
				nm.emission = color_neon
				nm.emission_energy_multiplier = energia_neon
			else:
				nm.albedo_color = color_casco
				nm.metallic = 0.6
				nm.roughness = 0.35
			mi.set_surface_override_material(s, nm)


func _crear_luces_neon(caja: AABB) -> void:
	if caja.size == Vector3.ZERO:
		return
	var centro := caja.get_center()
	for lado in [-1.0, 1.0]:
		var luz := OmniLight3D.new()
		luz.name = "LuzNeon" + ("Izq" if lado < 0.0 else "Der")
		luz.light_color = color_neon
		luz.light_energy = energia_luces
		luz.omni_range = largo * 1.2
		luz.shadow_enabled = false
		luz.position = Vector3(centro.x + lado * caja.size.x * 0.35, centro.y, centro.z + caja.size.z * 0.1)
		add_child(luz)


## Estela de propulsión: cono alargado con núcleo blanco-amarillo y vetas rojas/naranjas.
func _crear_estela(caja: AABB) -> void:
	var z_motor := largo * 0.5
	var y_motor := 0.0
	if caja.size != Vector3.ZERO:
		z_motor = caja.end.z
		y_motor = caja.get_center().y

	var largo_cono := largo * longitud_estela
	var cono := CylinderMesh.new()
	cono.top_radius = largo * radio_estela
	cono.bottom_radius = 0.01
	cono.height = largo_cono
	cono.radial_segments = 24
	cono.rings = 1
	cono.cap_top = false
	cono.cap_bottom = false

	var shader := Shader.new()
	shader.code = SHADER_ESTELA
	_material_estela = ShaderMaterial.new()
	_material_estela.shader = shader
	_material_estela.set_shader_parameter("core_color", color_nucleo)
	_material_estela.set_shader_parameter("edge_color", color_borde)
	_material_estela.set_shader_parameter("cone_length", largo_cono)

	_pivote_estela = Node3D.new()
	_pivote_estela.name = "PivoteEstela"
	_pivote_estela.position = Vector3(0.0, y_motor, z_motor)
	add_child(_pivote_estela)

	var malla := MeshInstance3D.new()
	malla.name = "Estela"
	malla.mesh = cono
	malla.material_override = _material_estela
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# El cilindro va a lo largo de Y; se gira para que el extremo ancho quede en la boquilla
	# y la punta se extienda hacia atrás (+Z).
	malla.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	malla.position = Vector3(0.0, 0.0, largo_cono * 0.5)
	_pivote_estela.add_child(malla)

	_luz_motor = OmniLight3D.new()
	_luz_motor.name = "LuzMotor"
	_luz_motor.light_color = color_borde.lerp(color_nucleo, 0.4)
	_luz_motor.light_energy = 0.4
	_luz_motor.omni_range = largo * 2.5
	_luz_motor.shadow_enabled = false
	_pivote_estela.add_child(_luz_motor)
