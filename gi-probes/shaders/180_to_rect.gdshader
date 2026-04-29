shader_type canvas_item;

uniform sampler2D left;
uniform sampler2D right;
uniform float exposure = 1.0;

void fragment() {
	// left or right 
	vec2 uv = vec2(UV.x*2.0, UV.y);
	
	if(uv.y < 1.0) {
		COLOR = vec4(texture(left, uv).rgb * exposure, 1.0);
	} else {
		uv.y = uv.y - 1.0; 
		COLOR = vec4(texture(right, uv).rgb * exposure, 1.0);
	}
}
