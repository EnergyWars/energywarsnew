shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.66, 0.71, 0.82, 0.5);

void fragment() {
	COLOR = vec4(tint.rgb, COLOR.a * tint.a);
}
