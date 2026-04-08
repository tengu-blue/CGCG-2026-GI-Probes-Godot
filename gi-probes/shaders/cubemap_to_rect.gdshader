shader_type canvas_item;

uniform samplerCube source_panorama : filter_linear, source_color, hint_default_black;
uniform float exposure = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 eyedir = vec3(	sin(UV.y * PI)*cos(UV.x * 2.0 * PI), 
						sin(UV.y * PI)*sin(UV.x * 2.0 * PI),
						cos(UV.y * PI));

	COLOR = vec4(texture(source_panorama, eyedir).rgb * exposure, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
