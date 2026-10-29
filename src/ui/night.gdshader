shader_type canvas_item;

const int MAX_LIGHTS = 32;

uniform vec4 tint : source_color = vec4(0.016, 0.024, 0.043, 1.0);
uniform float strength = 0.0;
uniform float lit_alpha = 0.18;
uniform float softness = 48.0;
uniform float glow_light = 0.55;
uniform vec2 world_size = vec2(1.0, 1.0);
uniform sampler2D glow_mask : hint_default_black, filter_linear, repeat_disable;
uniform int light_count = 0;
uniform vec3 lights[MAX_LIGHTS];

varying vec2 world;

void vertex() {
	world = VERTEX;
}

void fragment() {
	float lit = glow_light * smoothstep(0.0, 0.5, texture(glow_mask, world / world_size).r);
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) {
			break;
		}
		vec3 light = lights[i];
		float edge = max(light.z, 1.0);
		lit = max(lit, 1.0 - smoothstep(edge - softness, edge, distance(world, light.xy)));
	}
	COLOR = vec4(tint.rgb, tint.a * strength * mix(1.0, lit_alpha, lit));
}
