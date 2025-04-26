extends SubViewport

# Rendering device that the compute shader will be run on
var rd : RenderingDevice

## Aggregated outputs of the compute shader

# The aggregated force applied when the central force flag is set to true.
# i.e. when the "Apply Force Centrally" option is selected the individual forces are aggregated
# and applied to the origin of the RigidBody3D
var totalForce : Vector3 = Vector3()

# The average position of all forces and positions being returned by the compute shader.
# TODO: Implement this, and apply the aggregated force and see if it changes anything.
var averagePos : Vector3 = Vector3()

## Arrays storing the outputs of the compute shader
# The two arrays below are populated in a way that each force and position is calculated from the
# same work group of pixels.

# It works fine from the testing I've done, but I frankly don't trust the method
# TODO: Write a more reliable method than discarding zeroes - shouldn't be hard

# The array responsible for holding the forces returned by the compute shader.
var forceArr : PackedVector3Array

# The array responsible for holding the average pixel positions calculated from the texture
# from which the forces are calculated.
var forcePosArr : PackedVector3Array

## Resource ID's for the structures the rendering device recognises
# These are how you actually interact with the shader on the rendering device

# Compute Shader Resource ID
var shader : RID
# Shader Pipeline RID
var pipeline : RID

# RID for the input texture - the image from the underside of the plane in a format the RD likes
var input_texture : RID
# Texture sampler RID - used for actually retrieving pixel info within the compute shader
var sampler : RID

# Buffer RID for the values you wish to input to the compute shader
var input_buffer : RID
# Buffer RID for the values you wish you output from the compute shader
var output_buffer : RID
# Uniform set storing the information you wish to input and output from the shader
var uniform_set : RID

## Image conversion variables

# Format variable used to modify the format of the texture returned by the subviewport
var fmt : RDTextureFormat
# Packed byte array containing all of the image data in array form
var img_pba : PackedByteArray

## Signal waiter
# This is a bool used to wait for a signal that indicates that the ready function has completed
# and that the boilerplate for the compute shader setup has been completed before the _process
# method runs.
# TODO: Verify that there isn't a better way to do this, or do it better.
var ready_complete : bool

## Scene info

# A reference to the plane scene's rigidbody object - the root of the planescene
var plane : RigidBody3D

# The size of the orthographic camera in metres
var camSize : float
# The near plane of the orthographic camera
var camNear : float
# The far plane of the orthographic camera
var camFar : float
# The orthographic camera's relative y position under the the plane scene rigidbody
var camRelPos : float

## Debug seconds counter
# TODO: Redo this with a timer object like with the terrain, or get rid of it

# The initial UNIX time as a float storing the time the first run of the ready function is ran
var initialTime : float
# The counter storing the last second passed as an integer
var lastSecond : int

## Texture size variable storing the pixel width and height of the subviewport texture
var texture_size : Vector2i

## Signal that fires when the _ready function has finished executing
signal compute_code_ready

# Called when the node enters the scene tree for the first time.
# Prepares all references and unchanging variables for the process function.
func _ready() -> void:
	# Very important - we want the subviewport to update with every frame even if it's texture is
	# otherwise never used
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
	
	# Calling the render thread to initialised the RIDs for the shader code
	RenderingServer.call_on_render_thread(_init_compute_code)
	
	# Emitting a signal to let the _process method know that _ready is finished
	compute_code_ready.emit()
	ready_complete = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Awaiting _ready to complete to ensure all the needed variables are initialised
	if !ready_complete :
		await compute_code_ready
	
	# Doing all the fun compute shader stuff on the render thread
	RenderingServer.call_on_render_thread(_render_process)
	
	## Debug code to print the position and velocity of the plane at every second in time
	#var elapsedTime := Time.get_unix_time_from_system() - initialTime
	#
	#if lastSecond <= elapsedTime :
		#print("frame")
		#print("Elapsed time:\t" + str(elapsedTime))
		#print("Global Position:\t" + str(plane.global_position))
		#print("Linear Vel:  \t" + str(plane.linear_velocity))
		#print("Angular Vel: \t" + str(plane.angular_velocity))
		#print("Force Magnitude:\t" + str(totalForce.length()))
		#print("Force Direction:\t" + str(totalForce))
		#print()
		#lastSecond += 1

