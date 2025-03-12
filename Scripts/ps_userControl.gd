extends Node3D

const DOWN = Vector3(.0, -1.0, .0)

const TIP_SPEED : float = 1.0
const AILERON_ROLL_SPEED : float = 1.0
const ROLL_SPEED : float = 1.0

var planeDirection : Vector3
@onready var planeFront : Vector3 = Vector3(-1.0, .0, .0)
@onready var planeRight : Vector3 = Vector3(.0, .0, -1.0)
@onready var planeUp : Vector3 = Vector3(.0, 1.0, .0)

@export var useAilerons : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	updateDirectionVectors()
	
	handleInput(delta)

func updateDirectionVectors() -> void :
	
	planeFront = $Front.position
	planeUp = $Up.position
	planeRight = $Right.position
	
	planeDirection = planeFront - position
	planeDirection = planeDirection.normalized()
	

func handleInput(delta: float) -> void:
	
	if useAilerons :
		var tiltD = delta * AILERON_ROLL_SPEED
		
		var rollAngle = atan(tiltD)
		
		if Input.is_action_pressed("Roll Left") :
			$"L Anchor".rotate_object_local(planeRight, -rollAngle)
			$"R Anchor".rotate_object_local(planeRight, rollAngle)
		if Input.is_action_pressed("Roll Right") :
			$"L Anchor".rotate_object_local(planeRight, rollAngle)
			$"R Anchor".rotate_object_local(planeRight, -rollAngle)
	else :
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
	
