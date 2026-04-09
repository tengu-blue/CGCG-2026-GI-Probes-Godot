shader_type spatial;
render_mode unshaded;

uniform vec3 sh[9]; // your 9 coefficients (RGB)

// Real SH basis (same order as before)
float sh_basis(int i, vec3 n) {
    float x = n.x;
    float y = n.y;
    float z = n.z;

    if (i == 0) return 0.282095;
	
    if (i == 1) return 0.488603 * y;
    if (i == 2) return 0.488603 * z;
    if (i == 3) return 0.488603 * x;

    if (i == 4) return 1.092548 * x * y;
    if (i == 5) return 1.092548 * y * z;
    if (i == 6) return 0.315392 * (3.0 * z * z - 1.0);
    if (i == 7) return 1.092548 * x * z;
    if (i == 8) return 0.546274 * (x * x - y * y);

    return 0.0;
}

void fragment() {
    vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

    vec3 color = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        color += sh[i] * sh_basis(i, n);
    }

    ALBEDO = color;
}