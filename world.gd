extends Node3D

# This code was taken from https://www.youtube.com/watch?v=rWeQ30h25Yg

const CHUNK_SIZE : int = 64
const CHUNK_AMOUNT : int = 16

var noise
var chunks = {}
var unready_chunks = {}
var selfThread : Thread

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.fractal_octaves = 6
	
	selfThread = Thread.new()

func add_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key) or unready_chunks.has(key):
		return
	
	if not selfThread.is_started():
		selfThread.start(load_chunk.bind(selfThread, x, z))
		unready_chunks[key] = 1

func load_chunk(thread, x, z) :
	
	var chunk = Chunk.new(noise, x * CHUNK_SIZE, z * CHUNK_SIZE, CHUNK_SIZE)
	chunk.position = Vector3(x * CHUNK_SIZE, 0, z * CHUNK_SIZE)
	
	call_deferred("load_done", chunk, thread)

func load_done(chunk, thread : Thread) -> void :
	var key = str(chunk.x / CHUNK_SIZE) + "," + str(chunk.z / CHUNK_SIZE)
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()

func get_chunk(x, z) :
	var key = str(x) + "," + str(z)
	if chunks.has(key) :
		return chunks.get(key)
	
	return null

func update_chunks() :
	
	#var player_pos = 
	#var p_x = int(player_pos.x) / CHUNK_SIZE
	#var p_z = int(player_pos.z) / CHUNK_SIZE
	#
	#for x in range(p_x - CHUNK_AMOUNT * 0.5, p_x + CHUNK_AMOUNT * 0.5) :
		#for z in range (p_z - CHUNK_AMOUNT * 0.5, p_z + CHUNK_AMOUNT * 0.5) :
			#add_chunk(x, z)
	pass

func clean_up_chunks() :
	pass

func reset_chunks() :
	pass

func _process(delta: float) -> void:
	update_chunks()
	clean_up_chunks()
	reset_chunks()
