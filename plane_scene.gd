extends RigidBody3D

const THRUST_ACCEL : float = 1

@onready var thrust : float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("Increase Thrust") :
		thrust += THRUST_ACCEL * delta
	if Input.is_action_pressed("Reduce Thrust") :
		thrust -= THRUST_ACCEL * delta
	
	if thrust < 0.0 :
		thrust = 0.0
	
	var direction : Vector3 = $PlaneBody/Front.global_position - $PlaneBody.global_position
	
	direction = direction.normalized()
	
	global_position += direction * thrust * delta
	
	print(global_position)
