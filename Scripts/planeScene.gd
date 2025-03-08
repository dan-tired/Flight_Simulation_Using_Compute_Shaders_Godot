extends RigidBody3D

@export var THRUST_ACCEL : float = 10

var thrust : float = 0.0

var direction : Vector3 = Vector3(-1.0, 0.0, 0.0)

@export var useThrust : bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if useThrust :
	
		direction = $CollisionShape3D/PlaneBody/Front.global_position - $CollisionShape3D/PlaneBody.global_position
		
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
	
