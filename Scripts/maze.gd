extends Node3D

@onready var player_spawn = $"../../PlayerSpawn"
@onready var door_manager = $DoorManager
@onready var item_manager = $ItemManager

const WALL_SCENE = preload("res://World/Maze/Wall.tscn")
const EXIT_SCENE = preload("res://World/Maze/ExitGoal.tscn")
const TRAIL_MARKER = preload("res://World/Maze/TrailMarker.tscn")

@export var maze_width = 51
@export var maze_height = 51
@export var wall_spacing = 2.0
@export var loops = 30.0
@export var doors = 10

var maze = []
var exits: Array = []
var exit_cells: Array[Vector2i] = []
var exit_cell: Vector2i

func _ready():
	randomize()
	add_to_group("maze")

func generate_maze():
	clear_maze()
	exit_cells.clear()

	initialize_grid()
	carve_passages(1, 1)
	create_loops(maze_width * maze_height / loops)
	for i in range(2):	
		add_random_exit()	
	door_manager.spawn_doors(maze, maze_width, maze_height, wall_spacing, doors) # Spwan doors after exits so they can replace walls if needed
	build_maze() # Build maze after doors so they can replace walls if needed
	item_manager.spawn_items(maze, maze_width, maze_height, wall_spacing)

func clear_maze():
	clear_trail()
	for child in get_children():
		if child == door_manager or child == item_manager:
			continue  # don't free the door manager
		child.queue_free()
	
	# Clear doors separately
	door_manager.clear_doors()

func initialize_grid():
	maze.clear()

	for x in range(maze_width):
		maze.append([])
		for z in range(maze_height):
			maze[x].append(Globals.CELL_WALL) # Wall

func carve_passages(x, z):
	maze[x][z] = Globals.CELL_PATH

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
			if maze[nx][nz] == Globals.CELL_WALL:
				maze[x + int(dir.x / 2)][z + int(dir.y / 2)] = Globals.CELL_PATH
				carve_passages(nx, nz)

func create_loops(loop_count):
	for i in range(loop_count):

		var x = randi_range(1, maze_width - 2)
		var z = randi_range(1, maze_height - 2)

		# Only break walls
		if maze[x][z] == Globals.CELL_WALL:
			# Avoid destroying borders
			if x % 2 == 1 or z % 2 == 1:
				maze[x][z] = Globals.CELL_PATH

func add_random_exit():
	var exit_pos = Vector2i()
	var player_grid_pos = Vector2i(maze_width / 2, maze_height / 2)
	var min_distance = (maze_width + maze_height) / 4.0 # Roughly 25% of the total dimensions

	var found_valid_exit = false
	while not found_valid_exit:
		var side = randi() % 4
		match side:
			0: # left
				exit_pos = Vector2i(0, randi_range(1, maze_height - 2))
			1: # right
				exit_pos = Vector2i(maze_width - 1, randi_range(1, maze_height - 2))
			2: # top
				exit_pos = Vector2i(randi_range(1, maze_width - 2), 0)
			3: # bottom
				exit_pos = Vector2i(randi_range(1, maze_width - 2), maze_height - 1)
		
		# Check Manhattan distance from center
		var dist = abs(exit_pos.x - player_grid_pos.x) + abs(exit_pos.y - player_grid_pos.y)
		if dist >= min_distance:
			found_valid_exit = true

	# Open wall and mark as exit
	maze[exit_pos.x][exit_pos.y] = Globals.CELL_EXIT

	# Store exit position for spawning
	exit_cell = exit_pos
	exit_cells.append(exit_pos)
	
	spawn_exit()
	
func spawn_exit():
	var exit = EXIT_SCENE.instantiate()
	add_child(exit)

	exit.position = Vector3(
		exit_cell.x * wall_spacing,
		0,
		exit_cell.y * wall_spacing
	)
	exit.player_won.connect(_on_exit_triggered)
	exits.append(exit)

signal player_won_global

func _on_exit_triggered():
	emit_signal("player_won_global")

func build_maze():
	for x in range(maze_width):
		for z in range(maze_height):
			if maze[x][z] == Globals.CELL_WALL:
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

# =========================================================
# PATHFINDING FUNCTIONS
# =========================================================

func get_neighbors(cell: Vector2i) -> Array:
	var directions = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	var neighbors = []

	for dir in directions:
		var next = cell + dir

		if next.x >= 0 and next.x < maze_width and next.y >= 0 and next.y < maze_height:
			if maze[next.x][next.y] != Globals.CELL_WALL: # Walkable if NOT a wall
				neighbors.append(next)

	return neighbors

func reconstruct_path(came_from: Dictionary, start: Vector2i, goal: Vector2i) -> Array:
	var path = []
	var current = goal

	while current != start:
		path.push_front(current)
		current = came_from[current]

	path.push_front(start)
	return path

func bfs(start: Vector2i, goals: Array) -> Array:
	var queue = [start]
	var visited = {}
	var came_from = {}

	visited[start] = true

	while queue.size() > 0:
		var current = queue.pop_front()

		if current in goals:
			return reconstruct_path(came_from, start, current)

		for neighbor in get_neighbors(current):
			if not visited.has(neighbor):
				visited[neighbor] = true
				came_from[neighbor] = current
				queue.append(neighbor)

	return []

func get_path_to_nearest_exit(world_pos: Vector3) -> Array:
	var local_pos = to_local(world_pos)
	var start_cell = Vector2i(
		round(local_pos.x / wall_spacing),
		round(local_pos.z / wall_spacing)
	)
	
	# Ensure start_cell is within bounds
	start_cell.x = clamp(start_cell.x, 0, maze_width - 1)
	start_cell.y = clamp(start_cell.y, 0, maze_height - 1)
	
	var cell_path = bfs(start_cell, exit_cells)
	
	var world_path = []
	for cell in cell_path:
		world_path.append(to_global(Vector3(cell.x * wall_spacing, 0, cell.y * wall_spacing)))
		
	return world_path

var trail_nodes: Array = []

func clear_trail():
	for node in trail_nodes:
		if is_instance_valid(node):
			node.queue_free()
	trail_nodes.clear()

func spawn_trail(player_pos: Vector3):
	clear_trail()
	var path = get_path_to_nearest_exit(player_pos)

	if path.is_empty():
		print("No path found to any exit!")
		return

	for i in range(path.size()):
		if i % 2 != 0:
			continue

		var pos = path[i]
		var marker = TRAIL_MARKER.instantiate()

		get_parent().add_child(marker)
		marker.global_position = pos + Vector3(0, -1.5, 0)

		trail_nodes.append(marker)