# Application of the forces depending on whether the forces are selected to be applied centrally or not
func _physics_process(delta: float) -> void:
	
	if plane.applyForceCentrally :
		plane.apply_central_force(totalForce * delta)
	else :
		if forceArr.size() > 0 :
			for i in forceArr.size() :
				plane.apply_force(forceArr[i] * delta, forcePosArr[i])
	pass

# Freeing the RIDs where the Rendering Device variables were being stored
func _exit_tree() -> void:
	RenderingServer.call_on_render_thread(_free_resources)

# Initializing the variables for the compute shader
func _init_compute_code() -> void:
	# Creating a local rendering device
	rd = RenderingServer.create_local_rendering_device()
	# Creating the shader
	var shader_file : Resource = load("res://Shaders/ComputeShaderFiles/compute_lift.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	texture_size = get_texture().get_size()
	
	# Converting the subviewport texture to an image, then converting it into a packed array
	var img := get_texture().get_image()
	img_pba = img.get_data()
	
	## Debug code that shows an image is being created - also useful to check image formatting
	# img.save_png("test.png")
	
	# Creating a new format for the texture passed in to the compute shader uniform
	fmt = RDTextureFormat.new()
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB # This seems to preserve the colour properly
	fmt.width = texture_size.y
	fmt.height = texture_size.x
	fmt.usage_bits = (
			RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT |
			RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT |
			RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
			RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	)
	
	# A texture being created in a format the rendering device likes
	input_texture = rd.texture_create(fmt, RDTextureView.new(), [img_pba])
	
	# Creating the sampler
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
	# #work_groups_x * #work_groups_y * 3D vector * (norm and fragpos = 2)
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
	
	# Putting all created uniforms into a uniform set, as the shader gods intended
	uniform_set = rd.uniform_set_create([texture_uniform, input_buf_uniform, output_buf_uniform], shader, 0)

# Called every frame.
# Updates the texture, feeds the shader all new inputs for the frame, and retrieves the shader's output.
func _render_process() -> void:
	
	# Making sure that the number of work groups is the correct one with no rounding errors
	var x_groups : int = (texture_size.x - 1) / 8 + 1
	var y_groups : int = (texture_size.y - 1) / 8 + 1
	
	# Updates the texture being passed in to the one returned by the subviewport
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
	
	# Submitting the information to the rendering device
	rd.submit()
	# Syncing the rendering device with the CPU
	rd.sync()
	# The above two methods should be more separated, but they run at a fine speed so it's okay for now
	
	## Retrieving the lift info from the buffers
	pba = rd.buffer_get_data(output_buffer)
	var out_array = pba.to_float32_array()
	
	totalForce = Vector3()
	averagePos = Vector3()
	forceArr = PackedVector3Array()
	forcePosArr = PackedVector3Array()
	var forceComponent := Vector3()
	var forcePos := Vector3()
	
	if plane.applyForceCentrally : 
		# If true - An average force is calculated and applied to the rigidbody centre of mass
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
		# Otherwise, one force is applied to each work group involved
		for i in out_array.size() :
			if int(i / (3 * x_groups)) % 2 == 0 :
				if i % 3 == 0 :
					forceComponent.x = out_array[i]
				elif i % 3 == 1 :
					forceComponent.y = out_array[i]
				else :
					forceComponent.z = out_array[i]
					
					# The buffer index outputs zeroes if a work group has no visibility 
					# on a part of the plane
					if(forceComponent.is_equal_approx(Vector3(0.0, 0.0, 0.0))) :
						continue
					
					totalForce += forceComponent
					forceArr.append(forceComponent)
			else :
				if i % 3 == 0 :
					forcePos.x = out_array[i]
				elif i % 3 == 1 :
					forcePos.y = out_array[i]
				else :
					forcePos.z = out_array[i]
					
					if(forcePos.is_equal_approx(Vector3(0.0, 0.0, 0.0))) :
						continue
					
					forcePosArr.append(forcePos)
	
	## Debugger function - only works when Godot is launched from a terminal
	## Press "P" to print
	#_terminal_debugger(out_array)
	
	# Clearing the output buffer for the next frame
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

func _terminal_debugger(out_array) -> void :
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
