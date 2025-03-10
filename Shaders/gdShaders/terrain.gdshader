shader_type spatial;

render_mode cull_back;

uniform sampler2D heightmap;
uniform float terrian_height;
uniform float uv_scale;
uniform float uvx : hint_range(-100.0, 100.0, 0.001);
uniform float uvy : hint_range(-100.0, 100.0, 0.001);

vec3 getNormal(vec2 uv, float texelSize) {
	float t = texture(heightmap, uv + vec2(texelSize * vec2(1.0, 0.0))).x * terrian_height / uv_scale;
	float r = texture(heightmap, uv + vec2(texelSize * vec2(0.0, -1.0))).x * terrian_height / uv_scale;
	float l = texture(heightmap, uv + vec2(texelSize * vec2(0.0, 1.0))).x * terrian_height / uv_scale;
	float b = texture(heightmap, uv + vec2(texelSize * vec2(-1.0, 0.0))).x * terrian_height / uv_scale;

	return -normalize(vec3(2.0 * (b - t), -4.0, 2.0 * (r - l)));
}

void vertex() {

	vec2 uvs = vec2((UV.x + uvx), (UV.y + uvy)) / uv_scale;

	vec3 heightmap_out = texture(heightmap, uvs).rgb;

	vec3 halver = vec3(0.5, 0.5, 0.5);

	heightmap_out = heightmap_out - halver;

	vec3 vec_displacement = heightmap_out * vec3(0.0, terrian_height, 0.0);

	VERTEX.xyz += vec_displacement;

	NORMAL = getNormal(uvs, 2.0 * uv_scale / (float(textureSize(heightmap, 0).x)));

	COLOR.rgb = vec3(0.1, 0.6, 0.2);

}

void fragment() {
	ALBEDO = COLOR.rgb;
	NORMAL = NORMAL;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
