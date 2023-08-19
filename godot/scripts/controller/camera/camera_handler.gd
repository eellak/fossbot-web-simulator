extends Spatial

export (NodePath) var stage

func _input(event):
	if event is InputEventMouseButton:
		if $cameraStage.current and event.is_action_pressed("camera_handle")  and event.pressed:
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
	# enables camera gimball, while also disabling all other cameras.
	$cameraOrth.disable_orth_cam()
	$cameraStage.current = false
	$CameraGimbal/InnerGimbal/Camera.current = true

func disable_player_cam():
	# enables orthogonal camera, while also disabling all other cameras.
	$cameraOrth.enable_orth_cam()
	$cameraStage.current = false
	$CameraGimbal/InnerGimbal/Camera.current = false

func enable_stage_cam():
	# enables stage camera, while also disabling all other cameras.
	if stage:
		# sets the size of the orth stage camera, to stage size.
		var stage_size = get_node(stage).mesh.get_aabb().size
		$cameraStage.size = max(stage_size.x, stage_size.z)
	$CameraGimbal/InnerGimbal/Camera.current = false
	$cameraOrth.disable_orth_cam()
	$cameraStage.current = true

func set_target(fossbot_path):
	# Sets the cameras to point to specified fossbot.
	# Param: fossbot_path: the path to the specified fossbot to point at.
	$cameraOrth.set_target(fossbot_path)
	$CameraGimbal.set_target(fossbot_path)
