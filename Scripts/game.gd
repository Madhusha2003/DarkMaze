extends Node3D

@onready var world = $World
@onready var player_spawn = $PlayerSpawn

@export var dev_mode = false

const MAZE_SCENE = preload("res://World/Maze.tscn")

func _ready():
	pass

func _input(event):
	# Only allow export if dev_mode is true
	if dev_mode and event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_P: # Press 'P' to export
			export_current_maze()

func export_current_maze():
	# Find the maze inside the World node
	var maze = world.get_child(0)
	if maze and maze.has_method("export_to_scene"):
		maze.export_to_scene()
	else:
		print("No valid maze found to export.")

func load_and_center_maze():
	# Remove old maze if exists
	for child in world.get_children():
		child.queue_free()

	# Load maze scene
	var maze = MAZE_SCENE.instantiate()
	world.add_child(maze)

	# Wait one frame so children are fully loaded
	await get_tree().process_frame

	# Calculate bounds from all wall positions
	var min_pos = Vector3(INF, INF, INF)
	var max_pos = Vector3(-INF, -INF, -INF)

	for wall in maze.get_children():
		if wall is Node3D:
			var pos = wall.position
			min_pos.x = min(min_pos.x, pos.x)
			min_pos.z = min(min_pos.z, pos.z)

			max_pos.x = max(max_pos.x, pos.x)
			max_pos.z = max(max_pos.z, pos.z)

	# Center offset
	var maze_center = (min_pos + max_pos) / 2.0

	maze.position = Vector3(
		-maze_center.x,
		2,
		-maze_center.z
	)

	# Place player near maze entrance
	player_spawn.position = maze.position + Vector3(
		min_pos.x + 2,
		1,
		min_pos.z + 2
	)

