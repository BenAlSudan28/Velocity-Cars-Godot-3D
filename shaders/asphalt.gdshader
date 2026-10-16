shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.16, 0.18, 0.21, 1.0);
uniform float grain_scale = 17.0;
uniform float grain_strength = 0.21;
varying vec3 world_position;

float hash_cell(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float cell = hash_cell(floor(world_position.xz * grain_scale));
	float fine = hash_cell(floor(world_position.xz * grain_scale * 3.7));
	float grain = (cell - 0.5) * grain_strength + (fine - 0.5) * grain_strength * 0.34;
	ALBEDO = base_color.rgb * (0.94 + grain);
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}
