extends CharacterBody3D

const SPEED = 5.0
const CAMERA_SENSITIVITY = 0.005

var gravity = 9.8
var pitch = 0.0

# Head bobbing variables
var bob_time = 0.0
var bob_speed = 8.0
var bob_amount = 0.05

var interact_distance = 3.0

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var flashlight = $CameraPivot/Camera3D/FlashLight

@onready var maze = get_tree().get_first_node_in_group("maze")

var flashlight_on = false

var dev_fly_mode = false

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
		
		# Trail Logic
		if event.keycode == KEY_G:
			if maze and maze.has_method("spawn_trail"):
				maze.spawn_trail(global_position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_interact()

func _physics_process(delta):
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	var current_speed = SPEED
	# Gravity
	if not is_on_floor() and not dev_fly_mode:
		velocity.y -= gravity * delta
	elif dev_fly_mode:
		velocity.y = 0
		current_speed *= 2.5 # Fly mode is faster


	# Movement input
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_up"):
		input_dir.z += 1
	if Input.is_action_pressed("run"):
		current_speed = SPEED * 1.5
		if dev_fly_mode:
			current_speed = SPEED * 3.75 # Fly mode run is even faster

	input_dir = input_dir.normalized()

	var camera_basis = global_transform.basis
	var forward = -camera_basis.z
	var right = camera_basis.x

	var direction = (right * input_dir.x) + (forward * input_dir.z)

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if is_moving and is_on_floor():
		bob_time += delta * bob_speed

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