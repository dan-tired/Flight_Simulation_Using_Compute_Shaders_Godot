shader_type spatial;

render_mode fog_disabled, cull_back;

//uniform sampler2D depth_texture : source_color, hint_depth_texture;
//uniform sampler2D normal_rough_texture : hint_normal_roughness_texture;
//uniform sampler2D transparency : hint_screen_texture;

uniform sampler2D tex;
uniform sampler2D metallic;
uniform sampler2D roughness;

uniform vec3 metallic_channel;

varying uint camera_visible_layers;

void vertex() {
	//POSITION = vec4(VERTEX.xy, 1.0, 1.0);
	//COLOR.rgb = vec3(0.4, 0.4, 0.6);
}

void fragment() {

	if((int(CAMERA_VISIBLE_LAYERS)&1)==0) {
		vec3 worldNorms = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;

		vec3 boundedWorldNorms = normalize(worldNorms) / 2.0 + 0.5;

		ALBEDO.rgb = vec3(0.0);
		EMISSION.rb = boundedWorldNorms.xz;
		EMISSION.g = FRAGCOORD.z;
	}
	else {
		//ALBEDO = COLOR.xyz;
		vec4 texel = texture(tex, UV.xy);
		ALBEDO = texel.xyz;
		METALLIC =
			metallic_channel.x * texture(metallic, UV.xy).x +
			metallic_channel.y * texture(metallic, UV.xy).y +
			metallic_channel.z * texture(metallic, UV.xy).z;
		NORMAL = (1.0) * texture(roughness, UV).xyz + NORMAL;
	}

	camera_visible_layers = CAMERA_VISIBLE_LAYERS;
}

//void light() {
	//if((int(camera_visible_layers)&(1))==0){
		//DIFFUSE_LIGHT=ALBEDO;
		//SPECULAR_LIGHT=vec3(0,0,0);
	//}
//}
