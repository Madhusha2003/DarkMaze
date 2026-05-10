extends CharacterBody3D

const SPEED = 5.0
const CAMERA_SENSITIVITY = 0.005

var gravity = 9.8
var pitch = 0.0

# Head bobbing variables
var bob_time = 0.0
var bob_speed = 8.0
var bob_run_speed = 12.0
var bob_amount = 0.05

var player_energy = 100.0
var max_player_energy = 100.0
var stamina_consumption_rate = 20.0 # Energy per second while running
var stamina_recovery_rate = 10.0 # Energy per second while idle

signal player_energy_changed(current, max)

var interact_distance = 3.0

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var flashlight = $CameraPivot/Camera3D/FlashLight
@onready var footstep_player = $FootStepPlayer

@export var footstep_sounds: Array[AudioStream]
@export var walk_interval := 0.45
@export var run_interval := 0.3
var step_timer := 0.0
var current_step_index := 0



@onready var maze = get_tree().get_first_node_in_group("maze")

var flashlight_on = false
var flashlight_energy = 120.0
var max_flashlight_energy = 120.0
var battery_refill_amount = 60.0
var energy_consumption_rate = 2.0 # Energy per second

@onready var base_light_energy = flashlight.light_energy

signal flashlight_energy_changed(current, max)

var is_dev_mode = false

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:	
		if event is InputEventMouseMotion:
			# Rotate the player horizontally
			rotation.y -= event.relative.x * CAMERA_SENSITIVITY

			# Rotate the camera vertically
			pitch -= event.relative.y * CAMERA_SENSITIVITY
			pitch = clamp(pitch, deg_to_rad(-90), deg_to_rad(90))
			camera_pivot.rotation.x = pitch

# Release the mouse when the Escape key is pressed
func _input(event):
	if event is InputEventKey and event.is_pressed():
		# Mouse Toggle Logic
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# Flashlight Logic
		if event.keycode == KEY_F:
			flashlight_on = !flashlight_on
			flashlight.visible = flashlight_on
		
		# Manual Battery usage
		if event.keycode == KEY_R:
			if flashlight_energy < max_flashlight_energy:
				if Inventory.use_battery():
					flashlight_energy = min(flashlight_energy + battery_refill_amount, max_flashlight_energy)
					emit_signal("flashlight_energy_changed", flashlight_energy, max_flashlight_energy)
					print("Battery used manually. Energy: ", flashlight_energy)
				else:
					print("No batteries in inventory!")
			else:
				print("Flashlight energy already full.")
		
		# Trail Logic
		if event.keycode == KEY_G and is_dev_mode:
			if maze and maze.has_method("spawn_trail"):
				maze.spawn_trail(global_position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_interact()

func _physics_process(delta):
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	var is_running = Input.is_action_pressed("run") and is_moving and player_energy > 0
	
	# Handle Energy Consumption/Recovery
	if is_running and not is_dev_mode:
		player_energy -= stamina_consumption_rate * delta
		if player_energy < 0: player_energy = 0
		emit_signal("player_energy_changed", player_energy, max_player_energy)
	elif not is_running and player_energy < max_player_energy and not is_dev_mode:
		player_energy += stamina_recovery_rate * delta
		if player_energy > max_player_energy: player_energy = max_player_energy
		emit_signal("player_energy_changed", player_energy, max_player_energy)

	# Sound Effects
	if is_moving and is_on_floor():
		step_timer -= delta
		if step_timer <= 0:
			play_footstep(is_running)
			step_timer = run_interval if is_running else walk_interval
	else:
		step_timer = 0.0

	# Calculate Speed
	var current_speed = SPEED
	
	if is_running:
		current_speed *= 1.5
		if is_dev_mode:
			current_speed = SPEED * 3.75 # Keep dev mode multiplier consistent
	
	if player_energy <= 0 and not is_dev_mode:
		current_speed *= 0.5 # Exhaustion penalty
	
	if is_dev_mode:
		current_speed *= 2.5 # Base fly mode speed boost
	
	# Gravity
	if not is_on_floor() and not is_dev_mode:
		velocity.y -= gravity * delta
	elif is_dev_mode:
		velocity.y = 0

	# Movement input
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("ui_right"): input_dir.x += 1
	if Input.is_action_pressed("ui_left"): input_dir.x -= 1
	if Input.is_action_pressed("ui_down"): input_dir.z -= 1
	if Input.is_action_pressed("ui_up"): input_dir.z += 1
	
	input_dir = input_dir.normalized()

	var camera_basis = global_transform.basis
	var forward = -camera_basis.z
	var right = camera_basis.x

	var direction = (right * input_dir.x) + (forward * input_dir.z)

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Flashlight energy consumption
	if flashlight_on:
		if flashlight_energy > 0:
			flashlight_energy -= energy_consumption_rate * delta
			if flashlight_energy <= 0:
				flashlight_energy = 0
				# Try automatic battery use if available when hitting 0
				if Inventory.use_battery():
					flashlight_energy = battery_refill_amount
					print("Battery used automatically. Energy: ", flashlight_energy)
		
		# Calculate target light intensity
		var target_intensity = base_light_energy
		if flashlight_energy <= 0:
			target_intensity = 0.05 # "Super low" emergency light
		elif flashlight_energy < 20.0:
			# Proportional dimming from 20 down to 0
			var ratio = flashlight_energy / 20.0
			target_intensity = lerp(0.05, base_light_energy, ratio)
		
		flashlight.light_energy = lerp(flashlight.light_energy, target_intensity, delta * 2.0)
		
		emit_signal("flashlight_energy_changed", flashlight_energy, max_flashlight_energy)
	else:
		# Reset intensity for next time it's turned on, or keep it consistent
		flashlight.light_energy = lerp(flashlight.light_energy, base_light_energy, delta * 2.0)

	if is_moving and is_on_floor():
		var current_bob_speed = bob_run_speed if is_running else bob_speed
		bob_time += delta * current_bob_speed

		var bob_offset = sin(bob_time) * bob_amount
		camera_pivot.position.y = 1.6 + bob_offset
	else:
		bob_time = 0
		camera_pivot.position.y = lerp(camera_pivot.position.y, 1.6, delta * 5)

	move_and_slide()

func _try_interact():
	# Only interact when mouse is captured (playing)
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	
	var space = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * interact_distance)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collide_with_areas = true
	
	var result = space.intersect_ray(query)
	
	if result and result.collider:
		var interactable_item = _find_interactable(result.collider)
		if interactable_item:
			interactable_item.interact()

func _find_interactable(node: Node) -> Node:
	var current = node
	while current and current != get_tree().root:
		if current.has_method("interact"):
			return current
		current = current.get_parent()
	return null

func play_footstep(is_running_state: bool):
	if footstep_sounds.is_empty():
		return

	footstep_player.stream = footstep_sounds[current_step_index]
	
	if is_running_state:
		footstep_player.pitch_scale = randf_range(1.5, 1.7)
		footstep_player.volume_db = 16.0
	else:
		footstep_player.pitch_scale = randf_range(0.9, 1.1)
		footstep_player.volume_db = 6.0
		
	footstep_player.play()
	current_step_index = (current_step_index + 1) % footstep_sounds.size()
