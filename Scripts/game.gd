extends Node3D

@onready var world = $World
@onready var player_spawn = $PlayerSpawn
@onready var player = $PlayerSpawn/Player
@onready var start_menu = $StartMenu

@export var dev_mode = false

var regen_timer: Timer

func _ready():
	start_menu.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_menu.start_game.connect(start_new_game)
	
	setup_regen_timer()

	player.is_dev_mode = dev_mode

	if dev_mode:
		print("Developer mode is ON. Press 'P' to export the maze, 'R' to regenerate, and SPACE/CTRL to fly up/down.")
		Inventory.keys = 999 # Give player lots of keys for testing
		Inventory.batteries = 999 # Give player lots of batteries for testing

func setup_regen_timer():
	regen_timer = Timer.new()
	regen_timer.wait_time = 600.0 # 10 minutes
	regen_timer.one_shot = false
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)

func _on_regen_timer_timeout():
	print("10 minutes passed. Regenerating maze...")
	world.generate_world()
	spawn_player()
	connect_maze_signals()

func start_new_game():
	start_menu.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Generate the world and spawn the player
	world.generate_world()
	spawn_player()
	connect_maze_signals()
	regen_timer.start()

func _input(event):
	# Only allow export if dev_mode is true
	if dev_mode and event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_P: # Press 'P' to export
			export_current_maze()
		if event.keycode == KEY_X: # Press 'X' to regenerate
			world.generate_world()
			connect_maze_signals()
			spawn_player()
		if event.keycode == KEY_SPACE: # Fly mode
			player.global_position += Vector3(0, 2, 0) # Move player up by 5 units for testing
		if event.keycode == KEY_CTRL:
			player.global_position -= Vector3(0, 2, 0) # Move player down by 5 units for testing

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
func connect_maze_signals():
	var maze = world.maze
	if maze:
		 # Disconnect first if already connected, then reconnect cleanly
		if maze.player_won_global.is_connected(_on_player_win):
			maze.player_won_global.disconnect(_on_player_win)
		maze.player_won_global.connect(_on_player_win)

func _on_player_win():
	win_maze()

func win_maze():
	print("Congratulations! You've reached the exit!")
	
