extends VehicleBody

var vel_right = 0
var vel_left = 0
var obstacle_name = "obstacle"
var ultrasonic_tradeoff = 2.7	# change it according to the position of ultrasonic in comparison to the player
# Tip for defining ultrasonic_tradeoff: put an object in front and make it so when it is diectly near it for the ultrasonic to be 0.
var middle_sensor = "MiddleContainer/Viewport/MiddleSensor"		# path to ground sensors (change it if needed).
var left_sensor = "LeftContainer/Viewport/LeftSensor"
var right_sensor = "RightContainer/Viewport/RightSensor"
var light_sensor = "LightContainer/Viewport/LightSensor"	# path to light sensor (change it if needed).
# rotation related:
var radians = 0
var target_ros = 0
var dir_id = -1
var final_rot_pos = 0

# acceleration - gyroscope related:
var accelerometer = Vector3(0, 0, 0)
var gyroscope = Vector3(0, 0, 0)

# player distance related:
var init_player_pos
var target_distance = 0
var sum_distance = 0

# ground sensor id:
var middle_sensor_id = 1
var right_sensor_id = 2
var left_sensor_id = 3

var make_noise = false
var time_on = false
var time = 0
# METHODS FOR WEBSOCKET CONNECTION ====================================
var client = WebSocketClient.new()
var url = "ws://localhost:5000"

func _ready():
	middle_sensor = get_node(middle_sensor)
	left_sensor = get_node(left_sensor)
	right_sensor = get_node(right_sensor)
	light_sensor = get_node(light_sensor)
	client.connect("data_received", self, "data_received")
	var err = client.connect_to_url(url)
	if err != OK:
		set_process(false)
		print("Unable to connect to server.")


func data_received():
	# BLOCK HERE FOR ROTATION TARGET DEGREES & TARGET DISTANCE (before radians = 0).
	radians = 0
	init_player_pos = self.global_transform.origin
	var pkt = client.get_peer(1).get_packet()
	var parsedJson: JSONParseResult = JSON.parse(pkt.get_string_from_ascii())
	var d = parsedJson.get_result()
	# print("Got data from server: " + pkt.get_string_from_utf8())
	# changes player's velocity accordind to input:
	var req_func = d["func"]
	if req_func == "move_forward":
		resume()	# ALWAYS add resume() when function is movement related!
		# Pattern here: velocity = (-) abs(in_velocity)
		vel_right = abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif req_func == "move_reverse":
		resume()
		vel_right = -abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])
	elif req_func == "rotate_clockwise":
		resume()
		vel_right = -abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif req_func == "rotate_counterclockwise":
		resume()
		vel_right = abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])
	elif req_func == "rotate_clockwise_deg":
		resume()
		var init_rot = rotation_degrees.y
		dir_id = 1
		target_ros = d["degree"]
		final_rot_pos = calc_final_rot(init_rot, target_ros, dir_id)
		#vel_right = -abs(d["vel_right"])
		#vel_left = abs(d["vel_left"])
	elif req_func == "rotate_counterclockwise_deg":
		resume()
		var init_rot = rotation_degrees.y
		dir_id = 0
		target_ros = d["degree"]
		final_rot_pos = calc_final_rot(init_rot, target_ros, dir_id)
		#vel_right = abs(d["vel_right"])
		#vel_left = -abs(d["vel_left"])
	elif req_func == "check_for_obstacle":
		send(get_ultrasonic(false))
	elif req_func == "get_distance":
		send(get_ultrasonic(true))
	elif req_func == "get_floor_sensor":
		send(get_floor_sensor(d["sensor_id"]))
	elif req_func == "check_on_line":
		send(check_on_line(d["sensor_id"], d["dark_value"]/100))
	elif req_func == "get_light_sensor":
		send(get_light_sensor())
	elif req_func == "check_for_dark":
		send(check_for_dark(d["light_val"]))
	elif req_func == "get_noise_detection":
		send(make_noise)
	elif req_func == "get_elapsed":
		send(time)
	#elif req_func == "get_position":
	#	print("Position requested.")
	#	var pos_x = self.global_transform.origin.x
	#	var pos_z = self.global_transform.origin.z
	#	var msg = "Player position = x: " + str(pos_x) + ", z: " + str(pos_z)
	#	send(msg)	# sends data back to server
	elif req_func == "move_forward_distance":
		resume()
		init_player_pos = self.global_transform.origin
		target_distance = abs(d["tar_dist"])
		vel_right = abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif req_func == "move_reverse_distance":
		resume()
		init_player_pos = self.global_transform.origin
		target_distance = abs(d["tar_dist"])
		vel_right = -abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])
	elif req_func == "rgb_set_color":
		change_rgb(d["color"])
	elif req_func == "get_acceleration":
		send_axis_vector(accelerometer, d["axis"])
	elif req_func == "get_gyroscope":
		send_axis_vector(gyroscope, d["axis"])
	elif req_func == "stop":	# stops
		stop()
		vel_right = 0
		vel_left = 0

