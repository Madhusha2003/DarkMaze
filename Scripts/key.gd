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

func _init_positions():
	start_y = global_position.y
		# Adjust mesh position to center it (AABB indicates it's offset in the model)
	if has_node("Mesh"):
		$Mesh.position.y = 0.31

func _physics_process(delta):
	# Spin the key
	rotation.y += ROTATION_SPEED * delta
	
	# Bob the key up and down
	time_passed += delta
	global_position.y = start_y + sin(time_passed * BOB_SPEED) * BOB_HEIGHT

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Key collected by: ", body.name)
		Inventory.add_key()
		queue_free()

func interact():
	# Allow picking up by clicking/interacting as well
	Inventory.add_key()
	queue_free()
