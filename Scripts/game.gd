extends Node3D

@onready var world = $World
@onready var player_spawn = $PlayerSpawn

@export var dev_mode = false


func _ready():
	world.generate_maze()
	spawn_player()

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

func spawn_player():
	player_spawn.position = Vector3(
		position.x,
		1,
		position.z
	)