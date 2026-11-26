shader_type spatial;
uniform vec4 veta : source_color = vec4(0.6,0.61,0.63,1.0);
uniform float semilla = 1.0;
uniform float intensidad = 0.0;
varying vec3 local;
void vertex() {
	vec3 eje = normalize(VERTEX);
	float forma = sin(dot(eje,vec3(3.5,5.1,1.7))+semilla)*0.10 + cos(dot(eje,vec3(5.2,1.8,4.3))-semilla)*0.09;
	VERTEX *= vec3(0.96,0.83,1.04)*(0.93+forma);
	local = VERTEX;
}
void fragment() {
	vec3 faceta = normalize(cross(dFdx(VERTEX),dFdy(VERTEX)));
	NORMAL = dot(faceta,NORMAL) > 0.0 ? faceta : -faceta;
	float estrato = dot(local,vec3(7.0,10.5,3.3))+sin(local.z*11.0 + semilla)*1.4;
	float banda = pow(max(0.0,cos(estrato*2.2)),9.0);
	float roca = 0.53+0.20*sin(estrato*3.0)+0.14*sin(local.x*25.0+local.z*14.5);
	vec3 base = mix(vec3(0.075,0.088,0.102),veta.rgb,0.18)*roca;
	ALBEDO = mix(base, veta.rgb, banda*(0.35+intensidad*0.55));
	EMISSION = veta.rgb*banda*intensidad*0.85 + base*0.18;
	ROUGHNESS = 0.86;
}
