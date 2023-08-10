extends VehicleBody

var vel_right = 0
var vel_left = 0
var ultrasonic_tradeoff = 1.9	# change it according to the position of ultrasonic in comparison to the player
# Tip for defining ultrasonic_tradeoff: put an object in front and make it so when it is diectly near it for the ultrasonic to be 0.
onready var middle_sensor = $MiddleSensor/MiddleContainer/Viewport/MiddleSensor
onready var left_sensor = $LeftSensor/LeftContainer/Viewport/LeftSensor
onready var right_sensor = $RightSensor/RightContainer/Viewport/RightSensor
onready var light_sensor = $LightSensor/LightContainer/Viewport/LightSensor
# rotation related:
var radians = 0
var target_ros = 0
var dir_id = -1
var final_rot_pos = 0

# time for rotation x degrees:
var time_curr_ros = 0
var time_target_ros = -1

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
# timer variables
var time_on = false
var time = 0

# music (and its loop handling) related:
var wait_time = -1
var music = null
var prev_music_pos = -1
var curr_music_pos = 0

# direction of motors
var move_dir = "forward"

# Set this to false if not horizontal ground in scene (you can also do it from editor!)
export(bool) var horizontal_ground = true

export(float) var max_rpm = 100.0
var reduce_speed_rot_percent = 0.2	# 20 percent of initial torque for rotation (slows rotation).

var sum_rot = 0
# VARS FOR WEBSOCKET CONNECTION ====================================
var client = WebSocketClient.new()

var url = "ws://localhost:5000"

func _ready():
	_on_horizontal_ground_changed()
	client.connect("data_received", self, "data_received")
	var err = client.connect_to_url(url)
	if err != OK:
		set_process(false)
		print("Unable to connect to server.")


func data_received():
	# Handles all data received from server.
	var pkt = client.get_peer(1).get_packet()
	sum_distance = 0
	target_distance = -1
	radians = 0
	init_player_pos = self.global_transform.origin
	var parsedJson: JSONParseResult = JSON.parse(pkt.get_string_from_ascii())
	var d = parsedJson.get_result()
	# print("Got data from server: " + pkt.get_string_from_utf8())
	var req_func = d["func"]
	if req_func == "move_forward":
		just_move(d, "forward")
	elif req_func == "move_reverse":
		just_move(d, "reverse")
	elif req_func == "just_move":
		var tmp_move_dir = d["direction"]
		if tmp_move_dir != "forward" and tmp_move_dir != "reverse":
			print("Motor accepts only forward and reverse values.")
			return
		just_move(d, tmp_move_dir)
	elif req_func == "move_distance":
		var tmp_move_dir = d["direction"]
		if tmp_move_dir != "forward" and tmp_move_dir != "reverse":
			print("Motor accepts only forward and reverse values.")
			return
		move_distance(d, tmp_move_dir)
	elif req_func == "move_forward_distance":
		move_distance(d, "forward")
	elif req_func == "move_reverse_distance":
		move_distance(d, "reverse")
	elif req_func == "move_forward_default":
		d["tar_dist"] = d["def_dist"]
		move_distance(d, "forward")
	elif req_func == "move_reverse_default":
		d["tar_dist"] = d["def_dist"]
		move_distance(d, "reverse")
	elif req_func == "rotate_clockwise":
		resume()
		dir_id = 1
		vel_right = -abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif req_func == "rotate_counterclockwise":
		resume()
		dir_id = 0
		vel_right = abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])
	elif req_func == "rotate_clockwise_90":
		rotate_90(1, d)
	elif req_func == "rotate_counterclockwise_90":
		rotate_90(0, d)
	elif req_func == "just_rotate":
		var tmp_dir_id = d["dir_id"]
		if tmp_dir_id != 0 and tmp_dir_id != 1:
			print('Requested direction is out of bounds.')
			return
		d["degree"] = 1
		rotate_90(tmp_dir_id, d)
	elif req_func == "rotate_90":
		var tmp_dir_id = d["dir_id"]
		if tmp_dir_id != 0 and tmp_dir_id != 1:
			print('Requested direction is out of bounds.')
			return
		rotate_90(tmp_dir_id, d)
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
	elif req_func == "stop_timer":
		time_on = false
		send("Timer Stopped.")
	elif req_func == "start_timer":
		time = 0
		time_on = true
		send("Timer Started.")
	elif req_func == "wait":
		stop()
		wait_time = d["wait_time"]
		var message = "Waiting for %d seconds." % wait_time
		send(message)
	elif req_func == "play_sound":
		if music == null:
			var sound_path = d["sound_path"]
			music = AudioStreamPlayer.new()
			music.autoplay = false
			music.stream = load(sound_path)
			add_child(music)
			music.play()
	elif req_func == "rgb_set_color":
		change_rgb(d["color"])
	elif req_func == "get_acceleration":
		send_axis_vector(accelerometer, d["axis"])
	elif req_func == "get_gyroscope":
		send_axis_vector(gyroscope, d["axis"])
	elif req_func == "reset_dir":
		stop()
		move_dir = "forward"
		send(move_dir)
	elif req_func == "stop":	# stops
		stop()
		target_ros = -1
		final_rot_pos = 400
		vel_right = 0
		vel_left = 0
	elif req_func == "exit":
		stop()
		change_rgb('closed')
		vel_right = 0
		vel_left = 0
		exit()

