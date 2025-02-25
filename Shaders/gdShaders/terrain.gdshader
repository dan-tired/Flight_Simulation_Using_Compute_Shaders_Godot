shader_type spatial;

uniform sampler2D heightmap;
uniform float terrian_height;
uniform float uvx : hint_range(-100.0, 100.0, 0.001);
uniform float uvy : hint_range(-100.0, 100.0, 0.001);

vec3 getNormal(vec2 uv, float texelSize) {
	float t = texture(heightmap, uv + vec2(texelSize * vec2(1.0, 0.0))).x * terrian_height;
	float r = texture(heightmap, uv + vec2(texelSize * vec2(0.0, -1.0))).x * terrian_height;
	float l = texture(heightmap, uv + vec2(texelSize * vec2(0.0, 1.0))).x * terrian_height;
	float b = texture(heightmap, uv + vec2(texelSize * vec2(-1.0, 0.0))).x * terrian_height;

	return -normalize(vec3(2.0 * (b - t), -4.0, 2.0 * (r - l)));
}

void vertex() {

	vec2 uvs = vec2((UV.x + uvx), (UV.y + uvy));

	vec3 heightmap_out = texture(heightmap, uvs).rgb;

	vec3 halver = vec3(0.5, 0.5, 0.5);

	heightmap_out = heightmap_out - halver;

	vec3 vec_displacement = heightmap_out * vec3(0.0, terrian_height, 0.0);

	VERTEX.xyz += vec_displacement;

	NORMAL = getNormal(UV + vec2(uvx, uvy), 1.0 / float(textureSize(heightmap, 0).x));

	COLOR = COLOR;

}

void fragment() {
	NORMAL = NORMAL;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
