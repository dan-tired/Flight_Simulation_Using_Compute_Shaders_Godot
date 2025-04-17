extends RigidBody3D

@export_group("Lift application")
@export var lift_coefficient : float = 0.0
@export var applyForceCentrally : bool = true

@export_group("Control")
@export_subgroup("Directional control")
@export var useControlSurfaces : bool = false

@export_subgroup("Thrust control")
@export var THRUST_ACCEL : float = 0.0
@export var startThrust : float = 0.0
@export var startImpulse : float = 0.0
@export var useThrust : bool = true

@export_group("Damping")
@export var angDamp : float = 0.0
@export var linearDamp : float = 0.0

var thrust : float

var direction : Vector3 = Vector3(-1.0, 0.0, 0.0)

var camDist : float

var orthoCam : Camera3D 

func _ready() -> void:
	orthoCam = get_parent().get_node("OrthoCam")
	camDist = orthoCam.position.y
	$PlaneBody.useControlSurfaces = useControlSurfaces
	
	thrust = startThrust
	
	apply_central_impulse(Vector3(-startImpulse, 0, 0))
	angular_damp = angDamp
	linear_damp = linearDamp

func _process(_delta : float) -> void :
	orthoCam.global_position = self.global_position + camDist * (Vector3(0.0, 1.0, 0.0))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if useThrust :
	
		direction = $PlaneBody/Front.global_position - $PlaneBody.global_position
		
		direction = direction.normalized()
		
		if Input.is_action_pressed("Increase Thrust") :
			thrust += THRUST_ACCEL * delta
		elif Input.is_action_pressed("Reduce Thrust") :
			thrust -= THRUST_ACCEL * delta
		#else :
			#if thrust >= 0.0 :
				#thrust -= 2 * THRUST_ACCEL * delta
			#else :
				#thrust = 0.0
		
		apply_central_force(direction * thrust)
	
	
