extends Node3D

@onready var player_spawn = $"../PlayerSpawn"
@onready var maze = $Maze

const MAZE_SCENE = preload("res://World/Maze.tscn")

func _ready():
	pass

func generate_maze():
	maze.generate_maze()
	center_maze(maze, true)

func center_maze(maze_node: Node3D, is_generated: bool):
	if is_generated:
		# -------------------------
		# CASE 1: GENERATED MAZE
		# -------------------------
		maze.center_maze()

	else:
		# -------------------------
		# CASE 2: LOADED SCENE MAZE
		# -------------------------
		var min_pos = Vector3(INF, INF, INF)
		var max_pos = Vector3(-INF, -INF, -INF)

		for child in maze_node.get_children():
			if child is Node3D:
				var p = child.position
				min_pos.x = min(min_pos.x, p.x)
				min_pos.z = min(min_pos.z, p.z)

				max_pos.x = max(max_pos.x, p.x)
				max_pos.z = max(max_pos.z, p.z)

		var center = (min_pos + max_pos) / 2.0

		maze_node.position = Vector3(
			- center.x,
			2,
			- center.z
)
