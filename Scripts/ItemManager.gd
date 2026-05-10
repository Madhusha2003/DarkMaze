extends Node3D

const KEY_SCENE = preload("res://World/Items/Key.tscn")
const BATTERY_SCENE = preload("res://World/Items/Battery.tscn")

@export var min_item_distance: float = 6.0 # Minimum distance between spawned items

var pending_spawn: Array = []
var wall_spacing: float = 0.0
var maze_ref: Array = []
var spawned_positions: Array[Vector2i] = []


func spawn_items(maze_data: Array, width: int, height: int, spacing: float):
	clear_items()

	maze_ref = maze_data
	wall_spacing = spacing
	pending_spawn = _get_open_cells(maze_data, width, height)
	pending_spawn.shuffle()

	print("=== ITEM DEBUG ===")
	print("Open cells:", pending_spawn.size())

	call_deferred("_do_spawn")


func _do_spawn():
	_spawn(KEY_SCENE, 10, pending_spawn, wall_spacing, "Key")
	_spawn(BATTERY_SCENE, 15, pending_spawn, wall_spacing, "Battery")


func clear_items():
	print("ItemManager cleared:", get_child_count(), "items")
	for child in get_children():
		child.queue_free()
	spawned_positions.clear()


func _spawn(scene: PackedScene, count: int, cells: Array, spacing: float, label: String):
	var spawned = 0
	var i = 0
	
	while spawned < count and i < cells.size():
		var cell = cells[i]
		i += 1
		
		# Check distance against all already spawned positions
		var too_close = false
		for pos in spawned_positions:
			var world_pos = Vector2(cell.x * spacing, cell.y * spacing)
			var other_pos = Vector2(pos.x * spacing, pos.y * spacing)
			if world_pos.distance_to(other_pos) < min_item_distance:
				too_close = true
				break
		
		if too_close:
			continue

		var item = scene.instantiate()
		item.position = Vector3(
			cell.x * spacing,
			-0.5,
			cell.y * spacing
		)
		
		add_child(item)
		spawned_positions.append(cell)
		
		# Mark the maze array
		if maze_ref.size() > 0:
			maze_ref[cell.x][cell.y] = Globals.CELL_ITEM

		print(label, spawned, "->", item.position , "| ->" , item.global_position)
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

			if maze_data[x][z] != Globals.CELL_PATH:
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