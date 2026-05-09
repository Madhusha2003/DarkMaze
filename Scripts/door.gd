extends StaticBody3D

@export var open_speed = 2.0
@export var open_offset = Vector3(0, 3, 0) # How far it moves
@export var close_offset = Vector3.ZERO

var is_open = false
var is_animating = false
var closed_global_pos: Vector3
var open_global_pos: Vector3

func _ready():
	call_deferred("_init_positions")

func _init_positions():
	closed_global_pos = global_position
	open_global_pos = global_position + open_offset

func interact():
	if is_animating:
		return
	
	if is_open:
		close_door()
		return
	
	if Inventory.has_key():
		Inventory.use_key()
		open_door()
	else:
		print("You need a key!")

func open_door():
	is_animating = true
	var tween = create_tween()
	
	# Simpler way to animate a property
	tween.tween_property(self, "global_position", open_global_pos, open_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.finished.connect(func():
		is_open = true
		is_animating = false
	)

func close_door():
	if not is_open or is_animating:
		return
	
	is_animating = true
	var tween = create_tween()
	
	tween.tween_property(self, "global_position", closed_global_pos, open_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		is_open = false
		is_animating = false
	)
