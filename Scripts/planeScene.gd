extends RigidBody3D

## Inspector options for the plane
@export_group("Lift application")
# The coefficient of lift of the plane set a constant
@export var lift_coefficient : float = 0.0
# Switch to apply the force centrally or per work-group
@export var applyForceCentrally : bool = true

@export_group("Control")
@export_subgroup("Directional control")
# Set to true to use control surfaces, otherwise control is just directly over the 
# orientation of the plane.
@export var useControlSurfaces : bool = false

@export_subgroup("Thrust control")
# When the accelerate button is pressed, this is the thrust that is added per second
@export var THRUST_ACCEL : float = 0.0
# The start amount of thrust the plane is outputting
@export var startThrust : float = 0.0
# The start impulse that is applied to the plane
@export var startImpulse : float = 0.0
# Boolean indicating whether or not thrust should be applied to the plane.
# Set to true when not using a gliding plane.
@export var useThrust : bool = true

# Place to override damping settings - just for convenience really
@export_group("Damping")
# Angular movement damping
@export var angDamp : float = 0.0
# Linear movement damping
@export var linearDamp : float = 0.0

# The thrust applied to the plane each second
var thrust : float

# The direction of the nose of the plane from it's centre of mass
var direction : Vector3 = Vector3(-1.0, 0.0, 0.0)

# Orthographic camera distance beneath the plane
var camDist : float

# Reference to the orthographic camera
var orthoCam : Camera3D 

func _ready() -> void:
	orthoCam = get_parent().get_node("OrthoCam")
	camDist = orthoCam.position.y
	
	# Passing the flag to the plane control script
	$PlaneBody.useControlSurfaces = useControlSurfaces
	
	thrust = startThrust
	
	apply_central_impulse(Vector3(-startImpulse, 0, 0))
	
	# overriding default damping settings
	angular_damp = angDamp
	linear_damp = linearDamp

func _process(_delta : float) -> void :
	# Ensuring the orthographic camera is in a constant position relative to the rigidbody's centre of mass 
	orthoCam.global_position = self.global_position + camDist * (Vector3(0.0, 1.0, 0.0))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if useThrust :
	
		direction = $PlaneBody/Front.global_position - $PlaneBody.global_position
		
		# Direction component of thrust
		direction = direction.normalized()
		
		if Input.is_action_pressed("Increase Thrust") :
			thrust += THRUST_ACCEL * delta
		elif Input.is_action_pressed("Reduce Thrust") :
			thrust -= THRUST_ACCEL * delta
		
		apply_central_force(direction * thrust)
	
	
