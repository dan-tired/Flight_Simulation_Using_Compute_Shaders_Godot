extends SubViewport

var rd : RenderingDevice
var shader : RID
var pipeline : RID
var texture_set : RID
var texture_size : Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.call_on_render_thread(_init_compute_code)
	
	# Don't think I need to be doing anything else here?
	# I guess we'll find out soon enough!

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	RenderingServer.call_on_render_thread(_render_process)

func _exit_tree() -> void:
	RenderingServer.call_on_render_thread(_free_resources)

func _init_compute_code() -> void:
	# Retrieving the render device
	rd = RenderingServer.get_rendering_device()
	# Creating the shader
	var shader_file : Resource = load("res://compute_example.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	var texture : ViewportTexture = get_texture()
	var rd_texture = RenderingServer.texture_get_rd_texture(texture.get_rid())
	
	texture_size = get_texture().get_size()
	
	render_target_update_mode = UpdateMode.UPDATE_ALWAYS
	
	assert(rd.texture_is_valid(rd_texture))
	
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(rd_texture)
	
	texture_set = rd.uniform_set_create([uniform], shader, 0)
	
	## May need to copy the viewport texture into a new texture
	## Basically just due to it being a shared texture?
	#var tf : RDTextureFormat = RDTextureFormat.new()
	#tf.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	#tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	#tf.width = texture.get_width()
	#tf.height = texture.get_height()
	#tf.depth = 1
	#tf.array_layers = 1
	#tf.mipmaps = 1
	#tf.usage_bits = (
			#RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
			#RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT |
			#RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
			#RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
			#RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	#)

func _render_process() -> void:
	# I'll figure out what needs to be pushed up other than the texture size 
	
	var x_groups : int = (texture_size.x - 1) / 8 + 1
	var y_groups : int = (texture_size.y - 1) / 8 + 1
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, texture_set, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()

func _free_resources() -> void :
	rd.free_rid(shader)
