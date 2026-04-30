shader_type spatial;

render_mode blend_mix, specular_disabled, cull_disabled;

// Textures / Color

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color;

uniform float roughness_scalar : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D roughness_texture;

uniform float metallic_scalar : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D metallic_texture;

uniform sampler2D normal_texture : hint_normal;
uniform float normal_scale : hint_range(0.0, 4.0) = 1.0;

// Harmonics

uniform bool use_sh;
uniform vec3 sh[9];


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


// -------------------------------------------------------------------


void fragment() {
 	vec2 uv = UV;
	
	vec4 albedo_tex = texture(albedo_texture, uv);
 	vec3 albedo = albedo_color.rgb * albedo_tex.rgb;

 	float roughness_tex = texture(roughness_texture, uv).r;
 	float roughness = clamp(roughness_scalar * roughness_tex, 0.04, 1.0);

 	float metallic_tex = texture(metallic_texture, uv).r;
 	float metallic = clamp(metallic_scalar * metallic_tex, 0.0, 1.0);
 	 	
 	vec3 normal_map = texture(normal_texture, uv).rgb;
 	NORMAL_MAP = normal_map;
 	NORMAL_MAP_DEPTH = normal_scale;
	 	
 	ALBEDO = albedo;
 	ROUGHNESS = roughness;
 	METALLIC = metallic;
	
	// in editor -> no valid sh values so disable always
   
	#ifdef EDITOR_HINT
 	vec3 irradiance = vec3(1.0);
	#else
	 	vec3 irradiance = evaluate_sh(normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz));
	#endif
	   
 	if(use_sh)
		ALBEDO *= irradiance;
}




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

	// metallic workflow
 	if (NdotL > 0.0) {
 	 	vec3 albedo = ALBEDO;
 	 	float roughness = ROUGHNESS;
 	 	float metallic = METALLIC;
		
 	 	vec3 dielectric_F0 = vec3(0.04);
 	 	vec3 F0 = mix(dielectric_F0, albedo, metallic);

 	 	vec3 F = fresnel_schlick(VdotH, F0); 	   
 	 	float D = distribution_ggx(NdotH, roughness);
 	 	float G = geometry_smith(NdotV, NdotL, roughness);

 	 	vec3 numerator = D * G * F;
 	 	float denominator = max(4.0 * NdotV * NdotL, 0.0001);

 	 	vec3 specular = numerator / denominator;


 	 	vec3 kD = vec3(1.0) * (1.0 - metallic);
 	 	vec3 diffuse = kD * albedo / PI;

 	 	vec3 radiance = LIGHT_COLOR.rgb * ATTENUATION;

 	 	diffuse_out = diffuse * radiance * NdotL;
 	 	specular_out = specular * radiance * NdotL;
 	}

 	DIFFUSE_LIGHT += diffuse_out;
 	SPECULAR_LIGHT += specular_out;
}