shader_type canvas_item;

uniform vec4 fog_color : source_color;
uniform float explored_alpha = 0.51;

void fragment() {
	float level = texture(TEXTURE, UV).r * 255.0;
	float alpha = level < 1.0 ? mix(1.0, explored_alpha, level) : mix(explored_alpha, 0.0, level - 1.0);
	COLOR = vec4(fog_color.rgb, alpha);
}
