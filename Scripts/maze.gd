extends Node3D

@onready var player_spawn = $"../../PlayerSpawn"

const WALL_SCENE = preload("res://World/Wall.tscn")
const DOOR_SCENE = preload("res://World/Door.tscn")
const EXIT_SCENE = preload("res://World/ExitGoal.tscn")

@export var maze_width = 51
@export var maze_height = 51
@export var wall_spacing = 2.0
@export var loops = 30.0
@export var doors = 10

var maze = []
var exit_cell: Vector2i

func _ready():
	randomize()

func generate_maze():
	clear_maze()

	initialize_grid()
	carve_passages(1, 1)
	create_loops(maze_width * maze_height / loops)
	add_random_exit()
	spawn_doors(doors)
	build_maze()

func clear_maze():
	for child in get_children():
		child.queue_free()

func initialize_grid():
	maze.clear()

	for x in range(maze_width):
		maze.append([])
		for z in range(maze_height):
			maze[x].append(1) # Wall

func carve_passages(x, z):
	maze[x][z] = 0

	var directions = [
		Vector2(2, 0),
		Vector2(-2, 0),
		Vector2(0, 2),
		Vector2(0, -2)
	]

	directions.shuffle()

	for dir in directions:
		var nx = x + int(dir.x)
		var nz = z + int(dir.y)

		if nx > 0 and nz > 0 and nx < maze_width - 1 and nz < maze_height - 1:
			if maze[nx][nz] == 1:
				maze[x + int(dir.x / 2)][z + int(dir.y / 2)] = 0
				carve_passages(nx, nz)

func create_loops(loop_count):
	for i in range(loop_count):

		var x = randi_range(1, maze_width - 2)
		var z = randi_range(1, maze_height - 2)

		# Only break walls
		if maze[x][z] == 1:
			# Avoid destroying borders
			if x % 2 == 1 or z % 2 == 1:
				maze[x][z] = 0

func add_random_exit():
	var side = randi() % 4
	var exit_pos = Vector2i()

	match side:
		0: # left
			exit_pos = Vector2i(0, randi_range(1, maze_height - 2))
		1: # right
			exit_pos = Vector2i(maze_width - 1, randi_range(1, maze_height - 2))
		2: # top
			exit_pos = Vector2i(randi_range(1, maze_width - 2), 0)
		3: # bottom
			exit_pos = Vector2i(randi_range(1, maze_width - 2), maze_height - 1)

	# Open wall
	maze[exit_pos.x][exit_pos.y] = 0

	# Store exit position for spawning
	exit_cell = exit_pos
	
	spawn_exit()
	
func spawn_exit():
	var exit = EXIT_SCENE.instantiate()
	add_child(exit)

	exit.position = Vector3(
		exit_cell.x * wall_spacing,
		0,
		exit_cell.y * wall_spacing
	)

func build_maze():
	for x in range(maze_width):
		for z in range(maze_height):
			if maze[x][z] == 1:
				var wall = WALL_SCENE.instantiate()
				add_child(wall)

				wall.position = Vector3(
					x * wall_spacing,
					0,
					z * wall_spacing
				)

func center_maze():
	var total_width = (maze_width - 1) * wall_spacing
	var total_height = (maze_height - 1) * wall_spacing

	position = Vector3(
		-total_width / 2,
		2,
		-total_height / 2
	)

# ---------------
# Doors
# ---------------
func spawn_doors(count):
	var possible_positions = []

	for x in range(1, maze_width - 1):
		for z in range(1, maze_height - 1):

			if maze[x][z] != 1:
				continue

			# Vertical wall
			if maze[x][z - 1] == 1 and maze[x][z + 1] == 1 and maze[x - 1][z] == 0 and maze[x + 1][z] == 0:
				possible_positions.append({
					"x": x,
					"z": z,
					"rotation": 0
				})

			# Horizontal wall
			elif maze[x - 1][z] == 1 and maze[x + 1][z] == 1 and maze[x][z - 1] == 0 and maze[x][z + 1] == 0:
				possible_positions.append({
					"x": x,
					"z": z,
					"rotation": 90
				})

	possible_positions.shuffle()

	for i in range(min(count, possible_positions.size())):
		var door_data = possible_positions[i]
		spawn_door(door_data.x, door_data.z, door_data.rotation)


func spawn_door(x, z, rotation_deg):
	var door = DOOR_SCENE.instantiate()
	add_child(door)

	door.position = Vector3(
		x * wall_spacing,
		0,
		z * wall_spacing
	)

	door.rotation_degrees.y = rotation_deg

	# Remove wall from maze data
	maze[x][z] = 0

func export_to_scene():
	# 1. Create a new PackedScene object
	var scene = PackedScene.new()
	
	# 2. Set the 'owner' of all children to this node
	# This is required for Godot to know which nodes belong in the scene file
	for child in get_children():
		child.owner = self
	
	# 3. Pack the current node (and its owned children)
	var result = scene.pack(self)
	
	if result == OK:
		# 4. Save to your file system
		var path = "res://World/GeneratedMaze.tscn"
		var save_error = ResourceSaver.save(scene, path)
		
		if save_error == OK:
			print("Maze exported successfully to: ", path)
		else:
			print("Error saving scene: ", save_error)
	else:
		print("Error packing scene.")
