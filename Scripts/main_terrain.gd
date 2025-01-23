extends Node3D

var timer : Timer = Timer.new()
@onready var player : Node3D = get_parent().get_node("DepthSubViewport/PlaneScene")
var snap_step : int = 20
var player_pos : Vector3 # This is the player

var div : float = -1000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	add_child(timer)
	timer.connect("timeout", Callable(self, "snap"))
	timer.set_wait_time(1)
	snap()

func snap() -> void:
	# smallest face in blender is 0.39063
	player_pos = player.global_transform.origin.snapped(Vector3(snap_step, 0.0, snap_step))
	global_transform.origin.x = player_pos.x
	global_transform.origin.z = player_pos.z
	$MeshInstance3D.get_surface_override_material(0).set("shader_param/uvx", player_pos.x/div)
	$MeshInstance3D.get_surface_override_material(0).set("shader_param/uvy", player_pos.z/div)
	timer.start()
