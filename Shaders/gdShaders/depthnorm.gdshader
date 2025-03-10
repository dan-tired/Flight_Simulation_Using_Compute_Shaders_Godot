shader_type spatial;

render_mode fog_disabled, cull_back;

//uniform sampler2D depth_texture : source_color, hint_depth_texture;
//uniform sampler2D normal_rough_texture : hint_normal_roughness_texture;
//uniform sampler2D transparency : hint_screen_texture;

varying uint camera_visible_layers;

void vertex() {
	//POSITION = vec4(VERTEX.xy, 1.0, 1.0);
	COLOR.rgb = vec3(0.4, 0.4, 0.6);
}

void fragment() {

	if((int(CAMERA_VISIBLE_LAYERS)&1)==0) {
		vec3 worldNorms = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;

		worldNorms = normalize(worldNorms);

		//ALBEDO.rgb = worldNorms;
		//ALBEDO.rgb = worldNorms * 2.0 + 1.0;

		vec3 boundedWorldNorms = normalize((worldNorms + 1.0) / 2.0);

		float halfDepth = FRAGCOORD.z * 0.5;

		ALBEDO.rgb = vec3(0.0);
		EMISSION.rgb = boundedWorldNorms.xyz;
		//EMISSION.b = boundedWorldNorms.z > 0.5 ? halfDepth + 0.5 : halfDepth;
		//ALPHA = transparent.w;
	} else {
		ALBEDO = COLOR.xyz;
	}

	camera_visible_layers = CAMERA_VISIBLE_LAYERS;

}

void light() {
	if((int(camera_visible_layers)&(1))==0){
		DIFFUSE_LIGHT=ALBEDO;
		SPECULAR_LIGHT=vec3(0,0,0);
	}
}
