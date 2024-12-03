extends Node3D

# This code was taken from https://www.youtube.com/watch?v=rWeQ30h25Yg

class_name Chunk

var mesh_instance
var noiseObj
var x
var z
var chunk_size

func _init(noise, x, z, chunk_size) -> void:
	self.noiseObj = noise
	self.x = x
	self.z = z
	self.chunk_size = chunk_size

func generate_chunk(): 
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size * 0.5)
	plane_mesh.subdivide_depth = chunk_size * 0.5
	plane_mesh.subdivide_width = chunk_size * 0.5
	
	var surface_tool = SurfaceTool.new()
	var data_tool = MeshDataTool.new()
	
	surface_tool.create_from(plane_mesh, 0)
	
	var array_plane = surface_tool.commit()
	var error = data_tool.create_from_surface(array_plane, 0)
	
	for i in range(data_tool.get_vertex_count()) :
		var vertex = data_tool.get_vertex(i)
		
		vertex.y = noiseObj.get_noise_3d(vertex.x + x, vertex.y, vertex.z + z) * 80
		
		data_tool.set_vertex(i, vertex)
		
	
	for s in range(array_plane.get_surface_count()) :
		array_plane.surface_remove(s)
	
	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane, 0)
	surface_tool.generate_normals()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.create_trimesh_collision()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
