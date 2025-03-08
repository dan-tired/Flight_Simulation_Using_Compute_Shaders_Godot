extends SubViewport

@export var coefficientOfLift : float

var rd : RenderingDevice
var texture_size : Vector2i

var totalForce : Vector3 = Vector3()

var shader : RID
var pipeline : RID

var input_texture : RID
var sampler : RID
var input_buffer : RID
var output_buffer : RID
var uniform_set : RID

var fmt : RDTextureFormat
var img_pba : PackedByteArray

var ready_complete : bool

var plane : RigidBody3D
var camSize : float

signal compute_code_ready

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_target_update_mode = UpdateMode.UPDATE_ALWAYS
	
	plane = get_parent().get_node("DepthNormalSubViewport/PlaneModel")
	
	var cam : Camera3D = get_parent().get_node("DepthNormalSubViewport/PlaneModel/OrthoCam")
	
	camSize = cam.size
	
	await RenderingServer.frame_post_draw
	
	RenderingServer.call_on_render_thread(_init_compute_code)
	
	compute_code_ready.emit()
	ready_complete = true
	
	# Don't think I need to be doing anything else here?
	# I guess we'll find out soon enough!

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if !ready_complete :
		await compute_code_ready
	
	RenderingServer.call_on_render_thread(_render_process)
	
	print("frame")
	print(plane.linear_velocity)
	print(totalForce.length())
	print(totalForce)
	print()

func _physics_process(_delta: float) -> void:
	plane.apply_central_force(totalForce)
	pass
	

func _exit_tree() -> void:
	RenderingServer.call_on_render_thread(_free_resources)

func _init_compute_code() -> void:
	# Retrieving the rendering device
	rd = RenderingServer.create_local_rendering_device()
	# Creating the shader
	var shader_file : Resource = load("res://Shaders/ComputeShaderFiles/compute_example.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	#print(pipeline)
	
	texture_size = get_texture().get_size()
	
	var img := get_texture().get_image()
	img_pba = img.get_data()
	
	#img.save_png("test.png")
	
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
	
	input_texture = rd.texture_create(fmt, RDTextureView.new(), [img_pba])
	
	sampler = rid_create_sampler()
	
	# Creating the texture uniform
	var texture_uniform = RDUniform.new()
	texture_uniform.binding = 0
	texture_uniform.add_id(sampler)
	texture_uniform.add_id(input_texture)
	texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	
	# Creating array for input
	var array_initialiser = []
	for i in 7 :
		array_initialiser.append(0)
	var input_buffer_pba := PackedInt32Array(array_initialiser).to_byte_array()
	input_buffer = rd.storage_buffer_create(input_buffer_pba.size(), input_buffer_pba)
	
	# Creating 2D array for output
	array_initialiser = []
	for i in (texture_size.x / 8) * (texture_size.y / 8) * 3:
		array_initialiser.append(0)
	var output_buffer_pba := PackedInt32Array(array_initialiser).to_byte_array()
	output_buffer = rd.storage_buffer_create(output_buffer_pba.size(), output_buffer_pba)
	
	# Creating the buffer uniform
	var input_buf_uniform := RDUniform.new()
	input_buf_uniform.binding = 1
	input_buf_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	input_buf_uniform.add_id(input_buffer)
	
	var output_buf_uniform := RDUniform.new()
	output_buf_uniform.binding = 2
	output_buf_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	output_buf_uniform.add_id(output_buffer)
	
	uniform_set = rd.uniform_set_create([texture_uniform, input_buf_uniform, output_buf_uniform], shader, 0)
	
	#print(uniform_set)


func _render_process() -> void:
	
	var x_groups : int = (texture_size.x - 1) / 8 + 1
	var y_groups : int = (texture_size.y - 1) / 8 + 1
	
	rd.texture_update(input_texture,0,get_texture().get_image().get_data())
	
	var pba := rd.buffer_get_data(input_buffer)
	
	var input_array = pba.to_float32_array()
	
	# Passing in the velocity of the plane
	input_array[0] = plane.linear_velocity.x
	input_array[1] = plane.linear_velocity.y
	input_array[2] = plane.linear_velocity.z
	
	# Passing in the coefficient of lift - users can set this themselves
	# They can do this experimentally or based on research
	input_array[3] = coefficientOfLift
	
	# Passing in the height of the plane for calculating air density
	input_array[4] = plane.global_position.y
	
	# Passing in the camera size
	input_array[5] = camSize
	
	# Passing in the texture dimensions (square image so only one value will do)
	input_array[6] = texture_size.x;
	
	pba = input_array.to_byte_array()
	
	# Angle of attack needs to be calculated from the vector normals
	
	rd.buffer_update(input_buffer, 0, pba.size(), pba)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()
	
	pba = rd.buffer_get_data(output_buffer)
	var out_array = pba.to_float32_array()
	
	totalForce = Vector3()
	
	for i in len(out_array) :
		if i % 3 == 0 :
			totalForce.x += out_array[i]
		elif i % 3 == 1 :
			totalForce.y += out_array[i]
		else :
			totalForce.z += out_array[i]
	
	## This only prints to your terminal when you run godot from your terminal
	## But it works! And when it runs you can see the outline of the plane forming in the numbers
	#for i in out_array.size() :
		#if i % 3 == 0 :
			#printraw("T,")
		#if out_array[i] != 0 :
			#printraw(str(1) + ",")
		#else :
			#var printer = "." + ","
			#printraw(printer)
		#if i % (64 * 3) == ((64 * 3) - 1) :
			#printraw("\n")
	
	#for i in out_array.size() :
		#if i % 3 == 0 : printraw("\n")
		#printraw(str(out_array[i]) + ",")
	
	rd.buffer_clear(output_buffer,0,pba.size())
	

func rid_create_sampler() -> RID :
	var sampler_state := RDSamplerState.new()
	# This state (unnormalized_uvw) allows me to use pixel coordinates to sample the texture
	# As opposed to using normalized uvs between 0 and 1
	sampler_state.unnormalized_uvw = true 
	sampler = rd.sampler_create(sampler_state)
	return sampler

func _free_resources() -> void :
	rd.free_rid(shader)
	rd.free_rid(input_buffer)
	rd.free_rid(output_buffer)
	rd.free_rid(uniform_set)
	rd.free_rid(input_texture)
	rd.free_rid(sampler)
	rd.free_rid(pipeline)
