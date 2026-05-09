extends Node3D

const KEY_SCENE = preload("res://World/Key.tscn")

var pending_spawn: Array = []
var wall_spacing: float = 0.0


func spawn_items(maze_data: Array, width: int, height: int, spacing: float):
	clear_items()

	wall_spacing = spacing
	pending_spawn = _get_open_cells(maze_data, width, height)
	pending_spawn.shuffle()

	print("=== ITEM DEBUG ===")
	print("Open cells:", pending_spawn.size())

	call_deferred("_do_spawn")


func _do_spawn():
	_spawn(KEY_SCENE, 10, pending_spawn, wall_spacing, "Key")


func clear_items():
	print("ItemManager cleared:", get_child_count(), "items")
	for child in get_children():
		child.queue_free()


func _spawn(scene: PackedScene, count: int, cells: Array, spacing: float, label: String):
	var limit = min(count, cells.size())
	var spawned = 0

	for i in range(limit):
		var cell = cells[i]
		var item = scene.instantiate()
		add_child(item)

		item.position = Vector3(
			cell.x * spacing,
			0.5,
			cell.y * spacing
		)

		print(label, i, "->", item.position , "| ->" , item.global_position)
		spawned += 1

	print(label, "spawned:", spawned, "/", count)

	if spawned == 0:
		push_warning("No items spawned! Check maze or scene.")


func _get_open_cells(maze_data: Array, width: int, height: int) -> Array:
	var cells: Array = []

	var skipped_wall = 0
	var skipped_spawn = 0

	for x in range(1, width - 1):
		for z in range(1, height - 1):

			if maze_data[x][z] != 0:
				skipped_wall += 1
				continue

			if abs(x - 1) + abs(z - 1) <= 5:
				skipped_spawn += 1
				continue

			cells.append(Vector2i(x, z))

	print("Cells:", cells.size(),
		"| walls:", skipped_wall,
		"| spawn zone:", skipped_spawn)

	return cells