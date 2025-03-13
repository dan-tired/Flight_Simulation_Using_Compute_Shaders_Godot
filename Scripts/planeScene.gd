extends RigidBody3D

@export var THRUST_ACCEL : float = 10
@export var useAilerons : bool = false
@export var useThrust : bool = true

var thrust : float = 0.0

var direction : Vector3 = Vector3(-1.0, 0.0, 0.0)

var camDist : float

var orthoCam : Camera3D 

func _ready() -> void:
	orthoCam = get_parent().get_node("OrthoCam")
	camDist = orthoCam.position.y
	$PlaneBody.useAilerons = useAilerons
	
	apply_central_impulse(Vector3(-30, 0, 0))

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
		else :
			if thrust >= 0.0 :
				thrust -= 2 * THRUST_ACCEL * delta
			else :
				thrust = 0.0
		
		#linear_velocity = (direction * thrust * delta) + get_gravity()
		
		apply_central_force(direction * thrust)
		
		#print(global_position)
	
	
