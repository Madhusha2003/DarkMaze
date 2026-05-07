extends CharacterBody3D

const SPEED = 5.0
const CAMERA_SENSITIVITY = 0.005

var gravity = 9.8
var pitch = 0.0

# Head bobbing variables
var bob_time = 0.0
var bob_speed = 8.0
var bob_amount = 0.05

@onready var camera_pivot = $CameraPivot
@onready var flashlight = $CameraPivot/Camera3D/FlashLight

var flashlight_on = false

func _ready():
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

func _physics_process(delta):
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

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

	input_dir = input_dir.normalized()

	var camera_basis = global_transform.basis
	var forward = -camera_basis.z
	var right = camera_basis.x

	var direction = (right * input_dir.x) + (forward * input_dir.z)

	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	if is_moving and is_on_floor():
		bob_time += delta * bob_speed

		var bob_offset = sin(bob_time) * bob_amount
		camera_pivot.position.y = 1.6 + bob_offset
	else:
		bob_time = 0
		camera_pivot.position.y = lerp(camera_pivot.position.y, 1.6, delta * 5)

	move_and_slide()
