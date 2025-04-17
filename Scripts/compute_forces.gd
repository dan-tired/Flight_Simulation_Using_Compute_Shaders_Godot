extends SubViewport

var rd : RenderingDevice
var texture_size : Vector2i

var totalForce : Vector3 = Vector3()
var averagePos : Vector3 = Vector3()

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
var isSubmitted : bool

var plane : RigidBody3D

var camSize : float
var camNear : float
var camFar : float
var camRelPos : float

var initialTime : float
var lastSecond : int

var forceArr : PackedVector3Array
var forcePosArr : PackedVector3Array

signal compute_code_ready

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render_target_update_mode = UpdateMode.UPDATE_ALWAYS
	
	plane = $PlaneScene
	
	var cam : Camera3D = $OrthoCam
	
	camSize = cam.size
	camNear = cam.near
	camFar = cam.far
	camRelPos = cam.position.y
	
	initialTime = Time.get_unix_time_from_system()
	lastSecond = 0
	
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
	
	var elapsedTime := Time.get_unix_time_from_system() - initialTime
	
	if lastSecond <= elapsedTime :
		print("frame")
		print("Elapsed time:\t" + str(elapsedTime))
		print("Global Position:\t" + str(plane.global_position))
		print("Linear Vel:  \t" + str(plane.linear_velocity))
		print("Angular Vel: \t" + str(plane.angular_velocity))
		print("Force Magnitude:\t" + str(totalForce.length()))
		print("Force Direction:\t" + str(totalForce))
		print()
		lastSecond += 1

func _physics_process(delta: float) -> void:
	
	if plane.applyForceCentrally :
		plane.apply_central_force(totalForce * delta)
	else :
		if forceArr.size() > 0 :
			for i in forceArr.size() :
				plane.apply_force(forceArr[i] * delta, forcePosArr[i])
	pass

func _exit_tree() -> void:
	RenderingServer.call_on_render_thread(_free_resources)

func _init_compute_code() -> void:
	# Retrieving the rendering device
	rd = RenderingServer.create_local_rendering_device()
	# Creating the shader
	var shader_file : Resource = load("res://Shaders/ComputeShaderFiles/compute_lift.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	#print(pipeline)
	
	texture_size = get_texture().get_size()
	
	var img := get_texture().get_image()
	img_pba = img.get_data()
	
	#img.save_png("test.png")
	
	fmt = RDTextureFormat.new()
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB # Preserves colour properly
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
	for i in 13 :
		array_initialiser.append(0)
	var input_buffer_pba := PackedInt32Array(array_initialiser).to_byte_array()
	input_buffer = rd.storage_buffer_create(input_buffer_pba.size(), input_buffer_pba)
	
	# Creating 2D array for output
	# #work_groups_x * #work_groups_y * 3D vector * (norm and fragpos)
	array_initialiser = []
	for i in (texture_size.x / 8) * (texture_size.y / 8) * 3 * 2:
		array_initialiser.append(0)
	var output_buffer_pba := PackedInt32Array(array_initialiser).to_byte_array()
	output_buffer = rd.storage_buffer_create(output_buffer_pba.size(), output_buffer_pba)
	
	# Creating the input buffer uniform
	var input_buf_uniform := RDUniform.new()
	input_buf_uniform.binding = 1
	input_buf_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	input_buf_uniform.add_id(input_buffer)
	
	# Creatubg the output buffer uniform
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
	input_array[3] = plane.lift_coefficient
	
	# Passing in the height of the plane for calculating air density
	input_array[4] = plane.global_position.y
	
	# Passing in the camera size
	input_array[5] = camSize
	
	# Passing in the texture dimensions (square image so only one value will do)
	input_array[6] = texture_size.x
	
	# Passing in near and far planes of camera to reverse engineer distance 
	# from the depth buffer float
	input_array[7] = camNear
	input_array[8] = camFar
	
	# Passing in the camera position to make the depth calculation meaningful
	input_array[9] = camRelPos
	
	# Passing in the object's angular velocity
	input_array[10] = plane.angular_velocity.x
	input_array[11] = plane.angular_velocity.y
	input_array[12] = plane.angular_velocity.z
	
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
	averagePos = Vector3()
	forceArr = PackedVector3Array()
	forcePosArr = PackedVector3Array()
	var forceComponent := Vector3()
	var forcePos := Vector3()
	
	if plane.applyForceCentrally :
		for i in out_array.size() :
			if int(i / (3 * x_groups)) % 2 == 0 :
				if i % 3 == 0 :
					forceComponent.x = out_array[i]
				elif i % 3 == 1 :
					forceComponent.y = out_array[i]
				else :
					forceComponent.z = out_array[i]
					totalForce += forceComponent
	else :
		
		for i in out_array.size() :
			if int(i / (3 * x_groups)) % 2 == 0 :
				#printraw("0")
				if i % 3 == 0 :
					forceComponent.x = out_array[i]
				elif i % 3 == 1 :
					forceComponent.y = out_array[i]
				else :
					forceComponent.z = out_array[i]
					
					if(forceComponent.is_equal_approx(Vector3(0.0, 0.0, 0.0))) :
						continue
					
					totalForce += forceComponent
					forceArr.append(forceComponent)
			else :
				#printraw("1")
				if i % 3 == 0 :
					forcePos.x = out_array[i]
				elif i % 3 == 1 :
					forcePos.y = out_array[i]
				else :
					forcePos.z = out_array[i]
					
					if(forcePos.is_equal_approx(Vector3(0.0, 0.0, 0.0))) :
						continue
					
					forcePosArr.append(forcePos)
		
		if(Input.is_key_label_pressed(KEY_P)) :
			if(forceArr.size() == forcePosArr.size()) :
				for i in forceArr.size() :
					printraw(str(i) + ": " + str(forceArr[i]) + ", " + str(forcePosArr[i]) + "\n")
			else:
				printraw("false")
			
			#if i % (x_groups * 3) == ((x_groups * 3) - 1) :
				#printraw("\n")
	
	## This only prints to your terminal when you run godot from your terminal
	## But it works! And when it runs you can see the outline of the plane forming in the numbers
	
	if(Input.is_key_label_pressed(KEY_P)) :
		printraw("---------------------------------------------------------------\n")
		var counter : int = 0
		for i in out_array.size() :
			
			if !is_equal_approx(float(out_array[i]),0.0) :
				counter += 1
				#printraw(str(int(out_array[i])) + ",")
				##printraw(str(snapped(out_array[i], 0.01)) + ",")
			#else :
				#var printer = "." + ","
				#printraw(printer)
			#if i % (x_groups * 3) == ((x_groups * 3) - 1) :
				#printraw("\n")
		printraw("counter" + str(counter) + "\n")
		printraw("---------------------------------------------------------------\n")
		pass
	
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
	
	# Commented out RIDs are RIDs that are invalid when you try free them
	# I assume this means they don't need to be freed
	rd.free_rid(shader)
	rd.free_rid(input_buffer)
	rd.free_rid(output_buffer)
	#rd.free_rid(uniform_set)
	rd.free_rid(input_texture)
	rd.free_rid(sampler)
	#rd.free_rid(pipeline)
