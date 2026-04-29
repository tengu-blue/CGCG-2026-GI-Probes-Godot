shader_type spatial;

render_mode blend_mix, depth_draw_opaque, specular_disabled, cull_disabled;

// ============================================================
// MATERIAL INPUTS
// ============================================================

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color;

uniform float roughness_scalar : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D roughness_texture;

uniform float metallic_scalar : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D metallic_texture;

uniform float specular_scalar : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D specular_texture;

uniform sampler2D normal_texture : hint_normal;
uniform float normal_scale : hint_range(0.0, 4.0) = 1.0;

// ============================================================
// SPHERICAL HARMONICS COEFFICIENTS
// ============================================================

uniform bool use_sh;
uniform vec3 sh[9];

// ============================================================
// HELPERS
// ============================================================

vec3 evaluate_sh(vec3 n) {
    float x = -n.x;
    float y = -n.z;
    float z = n.y;

    float basis[9];

    basis[0] = 0.282095;
    basis[1] = 0.488603 * y;
    basis[2] = 0.488603 * z;
    basis[3] = 0.488603 * x;
    basis[4] = 1.092548 * x * y;
    basis[5] = 1.092548 * y * z;
    basis[6] = 0.315392 * (3.0 * z * z - 1.0);
    basis[7] = 1.092548 * x * z;
    basis[8] = 0.546274 * (x * x - y * y);

    vec3 result = vec3(0.0);

    for (int i = 0; i < 9; i++) {
        result += sh[i] * basis[i];
    }

    return max(result, vec3(0.0));
}

float distribution_ggx(float NdotH, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;

    float denom = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
    return a2 / max(PI * denom * denom, 0.0001);
}

float geometry_schlick_ggx(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;

    return NdotV / max(NdotV * (1.0 - k) + k, 0.0001);
}

float geometry_smith(float NdotV, float NdotL, float roughness) {
    float ggx1 = geometry_schlick_ggx(NdotV, roughness);
    float ggx2 = geometry_schlick_ggx(NdotL, roughness);

    return ggx1 * ggx2;
}

vec3 fresnel_schlick(float cos_theta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cos_theta, 5.0);
}

// ============================================================
// FRAGMENT STAGE
// ============================================================

void fragment() {
    vec2 uv = UV;

    // ========================================================
    // Material sampling
    // ========================================================

    vec4 albedo_tex = texture(albedo_texture, uv);
    vec3 albedo = albedo_color.rgb * albedo_tex.rgb;

    float roughness_tex = texture(roughness_texture, uv).r;
    float roughness = clamp(roughness_scalar * roughness_tex, 0.04, 1.0);

    float metallic_tex = texture(metallic_texture, uv).r;
    float metallic = clamp(metallic_scalar * metallic_tex, 0.0, 1.0);

    float specular_tex = texture(specular_texture, uv).r;
    float specular = clamp(specular_scalar * specular_tex, 0.0, 1.0);

    // ========================================================
    // Normal mapping
    // ========================================================

    vec3 normal_map = texture(normal_texture, uv).rgb;
    NORMAL_MAP = normal_map;
    NORMAL_MAP_DEPTH = normal_scale;

    // ========================================================
    // Standard outputs
    // ========================================================

    ALBEDO = albedo;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = specular;

    // ========================================================
    // SH probe diffuse irradiance
    // ========================================================
	#ifdef EDITOR_HINT
    vec3 irradiance = vec3(1.0);
	#else
	    vec3 irradiance = evaluate_sh(normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz));
	#endif
    
    // Store indirect diffuse contribution in built-in ambient
    // instead of emission
    //AO = 1.0;

    // Pre-bake probe lighting into albedo response
    // This keeps SH as diffuse reflectance rather than self-light
    if(use_sh)
		ALBEDO *= irradiance;
}

// ============================================================
// LIGHT STAGE
// ============================================================

void light() {
	vec2 uv = UV;
	
    vec3 N = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    vec3 V = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
    vec3 L = normalize((INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).xyz);
    vec3 H = normalize(V + L);

    float NdotL = max(dot(N, L), 0.0);
    float NdotV = max(dot(N, V), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float VdotH = max(dot(V, H), 0.0);

    vec3 diffuse_out = vec3(0.0);
    vec3 specular_out = vec3(0.0);

    if (NdotL > 0.0) {
        vec3 albedo = ALBEDO;
        float roughness = ROUGHNESS;
        float metallic = METALLIC;
		
		float specular_tex = texture(specular_texture, uv).r;
    	float specular = clamp(specular_scalar * specular_tex, 0.0, 1.0);
        float specular_strength = specular;

        // ========================================================
        // Fresnel base reflectivity
        // ========================================================

        vec3 dielectric_F0 = vec3(0.04 * specular_strength);
        vec3 F0 = mix(dielectric_F0, albedo, metallic);

        vec3 F = fresnel_schlick(VdotH, F0);

        // ========================================================
        // Cook-Torrance terms
        // ========================================================

        float D = distribution_ggx(NdotH, roughness);
        float G = geometry_smith(NdotV, NdotL, roughness);

        vec3 numerator = D * G * F;
        float denominator = max(4.0 * NdotV * NdotL, 0.0001);

        vec3 spec = numerator / denominator;

        // ========================================================
        // Energy conservation
        // ========================================================

        vec3 kS = F;
        vec3 kD = (vec3(1.0) - kS) * (1.0 - metallic);

        vec3 diffuse = kD * albedo / PI;

        // ========================================================
        // Light contribution
        // ========================================================

        vec3 radiance = LIGHT_COLOR.rgb * ATTENUATION;

        diffuse_out = diffuse * radiance * NdotL;
        specular_out = spec * radiance * NdotL;
    }

    DIFFUSE_LIGHT += diffuse_out;
    SPECULAR_LIGHT += specular_out;
}