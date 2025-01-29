extends SubViewport

var rd : RenderingDevice
var shader : RID
var pipeline : RID
var texture_size : Vector2i
var texture2Drd : Texture2DRD

var input_texture : RID
var sampler : RID
var output_buffer : RID
var uniform_set : RID
var fmt : RDTextureFormat
var img_pba : PackedByteArray

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_target_update_mode = UpdateMode.UPDATE_ALWAYS
	
	await RenderingServer.frame_post_draw
	
	texture_size = get_texture().get_size()
	
	var img := get_texture().get_image()
	img_pba = img.get_data()
	
	fmt = RDTextureFormat.new()
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB
	fmt.width = texture_size.y
	fmt.height = texture_size.x
	fmt.usage_bits = (
			RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
			RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT |
			RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
			RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	)
	
	img.save_png("test.png")
	
	RenderingServer.call_on_render_thread(_init_compute_code)
	
	# Don't think I need to be doing anything else here?
	# I guess we'll find out soon enough!

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#RenderingServer.call_on_render_thread(_render_process)
	pass

func _exit_tree() -> void:
	#RenderingServer.call_on_render_thread(_free_resources)
	pass

func _init_compute_code() -> void:
	# Retrieving the rendering device
	rd = RenderingServer.get_rendering_device()
	# Creating the shader
	var shader_file : Resource = load("res://Shaders/ComputeShaderFiles/compute_example.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	input_texture = rd.texture_create(fmt, RDTextureView.new(), [img_pba])
	
	var sampler = create_sampler()
	
	# Creating the texture uniform
	var texture_uniform = RDUniform.new()
	texture_uniform.binding = 0
	texture_uniform.add_id(sampler)
	texture_uniform.add_id(input_texture)
	texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	
	# Creating 2D array for simple output test
	var array_initialiser = []
	for i in (texture_size.x / 8) * (texture_size.x / 8) :
		array_initialiser.append(0)
	var output_buffer_pba := PackedInt32Array(array_initialiser).to_byte_array()
	output_buffer = rd.storage_buffer_create(output_buffer_pba.size(), output_buffer_pba)
	
	# Creating the buffer uniform
	var buffer_uniform = RDUniform.new()
	buffer_uniform.binding = 1
	buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	buffer_uniform.add_id(output_buffer)
	
	uniform_set = rd.uniform_set_create([texture_uniform, buffer_uniform], shader, 0)

	print("Completed uniform set")
	print(uniform_set)

func _render_process() -> void:
	# I'll figure out what needs to be pushed up other than the texture size 
	
	var x_groups : int = (texture_size.x - 1) / 8 + 1
	var y_groups : int = (texture_size.y - 1) / 8 + 1
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()

func create_sampler() -> RID :
	var sampler_state := RDSamplerState.new()
	# This state (unnormalized_uvw) allows me to use pixel coordinates to sample the texture
	# As opposed to using normalized uvs between 0 and 1
	sampler_state.unnormalized_uvw = true 
	sampler = rd.sampler_create(sampler_state)
	return sampler

func _free_resources() -> void :
	rd.free_rid(shader)
	rd.free_rid(output_buffer)
	rd.free_rid(uniform_set)
	rd.free_rid(input_texture)
	rd.free_rid(sampler)
