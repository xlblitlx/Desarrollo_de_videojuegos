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
