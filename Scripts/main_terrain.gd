extends Node3D

var timer : Timer = Timer.new() # Timer to update the position of the clipmap mesh every second.

@onready var player : Node3D = get_parent().get_node("DepthNormalSubViewport/PlaneScene")

var snap_step : int = 20 # This is the height/width of a grid cell.
var player_pos : Vector3 # This is the player's approximated position on a grid.

var div : float = 20 * 50 * self.scale.x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	add_child(timer)
	timer.connect("timeout", Callable(self, "snap"))
	timer.set_wait_time(1)
	snap() # Called one second after the timer is started.

func snap() -> void:
	# Finding the player's position if it was snapped to a grid.
	player_pos = player.global_transform.origin.snapped(Vector3(snap_step, 0.0, snap_step))
	
	# Snapping the mesh to that position on the "grid".
	global_transform.origin.x = player_pos.x
	global_transform.origin.z = player_pos.z
	
	# Modifying the uvs of the heightmap on the mesh to smooth out the snapping and to create the 
	# "infinite" illusion.
	$ClipMapMesh.get_surface_override_material(0).set_shader_parameter("uvx", player_pos.x/div)
	$ClipMapMesh.get_surface_override_material(0).set_shader_parameter("uvy", player_pos.z/div)
	
	timer.start() # The timer is restarted after snapping the player to the grid
