extends Area3D

const ROTATION_SPEED = 2.0
const BOB_SPEED = 2.0
const BOB_HEIGHT = 0.2

var start_y: float = 0.0
var time_passed: float = 0.0

func _ready():
	call_deferred("_init_positions")
	# Connect the body_entered signal to allow picking up by walking into it
	body_entered.connect(_on_body_entered)

	while true:
		await get_tree().create_timer(5.0).timeout
		print("Key position:", global_position, "| Local:", position)

func _init_positions():
	start_y = global_position.y

func _process(delta):
	# Spin the key
	rotation.y += ROTATION_SPEED * delta
	
	# Bob the key up and down
	time_passed += delta
	global_position.y = start_y + sin(time_passed * BOB_SPEED) * BOB_HEIGHT

func _on_body_entered(body):
	if body.name == "Player":
		Inventory.add_key()
		queue_free()

func interact():
	# Allow picking up by clicking/interacting as well
	Inventory.add_key()
	queue_free()
