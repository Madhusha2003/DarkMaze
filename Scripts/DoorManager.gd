extends Node3D

const DOOR_SCENE = preload("res://World/Door.tscn")

func spawn_doors(maze_data: Array, maze_width: int, maze_height: int, 
				 wall_spacing: float, count: int):  # no maze_origin
	var possible_positions = _find_door_positions(maze_data, maze_width, maze_height)
	possible_positions.shuffle()

	for i in range(min(count, possible_positions.size())):
		var d = possible_positions[i]
		_spawn_door(d.x, d.z, d.rotation, wall_spacing)
		maze_data[d.x][d.z] = Globals.CELL_DOOR

func _find_door_positions(maze_data: Array, maze_width: int, maze_height: int) -> Array:
	var positions = []
	for x in range(1, maze_width - 1):
		for z in range(1, maze_height - 1):
			if maze_data[x][z] != Globals.CELL_WALL:
				continue
			# Vertical corridor
			if maze_data[x][z-1] == Globals.CELL_WALL and maze_data[x][z+1] == Globals.CELL_WALL \
			and maze_data[x-1][z] == Globals.CELL_PATH and maze_data[x+1][z] == Globals.CELL_PATH:
				# Both open sides must be actual corridor (have open neighbors)
				if _is_corridor(maze_data, x-1, z) and _is_corridor(maze_data, x+1, z):
					positions.append({ "x": x, "z": z, "rotation": 0 })
			# Horizontal corridor
			elif maze_data[x-1][z] == Globals.CELL_WALL and maze_data[x+1][z] == Globals.CELL_WALL \
			and maze_data[x][z-1] == Globals.CELL_PATH and maze_data[x][z+1] == Globals.CELL_PATH:
				if _is_corridor(maze_data, x, z-1) and _is_corridor(maze_data, x, z+1):
					positions.append({ "x": x, "z": z, "rotation": 90 })
	return positions

# Check that a cell has at least 2 open neighbors (real corridor, not a dead end pocket)
func _is_corridor(maze_data: Array, x: int, z: int) -> bool:
	var open_neighbors = 0
	if maze_data[x-1][z] == Globals.CELL_PATH: open_neighbors += 1
	if maze_data[x+1][z] == Globals.CELL_PATH: open_neighbors += 1
	if maze_data[x][z-1] == Globals.CELL_PATH: open_neighbors += 1
	if maze_data[x][z+1] == Globals.CELL_PATH: open_neighbors += 1
	return open_neighbors >= 2

func _spawn_door(x: int, z: int, rotation_deg: float, 
				 wall_spacing: float):
	var door = DOOR_SCENE.instantiate()
	add_child(door)
	door.position = Vector3(x * wall_spacing, 0, z * wall_spacing)
	door.rotation_degrees.y = rotation_deg

func clear_doors():
	for child in get_children():
		child.queue_free()