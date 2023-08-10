extends Spatial


func _process(delta):
	if Input.is_action_pressed("camera_player"):
		$cameraOrth.disable_orth_cam()
		$CameraGimbal/InnerGimbal/Camera.current = true
	elif Input.is_action_pressed("camera_orth"):
		$cameraOrth.enable_orth_cam()
		$CameraGimbal/InnerGimbal/Camera.current = false