func send(msg):
	client.get_peer(1).put_packet(JSON.print(msg).to_utf8())

# =======================================================================

func send_axis_vector(in_vector, axis: String):
	if axis == "x":
		send(in_vector.x)
	elif axis == "z":
		send(in_vector.z)
	elif axis == "y":
		send(in_vector.y)
	else:
		print("Unknown Axis!")
		send("0")

func _physics_process(delta):
	client.poll()	# used for websockets
	move(vel_right, vel_left)

	# PROXEIRO ====================================================
	## input func returns -1 and 1
	## steer = lerp(steer, Input.get_axis("right", "left") * 0.4, 5 * delta)
	## steering = steer
	## var acceleration = Input.get_axis("back", "forward")
	#var accel_right = -1	# change this variable for different motor velocity
	#var accel_left = -1 
	#move(accel_right, accel_left)
	## transform.origin.distance_to()
	## print(get_rotation_degrees())
	## var angle = get_rotation().y # gets rad rotation
	## get_rotation_degrees().y -> gets rotation in degrees.
	# =================================================================

	if target_ros > 0:
		rotate_degrees(target_ros, dir_id)

	if target_distance > 0:
		count_distance()

	# UPDATE OF COMPONENTS (VERY IMPORTANT TO BE HERE) ======================================
	update_all_camera_sensors()
	# updates values of accelerometer and gyro:
	update_accel_gyro(delta)
	# ============================================================================
	# print(get_darkness_percent(middle_sensor))
	if time_on:
		update_timer(delta)


func move(right_vel, left_vel):
	# var steer = 0
	var max_torque = 100	# change this if needed
	var max_rpm = 100
	var rpm = abs($"front-right-wheel".get_rpm())
	$"front-right-wheel".engine_force = (right_vel/100) * max_torque * (1 - rpm / max_rpm)
	rpm = abs($"front-left-wheel".get_rpm())
	$"front-left-wheel".engine_force = (left_vel/100) * max_torque * (1 - rpm / max_rpm)

var v0 = Vector3(0,0,0)
var r0 = Vector3(0,0,0)
func update_accel_gyro(delta):
	# source: https://godotengine.org/qa/69346/how-to-get-rigidbody2d-linear-acceleration
	# Calculates acceleration and gyroscope (USE it in physics process).
	#if v0 and r0:
	accelerometer  = (linear_velocity  - v0) / delta
	gyroscope = (angular_velocity - r0) / delta
	v0 = linear_velocity
	r0 = angular_velocity
	#print(accelerometer.z)
	#print(gyroscope)

var prev_mode = mode
func stop():
	# Stops the vehicle (to un-stop, call resume() method).
	prev_mode = mode
	mode = MODE_STATIC

func resume():
	# Call this immediately after stop().
	mode = prev_mode


func get_ultrasonic(calc_distance):
	# If cal_distance == false, just returns if ultrasonic has detected a static body.
	# If cal_distance == true, returns the distance of the nearest obstacle.
	# Parameters: calc_distance = boolean.
	var list_detect = $ultrasonic.get_overlapping_bodies()
	# iterate over the list of overlapping bodies
	var min_d = 10000
	for body in list_detect:
		if body.get_name() == obstacle_name:
			if !calc_distance:
				return true #if no calc_distance, just returns if the object is colliding with static.
			var player_position = self.global_transform.origin
			var body_position = body.global_transform.origin
			var distance = player_position.distance_to(body_position) - ultrasonic_tradeoff
			# print("Distance to ", body.get_name(), " is ", distance)
			if distance < min_d:
				min_d = distance
	if min_d == 10000 and !calc_distance:
		return false 	# no obstacle has been detected.
	return min_d

