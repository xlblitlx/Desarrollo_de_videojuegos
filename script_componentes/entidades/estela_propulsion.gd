class_name EstelaPropulsion
extends Node3D

const CODIGO_SHADER := """
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
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
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

var _material: ShaderMaterial
var _luz: OmniLight3D
var _nivel: float = 0.0
var _siempre_activa: bool = false
var _reposo: float = 0.2
var _cuerpo: CharacterBody3D


func configurar(largo_nave: float, longitud_mult: float, radio_mult: float, nucleo: Color, borde: Color, fija: bool, reposo: float) -> void:
	_siempre_activa = fija
	_reposo = reposo
	_cuerpo = _buscar_cuerpo_padre()

	var largo_cono := largo_nave * longitud_mult
	var cono := CylinderMesh.new()
	cono.top_radius = largo_nave * radio_mult
	cono.bottom_radius = 0.01
	cono.height = largo_cono
	cono.radial_segments = 20
	cono.cap_top = false
	cono.cap_bottom = false

	var shader := Shader.new()
	shader.code = CODIGO_SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("core_color", nucleo)
	_material.set_shader_parameter("edge_color", borde)
	_material.set_shader_parameter("cone_length", largo_cono)

	var malla := MeshInstance3D.new()
	malla.mesh = cono
	malla.material_override = _material
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	malla.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	malla.position = Vector3(0.0, 0.0, largo_cono * 0.5)
	add_child(malla)

	_luz = OmniLight3D.new()
	_luz.light_color = borde.lerp(nucleo, 0.4)
	_luz.light_energy = 0.25
	_luz.omni_range = largo_nave * 1.8
	_luz.shadow_enabled = false
	add_child(_luz)


func _process(delta: float) -> void:
	var objetivo := _reposo
	if _siempre_activa:
		objetivo = maxf(_reposo, 0.55)
	elif _cuerpo != null:
		if _cuerpo.get("propulsor_activo") == true:
			objetivo = 1.0
		elif _cuerpo.velocity.length() > 1.0:
			objetivo = 0.45

	_nivel = lerpf(_nivel, objetivo, clampf(6.0 * delta, 0.0, 1.0))
	var ancho := lerpf(0.45, 0.85, _nivel)
	scale = Vector3(ancho, ancho, lerpf(0.25, 0.9, _nivel))
	_material.set_shader_parameter("intensity", lerpf(0.35, 1.1, _nivel))
	_luz.light_energy = lerpf(0.2, 1.1, _nivel)


func _buscar_cuerpo_padre() -> CharacterBody3D:
	var n := get_parent()
	while n != null:
		if n is CharacterBody3D:
			return n as CharacterBody3D
		n = n.get_parent()
	return null
