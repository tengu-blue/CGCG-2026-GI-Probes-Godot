shader_type spatial;

uniform samplerCube source_panorama : filter_linear, source_color, hint_default_black;
uniform float exposure = 1.0;

void vertex() {
	
}

void fragment() {
	vec3 eyedir = normalize(-(INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    ALBEDO = texture(source_panorama, eyedir).rgb * exposure;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
