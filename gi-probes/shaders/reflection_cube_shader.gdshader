shader_type spatial;

uniform samplerCube source_panorama : filter_linear, source_color, hint_default_black;
uniform float exposure = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 eyedir = NORMAL;
    ALBEDO = texture(source_panorama, eyedir).rgb * exposure;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