func get_darkness_percent(camera: Camera):
	# returns the percent value of dark color of input ground sensor.
	var texture = camera.get_viewport().get_texture()
	var image: Image = texture.get_data()
	image.resize(64,64)
	image.lock()
	var total_grayscale = 0

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c = image.get_pixel(x, y)
			# var grayscale = c.gray() -> deprecated
			var grayscale = c.v
			total_grayscale += grayscale

	return total_grayscale / (64 * 64)

func is_dark(camera: Camera, dark_threshold: float = 0.5):
	# returns true if input ground sensor is above dark color.
	if get_darkness_percent(camera) <= dark_threshold:
		return true
	else:
		return false

func get_light_sensor():
	# Returns the light sensor value (in range [0, 1024] like the previous simulator).
	# transform the percentage [0, 1] to [0, 1024] value just like old simulator.
	return get_darkness_percent(light_sensor) * 1024

func check_for_dark(light_val):
	# Returns true, if light_sensor is below light_val (aka it is dark).
	var gray_color = light_val / 1024	# converts gray to [0, 1] range.
	var val = get_darkness_percent(light_sensor)
	# grey == 50%, white == 100%, black <= 10%
	if val < gray_color:
		return true
	return false

func get_floor_sensor(sensor_id: int):
	if sensor_id == middle_sensor_id:
		return get_darkness_percent(middle_sensor)
	elif sensor_id == left_sensor_id:
		return get_darkness_percent(left_sensor)
	elif sensor_id == right_sensor_id:
		return get_darkness_percent(right_sensor)
	else:
		print('Requested sensor is out of bounds.')
		return 0.0

func check_on_line(sensor_id: int, dark_value: float):
	if sensor_id == middle_sensor_id:
		return is_dark(middle_sensor, dark_value)
	elif sensor_id == right_sensor_id:
		return is_dark(right_sensor, dark_value)
	elif sensor_id == left_sensor_id:
		return is_dark(left_sensor, dark_value)
	else:
		print('Requested sensor is out of bounds.')
		return false

func set_camera_sensor_pos(sensor: Camera, offset_x, offset_z, offset_y, offset_deg_x):
	# Used to update the input camera sensor (ground + light) position when the bot moves (recommended to be used in _physics_process).
	# Parameters: 
	#   sensor: the camera sensor to be moved (path).
	#	offset_x: the x position offset (position difference of main vehicle body, to wanted x position of camera sensor).
	#	offset_z: the z position offset (position difference of main vehicle body, to wanted z position of camera sensor).
	#	offset_y: the y position offset (position difference of main vehicle body, to wanted y position of camera sensor).
	# 	offset_deg_x: the rotation offset in x axis (rotation difference of main vehicle body, to wanted x position of camera sensor).
	# tip for setting offsets: move player to 0,0,0 (transform) and put the sensors in the right place -> their transform and rotation value is the offset.
	if abs(rotation_degrees.y) <= 90:
		sensor.global_translation.z = self.global_transform.origin.z - abs(offset_z)
		sensor.global_translation.x = self.global_transform.origin.x - abs(offset_x)
	else:
		sensor.global_translation.z = self.global_transform.origin.z + abs(offset_z)
		sensor.global_translation.x = self.global_transform.origin.x + abs(offset_x)
	#sensor.global_translation.z = self.global_transform.origin.z + offset_z
	#sensor.global_translation.x = self.global_transform.origin.x + offset_x
	sensor.global_translation.y = self.global_transform.origin.y + offset_y
	sensor.rotation = self.rotation
	sensor.rotation.x = offset_deg_x

func update_all_camera_sensors():
	# Updates all camera sensors (ground + light) position when the bot moves (MUST be to be used in _physics_process).
	# change offsets if needed -> see set_camera_sensor_pos documentation to understand what values to put.
	set_camera_sensor_pos(middle_sensor, 0, -1.45, -0.27, -90)
	set_camera_sensor_pos(right_sensor, 0.4, -1.45, -0.27, -90)
	set_camera_sensor_pos(left_sensor, -0.4, -1.45, -0.27, -90)
	set_camera_sensor_pos(light_sensor, 0.45, -1.6, 0, 0)

