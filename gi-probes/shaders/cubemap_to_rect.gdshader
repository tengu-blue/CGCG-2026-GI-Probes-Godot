shader_type canvas_item;

uniform samplerCube source_panorama : filter_linear, source_color, hint_default_black;
uniform float exposure = 1.0;

void fragment() {
	vec3 eyedir = vec3(	sin(UV.y * PI)*cos(UV.x * 2.0 * PI), 
					   -cos(UV.y * PI),
						sin(UV.y * PI)*sin(UV.x * 2.0 * PI));

	COLOR = vec4(texture(source_panorama, eyedir).rgb * exposure, 1.0);
}
