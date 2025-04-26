extends Node3D

# Direction directly down
const DOWN = Vector3(.0, -1.0, .0)

# Pitching angular speed
const TIP_SPEED : float = 1.0
# Rolling angular speed
const ROLL_SPEED : float = 1.0
# Paper plane elevator control speed
const CONT_SURF_SPEED : float = 1.0

# The direction of the nose of the plane from its centre of mass
var planeDirection : Vector3
@onready var planeFront : Vector3 = Vector3(-1.0, .0, .0)
@onready var planeRight : Vector3 = Vector3(.0, .0, -1.0)
@onready var planeUp : Vector3 = Vector3(.0, 1.0, .0)

var useControlSurfaces : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
# Updates the direction vectors of the plane, then handles user input
func _process(delta: float) -> void:
	
	updateDirectionVectors()
	
	handleInput(delta)

# Updates the plane's front, up, and right directions using the cool and fun nodes for simplicity
func updateDirectionVectors() -> void :
	
	planeFront = $Front.position
	planeUp = $Up.position
	planeRight = $Right.position
	
	planeDirection = planeFront - position
	planeDirection = planeDirection.normalized()
	

# Handles user input
func handleInput(delta: float) -> void:
	
	if useControlSurfaces : # If control surfaces are being used, the control surfaces are tilted
		var tiltD = delta * CONT_SURF_SPEED
		
		var rollAngle = atan(tiltD)
		
		if Input.is_action_pressed("Roll Left") :
			$"L Anchor".rotate_object_local(planeRight, -rollAngle)
			$"R Anchor".rotate_object_local(planeRight, rollAngle)
		if Input.is_action_pressed("Roll Right") :
			$"L Anchor".rotate_object_local(planeRight, rollAngle)
			$"R Anchor".rotate_object_local(planeRight, -rollAngle)
		if Input.is_action_pressed("Pitch Down") :
			$"L Anchor".rotate_object_local(planeRight, -rollAngle)
			$"R Anchor".rotate_object_local(planeRight, -rollAngle)
		if Input.is_action_pressed("Pitch Up") :
			$"L Anchor".rotate_object_local(planeRight, rollAngle)
			$"R Anchor".rotate_object_local(planeRight, rollAngle)
	else : # If control surfaces are not being used, the pitch and roll of the object are updated independantly
		# Pitch down
		var pitchD : float = 0.0
		# Roll right
		var rollR : float = 0.0
		
		if Input.is_action_pressed("Pitch Down") :
			pitchD -= delta * TIP_SPEED
		if Input.is_action_pressed("Pitch Up") :
			pitchD += delta * TIP_SPEED
		if Input.is_action_pressed("Roll Left") :
			rollR -= delta * ROLL_SPEED
		if Input.is_action_pressed("Roll Right") :
			rollR += delta * ROLL_SPEED
		
		# Converting numeric shift into an angle
		var pitchAngle : float = atan(pitchD)
		var rollAngle : float = atan(rollR)
		
		rotate_object_local(planeDirection, rollAngle)
		rotate_object_local(planeRight,  pitchAngle)
	
