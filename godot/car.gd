extends VehicleBody

func _physics_process(delta):
	# input func returns -1 and 1
	# steer = lerp(steer, Input.get_axis("right", "left") * 0.4, 5 * delta)
	#steering = steer
	# var acceleration = Input.get_axis("back", "forward")
	var accel_right = -1	# change this variable for different motor velocity
	var accel_left = -1 
	move(accel_right, accel_left)
	# transform.origin.distance_to()
	# print(get_rotation_degrees())
	# var angle = get_rotation().y # gets rad rotation
	# get_rotation_degrees().y -> gets rotation in degrees.

func move(right_vel, left_vel):
	# var steer = 0
	var max_torque = 100	# change this if needed
	var max_rpm = 100
	var rpm = abs($"front-right-wheel".get_rpm())
	$"front-right-wheel".engine_force = right_vel * max_torque * (1 - rpm / max_rpm)
	rpm = abs($"front-left-wheel".get_rpm())
	$"front-left-wheel".engine_force = left_vel * max_torque * (1 - rpm / max_rpm)
