extends Camera

export (NodePath) var target
export var zoom_speed = 0.5
export var move_speed = 0.5

onready var zoom = size

var translate_offset_x = 0
var translate_offset_z = 0

func _input(event):
	if not current:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom -= zoom_speed
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom += zoom_speed
		size = zoom

func get_input_keyboard(delta):
	if Input.is_action_pressed("cam_down"):
		translate_offset_z += move_speed
	if Input.is_action_pressed("cam_up"):
		translate_offset_z += -move_speed
	if Input.is_action_pressed("cam_left"):
		translate_offset_x += -move_speed
	if Input.is_action_pressed("cam_right"):
		translate_offset_x += move_speed


func _process(delta):
	if not current:
		return
	get_input_keyboard(delta)
	if target:
		var target_pos = get_node(target).global_transform.origin
		global_transform.origin.x = lerp(target_pos.x, target_pos.x + translate_offset_x, move_speed / 2)
		global_transform.origin.z = lerp(target_pos.z, target_pos.z + translate_offset_z, move_speed / 2)

func enable_orth_cam():
	current = true

func disable_orth_cam():
	current = false
	translate_offset_x = 0
	translate_offset_z = 0
