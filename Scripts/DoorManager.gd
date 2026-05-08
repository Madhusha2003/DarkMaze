extends Node3D

@onready var maze = $"../Maze"

const DOOR_SCENE = preload("res://World/Door.tscn")

func spawn_doors(count):
	var placed = 0

	while placed < count:
		var x = randi_range(1, maze.maze_width - 2)
		var z = randi_range(1, maze.maze_height - 2)

		if maze.maze[x][z] == 0: # path
			var door = DOOR_SCENE.instantiate()
			add_child(door)

			door.position = Vector3(
				x * maze.wall_spacing,
				0,
				z * maze.wall_spacing
			)

			placed += 1