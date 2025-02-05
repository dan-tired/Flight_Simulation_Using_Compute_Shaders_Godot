shader_type spatial;

render_mode unshaded, fog_disabled, cull_back;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D normal_rough_texture : hint_normal_roughness_texture;
uniform sampler2D transparency : hint_screen_texture;


void vertex() {
	//POSITION = vec4(VERTEX.xy, 1.0, 1.0);
	COLOR.w = 0.f;
}

void fragment() {
	float depth = (texture(depth_texture, SCREEN_UV).x + 1.0) / 2.0;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;

	vec4 normal_rough = texture(normal_rough_texture, SCREEN_UV);
	vec3 normals_view_raw = normal_rough.xyz; // Normals in view space, in [0.0, 1.0] range
	vec3 normals_view_remapped = normals_view_raw.xyz * 2.0 - 1.0;  // Normals in view space, in [-1.0, 1.0] range
	vec3 normals_world = (INV_VIEW_MATRIX * vec4(normals_view_remapped, 0.0)).xyz;
	
	vec4 transparent = texture(transparency, SCREEN_UV);

	// Visualize linear depth
	//ALBEDO.rgb = vec3(fract(linear_depth));
	// Visualize world position
	//ALBEDO.rgb = fract(world_position).xyz;
	// Visualize world normals
	// ALBEDO.rgb = normals_world;
	
	ALBEDO.rgb = normals_world.xyz;
	ALPHA = transparent.w;

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