func change_rgb(color):
	var material = $led.get_surface_material(0)
	if color == 'red':
		material.albedo_color = Color(1, 0, 0)
	elif color == 'green':
		material.albedo_color = Color(0, 1, 0)
	elif color == 'blue':
		material.albedo_color = Color(0, 0, 1)
	elif color == 'white':
		material.albedo_color = Color(1, 1, 1)
	elif color == 'yellow':
		material.albedo_color = Color(1, 1, 0)
	elif color == 'cyan':
		material.albedo_color = Color(0, 1, 1)
	elif color == 'violet':
		material.albedo_color = Color(1, 0, 1)
	elif color == 'closed':
		material.albedo_color = Color(0, 0, 0)
	else:
		print('Uknown color!')
	$led.set_surface_material(0, material)

func rotate_degrees(degr: float, dir_id: int, rythm=0.01):
	# Rotates (slowly) the robot (USE IT IN PHYSICS_PROCESS)
	# Param: degr: the degrees to rotate it
	#		 dir_id: the direction to rotate it:
	#			counterclockwise: dir_id == 0	(left)
	#			clockwise: dir_id == 1	(right)
	# 		 rythm=0.01: the step for each rotation (decrease it for slower rotation)

	# TODO: block all incoming functions & when stop -> rotate player exactly to desired degree.
	if !dir_id:
		if radians < deg2rad(abs(degr)):
			radians += rythm
			rotate_object_local(Vector3(0, 1, 0), rythm)
			transform = transform.orthonormalized()
		else:
			#rotation_degrees.y = int(rotation_degrees.y)
			print(rotation_degrees.y)
			print(final_rot_pos)
			stop()
			rotation_degrees.y = final_rot_pos # sets either way to final position -> reduces float mistakes.
			target_ros = 0
			dir_id = -1
	else:
		if radians > -deg2rad(abs(degr)):
			radians -= rythm
			rotate_object_local(Vector3(0, 1, 0), -rythm)
			transform = transform.orthonormalized()
		else:
			#print(rad2deg(radians))
			#rotation_degrees.y = int(rotation_degrees.y)
			print(rotation_degrees.y)
			print(final_rot_pos)
			stop()
			rotation_degrees.y = final_rot_pos
			target_ros = 0
			dir_id = -1

func calc_final_rot(initial_rot: float, degrees_to_rotate: float, dir_id: int) -> float:
	# Calculates the final rotation position (call it before rotation to calculate final position of rotation).
	# Parameters: initial_rot: the initial position of player.
	#			  degrees_to_rotate: the target degrees to rotate.
	#			  dir_id: the direction id (1 == clockwise and 0 == counterclockwise).
	# Returns: the final rotation position of input rotation.
	var direction = 1
	if dir_id:	# clockwise rotation
		direction = -1
	# if dir_id == 0 (counterclockwise), the direction is 1.
	# Ensure initial_position is in the range [-180, 180)
	var normalized_position = fmod((initial_rot + 180), 360) - 180
	# Calculate final position
	var final_position = fmod((normalized_position + direction * degrees_to_rotate), 360)
	# Map final position to range [-180, 180)
	if final_position >= 180:
		final_position -= 360
	elif final_position < -180:
		final_position += 360
	return round(final_position)

func count_distance():
	# Counts distance until the target distance. If player reaches it -> stops
	# more here: https://www.youtube.com/watch?v=zFrKeEPmk2Q
	if sum_distance < target_distance:
		sum_distance += init_player_pos.distance_to(self.global_transform.origin)
		init_player_pos = self.global_transform.origin
		print(sum_distance)
	else:
		stop()
		sum_distance = 0
		target_distance = 0


func make_noise_btn():
	make_noise = !make_noise
	if make_noise:
		$noise_btn.text = "Stop Noise"
	else:
		$noise_btn.text = "Make Noise"

func update_timer(delta):
	# updates the timer (use it in physics process).
	time += delta
	var mils = fmod(time,1)*1000
	var secs = fmod(time,60)
	var mins = fmod(time, 60*60) / 60
	var hr = fmod(fmod(time,3600 * 60) / 3600,24)
	
	var time_passed = "%02d : %02d : %02d : %03d" % [hr,mins,secs,mils]
	$timer_label.text = time_passed# + " : " + var2str(time)

func _on_timer_btn_pressed():
	if !time_on:
		time = 0
		time_on = true
		$timer_btn.text = "Stop Timer"
	else:
		time_on = false
		$timer_btn.text = "Start Timer"

