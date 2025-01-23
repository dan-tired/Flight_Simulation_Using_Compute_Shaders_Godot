shader_type spatial;

uniform sampler2D heightmap;
uniform int terrian_height;
uniform float uvx : hint_range(-100.0, 100.0, 0.001);
uniform float uvy : hint_range(-100.0, 100.0, 0.001);

void vertex() {

	vec4 colIN = COLOR;
	ivec2 texSize = textureSize(heightmap, 0);

	vec2 uvs = vec2((POSITION.x + uvx)/float(texSize.x), (POSITION.z + uvy)/float(texSize.y));

	vec3 heightmap_out = texture(heightmap, uvs).rgb;



	//POSITION.y = (heightmap_out * vec3(0.0, float(terrian_height), 0.0)).y;

	COLOR = COLOR;

}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
