extends Spatial

export (NodePath) var stage

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			enable_player_cam()
			$CameraGimbal.enable_mouse_control()

func _process(delta):
	if Input.is_action_pressed("camera_player"):
		enable_player_cam()
	elif Input.is_action_pressed("camera_orth"):
		disable_player_cam()
	elif Input.is_action_pressed("camera_stage"):
		enable_stage_cam()

func enable_player_cam():
	$cameraOrth.disable_orth_cam()
	$cameraStage.current = false
	$CameraGimbal/InnerGimbal/Camera.current = true

func disable_player_cam():
	$cameraOrth.enable_orth_cam()
	$cameraStage.current = false
	$CameraGimbal/InnerGimbal/Camera.current = false

func enable_stage_cam():
	if stage:
		# sets the size of the orth stage camera, to stage size.
		var stage_size = get_node(stage).mesh.get_aabb().size
		$cameraStage.size = max(stage_size.x, stage_size.z)
	$CameraGimbal/InnerGimbal/Camera.current = false
	$cameraOrth.disable_orth_cam()
	$cameraStage.current = true
