extends Node3D

# Variable for setting the distance from the camera to the plane object
# Useful for objects of different sizes
@export var cam_dist : float = 1.0

# Called when the node enters the scene tree for the first time.
# Sets the camera to the follower camera and changes some project settings.
func _ready() -> void:
	$FollowerCam.make_current()
	
	# Removing mesh LOD as the terrain has it built-in and the models look better without it.
	# (and in the context of this demo - they don't cause a performance drop)
	get_tree().root.mesh_lod_threshold = 0
	
	## Slowing down time for debug
	#Engine.time_scale = 0.05


# Called every frame. 'delta' is the elapsed time since the previous frame.
# Does the required maths for the follower cam to always stay behind the plane object.
func _process(_delta: float) -> void:
	var planeBody = $DepthNormalSubViewport/PlaneScene/PlaneBody
	var planeForward : Vector3 = planeBody.get_node("Front").global_position - planeBody.global_position
	var planeUp : Vector3 = Vector3(0.0, 1.0, 0.0)
	
	var planeRight = planeForward.cross(planeUp)
	
	# The direction the plane is facing on the y-plane
	var planeFacingDir = planeRight.cross(planeUp)
	
	$FollowerCam.global_position = planeBody.global_position + (planeFacingDir.normalized() * cam_dist)
	$FollowerCam.global_position += Vector3(0.0, 0.5, 0.0) * cam_dist
	
	$FollowerCam.look_at_from_position($FollowerCam.global_position, planeBody.global_position)
