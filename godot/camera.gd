extends Spatial

export (NodePath) var target

export (float, 0.0, 2.0) var rotation_speed = PI/2

# mouse properties
var mouse_control = false
export (float, 0.001, 0.1) var mouse_sensitivity = 0.005
export (bool) var invert_y = false
export (bool) var invert_x = false

# zoom settings
export (float) var max_zoom = 5.0
export (float) var min_zoom = 0.4
export (float, 0.05, 1.0) var zoom_speed = 0.09

var zoom = 1.5

func _input(event):
	if not $InnerGimbal/Camera.current:
		return
	if event is InputEventMouseButton:
		if event.is_action_pressed("camera_handle") and event.pressed:
			mouse_control = true
		elif event.is_action_released("camera_handle") and not event.pressed:
			mouse_control = false
		if event.button_index == BUTTON_WHEEL_UP:
			zoom -= zoom_speed
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom += zoom_speed
	zoom = clamp(zoom, min_zoom, max_zoom)
	if mouse_control and event is InputEventMouseMotion:
		if event.relative.x != 0:
			var dir = 1 if invert_x else -1
			rotate_object_local(Vector3.UP, dir * event.relative.x * mouse_sensitivity)
		if event.relative.y != 0:
			var dir = 1 if invert_y else -1
			var y_rotation = clamp(event.relative.y, -30, 30)
			$InnerGimbal.rotate_object_local(Vector3.RIGHT, dir * y_rotation * mouse_sensitivity)

func get_input_keyboard(delta):
	# Rotate outer gimbal around y axis
	var y_rotation = 0
	if Input.is_action_pressed("ui_right"):
		y_rotation += 1
	if Input.is_action_pressed("ui_left"):
		y_rotation += -1
	rotate_object_local(Vector3.UP, y_rotation * rotation_speed * delta)
	# Rotate inner gimbal around local x axis
	var x_rotation = 0
	if Input.is_action_pressed("ui_up"):
		x_rotation += -1
	if Input.is_action_pressed("ui_down"):
		x_rotation += 1
	x_rotation = -x_rotation if invert_y else x_rotation
	$InnerGimbal.rotate_object_local(Vector3.RIGHT, x_rotation * rotation_speed * delta)

func _process(delta):
	if not $InnerGimbal/Camera.current:
		return
	if !mouse_control:
		get_input_keyboard(delta)
	$InnerGimbal.rotation.x = clamp($InnerGimbal.rotation.x, -1.45, -0.01)
	scale = lerp(scale, Vector3.ONE * zoom, zoom_speed)
	if target:
		global_transform.origin = get_node(target).global_transform.origin

func enable_mouse_control():
	if not mouse_control:
		mouse_control = true