func send(msg):
	client.get_peer(1).put_packet(JSON.print(msg).to_utf8())

# =======================================================================

func send_axis_vector(in_vector, axis: String):
	# Sends the data of the requested axis (of input vector) back to server.
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
	if music:	# this is for stop looping the music.
		curr_music_pos = music.get_playback_position()
		if curr_music_pos < prev_music_pos:
			music.stop()
			music = null
			prev_music_pos = -1
			curr_music_pos = 0
			print("Sound ended.")
		prev_music_pos = curr_music_pos

	if wait_time > 0:
		# does not do anything for wait_time seconds.
		print(wait_time)
		wait_time -= delta
	else:
		wait_time = -1

	move(vel_right, vel_left)
	# print(rotation.y)
	if target_ros > 0:
		actual_rotate_90(delta, target_ros)	# rotates with time.

	if target_distance > 0:
		count_distance()
	# print(get_ultrasonic(true))
	# UPDATE OF COMPONENTS (VERY IMPORTANT TO BE HERE) ======================================
	update_all_camera_sensors()
	# updates values of accelerometer and gyro:
	update_accel_gyro(delta)
	# ============================================================================
	# print(get_darkness_percent(middle_sensor))
	if time_on:
		update_timer(delta)

func move(right_vel, left_vel):
	# Puts input right and left velocities to right and left motors.
	var max_torque = 50	# change this if needed
	if dir_id >= 0:	# rotation:
		max_torque = max_torque * reduce_speed_rot_percent
	var mx_rpm = max_rpm
	var rpm = abs($"front-right-wheel".get_rpm())
	$"front-right-wheel".engine_force = -(right_vel/100) * max_torque * (1 - rpm / mx_rpm)
	rpm = abs($"front-left-wheel".get_rpm())
	$"front-left-wheel".engine_force = -(left_vel/100) * max_torque * (1 - rpm / mx_rpm)

var v0 = Vector3(0,0,0)
var r0 = Vector3(0,0,0)
func update_accel_gyro(delta):
	# source: https://godotengine.org/qa/69346/how-to-get-rigidbody2d-linear-acceleration
	# Calculates acceleration and gyroscope (USE it in physics process).
	accelerometer  = (linear_velocity  - v0) / delta
	gyroscope = (angular_velocity - r0) / delta
	v0 = linear_velocity
	r0 = angular_velocity
	#print(accelerometer.z)
	#print(gyroscope)

func stop():
	# Stops the vehicle (to un-stop, call resume() method).
	mode = MODE_STATIC
	vel_left = 0
	vel_right = 0
	engine_force = 0
	dir_id = -1
	mode = MODE_RIGID
	linear_damp = 5

func resume():
	# Call this immediately after stop() for movement.
	linear_damp = -1

func get_ultrasonic(calc_distance):
	# If cal_distance == false, just returns if ultrasonic has detected a static body.
	# If cal_distance == true, returns the distance of the nearest obstacle.
	# Parameters: calc_distance = boolean.
	var list_detect = $ultrasonic.get_overlapping_bodies()
	# iterate over the list of overlapping bodies
	var min_d = 10000
	for body in list_detect:
		# print(body.get_name().to_lower())
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
	image.resize(64, 64)	# resizes image to 64 by 64 for quicker analysis.
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
	# Returns the reading of input ground sensor.
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
	# Returns True, if input ground sensor is on black line.
	if sensor_id == middle_sensor_id:
		return is_dark(middle_sensor, dark_value)
	elif sensor_id == right_sensor_id:
		return is_dark(right_sensor, dark_value)
	elif sensor_id == left_sensor_id:
		return is_dark(left_sensor, dark_value)
	else:
		print('Requested sensor is out of bounds.')
		return false

func set_camera_sensor_pos(sensor: Camera, offset_y, offset_deg_x):
	# Used to update the input camera sensor (ground + light) position when the bot moves (recommended to be used in _physics_process).
	# Parameters: 
	#   sensor: the camera sensor to be moved (path).
	#	offset_y: the y position offset (position difference of parent mesh of camera sensor, to wanted y position of camera sensor).
	# 	offset_deg_x: the rotation offset in x axis (rotation difference of parent mesh of camera sensor, to wanted x position of camera sensor).

	#print(sensor.get_parent().get_parent().get_parent().get_name())
	var mesh_parent = sensor.get_parent().get_parent().get_parent()
	sensor.global_translation = mesh_parent.global_translation
	sensor.rotation = self.rotation
	sensor.rotation.x = offset_deg_x
	sensor.global_translation.y = mesh_parent.global_transform.origin.y + offset_y


