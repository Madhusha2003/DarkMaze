extends Node3D

@onready var world = $World
@onready var player_spawn = $PlayerSpawn
@onready var player = $PlayerSpawn/Player

@export var dev_mode = false

func _ready():
	world.generate_maze()
	spawn_player()

	player.dev_fly_mode = dev_mode

func _input(event):
	# Only allow export if dev_mode is true
	if dev_mode and event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_P: # Press 'P' to export
			export_current_maze()
		if event.keycode == KEY_R: # Press 'R' to regenerate
			world.generate_maze()
			spawn_player()
		if event.keycode == KEY_SPACE: # Fly mode
			player.global_position += Vector3(0, 5, 0) # Move player up by 5 units for testing
		if event.keycode == KEY_CTRL:
			player.global_position -= Vector3(0, 5, 0) # Move player down by 5 units for testing

func export_current_maze():
	# Find the maze inside the World node
	var maze = world.get_child(0)
	if maze and maze.has_method("export_to_scene"):
		maze.export_to_scene()
	else:
		print("No valid maze found to export.")

func spawn_player():
	player_spawn.position = Vector3(
		position.x,
		1,
		position.z
	)
