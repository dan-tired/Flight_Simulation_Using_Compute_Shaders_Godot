extends Node3D

@export var cam_dist : float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$FollowerCam.make_current()
	
	get_tree().root.mesh_lod_threshold = 0
	
	## Slowing down time for debug
	#Engine.time_scale = 0.05


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var planeBody = $DepthNormalSubViewport/PlaneScene/PlaneBody
	var planeForward : Vector3 = planeBody.get_node("Front").global_position - planeBody.global_position
	var planeUp : Vector3 = Vector3(0.0, 1.0, 0.0)
	
	var planeRight = planeForward.cross(planeUp)
	
	var planeFacingDir = planeRight.cross(planeUp)
	
	$FollowerCam.global_position = planeBody.global_position + (planeFacingDir.normalized() * cam_dist)
	$FollowerCam.global_position += Vector3(0.0, 0.5, 0.0) * cam_dist
	
	$FollowerCam.look_at_from_position($FollowerCam.global_position, planeBody.global_position)