func update_all_camera_sensors():
	# Updates all camera sensors (ground + light) position when the bot moves (MUST be to be used in _physics_process).
	# change offsets if needed -> see set_camera_sensor_pos documentation to understand what values to put.
	set_camera_sensor_pos(middle_sensor, -0.05, -90)
	set_camera_sensor_pos(right_sensor, -0.05, -90)
	set_camera_sensor_pos(left_sensor,  -0.05, -90)
	set_camera_sensor_pos(light_sensor, 0, 0)

func change_rgb(color):
	# Changes the color to input color string.
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
	$led/ledlight.light_color = material.albedo_color

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
	# Function executed when pressing the 'make a noise button'.
	make_noise = !make_noise
	if make_noise:
		$noise_btn.text = "Stop Noise"
	else:
		$noise_btn.text = "Make Noise"

func update_timer(delta):
	# Updates the timer (use it in physics process).
	time += delta
	var mils = fmod(time,1)*1000
	var secs = fmod(time,60)
	var mins = fmod(time, 60*60) / 60
	var hr = fmod(fmod(time,3600 * 60) / 3600,24)
	
	var time_passed = "%02d : %02d : %02d : %03d" % [hr,mins,secs,mils]
	$timer_label.text = time_passed# + " : " + var2str(time)

func exit():
	# The simulator exits the connection of the websocket.
	stop()
	change_rgb('closed')
	client.disconnect_from_host(1000, "User disconnected.")

func rotate_90(dr_id: int, d):
	# Sets the necessary variables and functions for x degree rotation with dir_id rotation.
	# Param: dr_id: the direction id (dir_id) of rotation: clockwise == 1, counterclockwise == 0.
	#		 d: the initial dictionary (json) sent from the server.
	if d["degree"] <= 0:
		return
	resume()
	dir_id = dr_id
	print(self.global_transform.origin)
	var init_rot = rotation_degrees.y
	time_curr_ros = 0
	time_target_ros = -1
	target_ros = d["degree"]
	final_rot_pos = calc_final_rot(init_rot, target_ros, dr_id)
	if dr_id == 1:
		vel_right = -abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif dr_id == 0:
		vel_right = abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])


func actual_rotate_90(delta, target_rot):
	# Stops if fossbot has rotated to target degrees (USE it in physics_process).
	# Param: delta: the delta time of physics process.
	#		 target_rot: the target degrees to be rotated.
	var rotation_angle = abs(sign(rotation.y) * delta * angular_velocity.y)
	sum_rot += rotation_angle
	print(rad2deg(sum_rot))
	if rad2deg(sum_rot) >= target_rot:
		stop()
		sum_rot = 0
		target_ros = -1
		#if horizontal_ground:
		# Sets final player rotation regardles:
		rotation_degrees.y = final_rot_pos
		# init_player_pos
		print("Final rot pos: " + str(self.rotation_degrees.y))
		print(self.global_transform.origin)


func rotate_degrees_transf(degr: float, dir_id: int, rythm=0.01):
	# DEPRECATED:
	# Rotates (slowly) the robot (USE IT IN PHYSICS_PROCESS)
	# Param: degr: the degrees to rotate it
	#		 dir_id: the direction to rotate it:
	#			counterclockwise: dir_id == 0	(left)
	#			clockwise: dir_id == 1	(right)
	# 		 rythm=0.01: the step for each rotation (decrease it for slower rotation)
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

func move_distance(d, direction="forward"):
	# Sets the necessaruy variables for moving a specific distance.
	# Param: d: the initial dictionary (json) sent from the server.
	#		 direction: string: the direction to be moved (default is 'forward').
	if d["tar_dist"] <= 0:
		return
	resume()
	move_dir = direction
	init_player_pos = self.global_transform.origin
	target_distance = d["tar_dist"]
	if direction == "forward":
		vel_right = abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif direction == "reverse":
		vel_right = -abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])

func just_move(d, direction="forward"):
	# Sets the necessaruy variables for moving forever towards input direction.
	# Param: d: the initial dictionary (json) sent from the server.
	#		 direction: string: the direction to be moved (default is 'forward').
	if move_dir != direction:
		stop()
	resume()	# ALWAYS add resume() when function is movement related!
	# Pattern here: velocity = (-) abs(in_velocity)
	move_dir = direction
	if direction == "forward":
		vel_right = abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif direction == "reverse":
		vel_right = -abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])

func lock_x_z_ang():
	# Locks x and z angular axis
	axis_lock_angular_x = true
	axis_lock_angular_z = true

func unlock_x_z_ang():
	# Unlocks x and z angular axis
	axis_lock_angular_x = false
	axis_lock_angular_z = false

func _on_horizontal_ground_changed():
	# Define a function that will be executed when horizontal ground changes
	if horizontal_ground:
		lock_x_z_ang()
		# print("Axis locked")
	else:
		unlock_x_z_ang()
		# print("Axis unlocked")

