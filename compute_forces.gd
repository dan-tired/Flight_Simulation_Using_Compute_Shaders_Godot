extends SubViewport

var rd : RenderingDevice
var shader : RID
var pipeline : RID
var texture_set : RID

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.call_on_render_thread(_init_compute_code)
	
	# Don't think I need to be doing anything else here?
	# I guess we'll find out soon enough!


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	RenderingServer.call_on_render_thread(_render_process)
	
	# Again, realistically all I want to be doing is chucking the
	# texture info into the rendering device

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
	
	render_target_update_mode = UpdateMode.UPDATE_ALWAYS
	
	assert(rd.texture_is_valid(rd_texture))
	
	texture_set = _create_uniform_sets(rd_texture)
	
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

func _create_uniform_sets(texture_rd : RID) -> RID:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(texture_rd)
	# Only using one set in theory so this is fine I think?
	# Also the sets are dependencies so I don't need to free them?
	return rd.uniform_set_create([uniform], shader, 0)

func _render_process() -> void:
	pass
