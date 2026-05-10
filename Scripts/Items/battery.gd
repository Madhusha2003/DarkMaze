extends StaticBody3D

const ROTATION_SPEED = 2.0
const BOB_SPEED = 2.0
const BOB_HEIGHT = 0.2

var start_y: float = 0.0
var time_passed: float = 0.0

func _ready():
	call_deferred("_init_positions")	

func _init_positions():
	start_y = global_position.y

func _physics_process(delta):
	# Spin the battery
	rotation.y += ROTATION_SPEED * delta
	
	# Bob the battery up and down
	time_passed += delta
	global_position.y = start_y + sin(time_passed * BOB_SPEED) * BOB_HEIGHT

func interact():
	# Allow picking up by clicking/interacting as well
	Inventory.add_battery()
	queue_free()