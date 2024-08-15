shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	vec3 base = texture(screen_texture, SCREEN_UV).rgb;
	vec3 blend = COLOR.rgb;
	
	COLOR.rgb = 1.0 - (1.0 - base) * (1.0 - blend);
}
