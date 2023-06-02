extends VehicleBody

var steer = 0
var max_torque = 100
var max_rpm = 500

func _physics_process(delta):
	# input func returns -1 and 1
	# steer = lerp(steer, Input.get_axis("right", "left") * 0.4, 5 * delta)
	#steering = steer
	var acceleration = Input.get_axis("back", "forward")
	var rpm = abs($"back-left-wheel".get_rpm())
	$"back-left-wheel".engine_force = 0.5 * max_torque * (1 - rpm / max_rpm)
	rpm = abs($"back-right-wheel".get_rpm())
	$"back-right-wheel".engine_force = 1 * max_torque * (1 - rpm / max_rpm)

