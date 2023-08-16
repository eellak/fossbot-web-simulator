extends Camera

var target
export var zoom_speed = 0.5
export var move_speed = 0.5
export (float, 0.001, 1.0) var mouse_sensitivity = 0.05
onready var zoom = size

var translate_offset_x = 0
var translate_offset_z = 0
var mouse_control = false
export (bool) var invert_y = false
export (bool) var invert_x = false


func _input(event):
	if not current:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom -= zoom_speed
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom += zoom_speed
		size = zoom
		if event.is_action_pressed("camera_handle") and event.pressed:
			mouse_control = true
		elif event.is_action_released("camera_handle") and not event.pressed:
			mouse_control = false
	if mouse_control and event is InputEventMouseMotion:
		if event.relative.x != 0:
			var dir = 1 if invert_x else -1
			translate_offset_x += dir * event.relative.x * mouse_sensitivity
		if event.relative.y != 0:
			var dir = 1 if invert_y else -1
			translate_offset_z += dir * event.relative.y * mouse_sensitivity

func get_input_keyboard(delta):
	if Input.is_action_pressed("ui_down"):
		translate_offset_z += move_speed
	if Input.is_action_pressed("ui_up"):
		translate_offset_z += -move_speed
	if Input.is_action_pressed("ui_left"):
		translate_offset_x += -move_speed
	if Input.is_action_pressed("ui_right"):
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
	#translate_offset_x = 0
	#translate_offset_z = 0

func set_target(foss_target):
	target = foss_target



