extends VehicleBody

var vel_right = 0
var vel_left = 0
var init_player_transform
var init_player_rotation
var respawn_y_pos = -25	# the y position to witch the respawn function is activated.

var ultrasonic_tradeoff = 2.4	# change it according to the position of ultrasonic in comparison to the player
# Tip for defining ultrasonic_tradeoff: put an object in front and make it so when it is diectly near it for the ultrasonic to be 0.
onready var middle_sensor = $MiddleSensor/MiddleContainer/Viewport/MiddleSensor
onready var left_sensor = $LeftSensor/LeftContainer/Viewport/LeftSensor
onready var right_sensor = $RightSensor/RightContainer/Viewport/RightSensor
onready var light_sensor = $LightSensor/LightContainer/Viewport/LightSensor
# rotation related:
var radians = 0
var target_ros = -1
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
var target_distance = -1
var sum_distance = 0

# used to get revolutions and steps:
var sensor_disc = 20	# by default 20 lines sensor disc
var total_rev_left = 0
var total_rev_right = 0
var total_steps_left = 0
var total_steps_right = 0
var total_left_dist = 0
var total_right_dist = 0
var total_sum_rot = 0

# ground sensor id:
var middle_sensor_id = 1
var right_sensor_id = 2
var left_sensor_id = 3

# music (and its loop handling) related:
var wait_time = -1
var music = null
var prev_music_pos = -1
var curr_music_pos = 0

# direction of motors
var move_dir = "forward"

onready var fossbot_name = get_node(".").name
# Set this to false if not horizontal ground in scene (you can also do it from editor!)
export(float) var max_rpm = 200.0
var motor_left_name
var motor_right_name
var motor_left_node
var motor_right_node

var reduce_speed_rot_percent = 0.2	# 20 percent of initial torque for rotation (slows rotation).

var prev_func
var PARALLEL_METHODS = ["dist_travelled", "deg_rotated", "check_for_obstacle", "get_distance", "get_floor_sensor", "check_on_line", "get_light_sensor", "check_for_dark", "get_noise_detection", "get_elapsed", "stop_timer","start_timer", "play_sound", "rgb_set_color", "get_acceleration", "get_gyroscope", "get_revolutions", "get_steps", "reset_steps", "count_revolutions"]

var last_just_move_time_func = 0
var last_just_rot_time_func = 0

var wait_until_next_just_do = 0.5	# in seconds
var collision_occured = false
var sum_rot = 0
var move_func = false	# used to detect whether there is a "moving" func executed.
var move_dist_func_end = false	# used to detect if a move_distance function has ended.
var rot_deg_func_end = false	# same here but with rotation degree.
# VARS FOR WEBSOCKET CONNECTION ====================================
var user_id

var horizontal_ground = true

var window = JavaScript.get_interface("window")

func _ready():
	sim_info.init_fossbot(get_node(".").get_path())
	init_player_transform = global_transform.origin
	init_player_transform.y += 0.5
	init_player_rotation = global_rotation
	# emit_signal("fossbot", get_node(".").get_path())


func check_last_just_do_time(last_do_time):
	if abs(Time.get_ticks_msec() - last_do_time) >= wait_until_next_just_do * 1000:
		prev_func = "stop"
		stop()

func data_received(pkt):

	if pkt == null or str(pkt) == 'nan':
		if prev_func == "just_move":
			check_last_just_do_time(last_just_move_time_func)
		elif prev_func == "just_rotate":
			check_last_just_do_time(last_just_rot_time_func)
		return

	var d = pkt
	var req_func = d["func"]

	if not req_func in PARALLEL_METHODS:
		sum_distance = 0
		target_distance = -1
		init_player_pos = self.global_transform.origin
		sum_rot = 0
		radians = 0
		# total_sum_rot = 0
		move_dist_func_end = false
		rot_deg_func_end = false
		collision_occured = false

	if req_func == "just_move":
		last_just_move_time_func = Time.get_ticks_msec()
		var tmp_move_dir = d["direction"]
		if tmp_move_dir != "forward" and tmp_move_dir != "reverse":
			print("Motor accepts only forward and reverse values.")
			return
		if prev_func != "just_move":
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
	elif req_func == "rotate_clockwise_90":
		rotate_90(1, d)
	elif req_func == "rotate_counterclockwise_90":
		rotate_90(0, d)
	elif req_func == "just_rotate":
		last_just_rot_time_func = Time.get_ticks_msec()
		var tmp_dir_id = d["dir_id"]
		if tmp_dir_id != 0 and tmp_dir_id != 1:
			print('Requested direction is out of bounds.')
			return
		if prev_func != "just_rotate":
			just_rotate(d)
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
		send(sim_info.get_make_noise())
	elif req_func == "get_elapsed":
		send(sim_info.time)
	elif req_func == "wait":
		stop()
		wait_time = d["wait_time"]
		print("Waiting for %d seconds." % wait_time)
		# send(message)
	elif req_func == "play_sound":
		if music == null:
			var sound_path = d["sound_path"]
			var music_file = load(sound_path)
			if music_file == null:
				print("Requested Music File not found.")
				return
			music = AudioStreamPlayer.new()
			music.autoplay = false
			music.stream = music_file
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
		# final_rot_pos = 0
	elif req_func == "exit":
		exit()
	elif req_func == "dist_travelled":
		if move_dist_func_end:
			send(sum_distance)
		elif d["motor_name"] == motor_left_name:
			send(total_left_dist)
		elif d["motor_name"] == motor_right_name:
			send(total_right_dist)
	elif req_func == "get_revolutions":
		if d["motor_name"] == motor_left_name:
			send(total_rev_left)
		elif d["motor_name"] == motor_right_name:
			send(total_rev_right)
	elif req_func == "get_steps":
		if d["motor_name"] == motor_left_name:
			send(total_steps_left)
		elif d["motor_name"] == motor_right_name:
			send(total_steps_right)
	elif req_func == "reset_steps":
		total_steps_left = 0
		total_steps_right = 0
	elif req_func == "count_revolutions":
		if d["motor_name"] == motor_left_name:
			total_steps_left += 1
		elif d["motor_name"] == motor_right_name:
			total_steps_right += 1
	elif req_func == "deg_rotated":
		if rot_deg_func_end:
			send(rad2deg(sum_rot))
		else:
			send(rad2deg(total_sum_rot))
	elif req_func == "move_motor":
		var dir_motor = d["direction"]
		if dir_motor != "forward" and dir_motor != "reverse":
			print("Motor accepts only forward and reverse values.")
			return
		if d["motor_name"] == motor_left_name:
			vel_left = move_motor(dir_motor, float(d["motor_vel"]))
		elif d["motor_name"] == motor_right_name:
			vel_right = move_motor(dir_motor, float(d["motor_vel"]))
	if not req_func in PARALLEL_METHODS:
		prev_func = req_func

func move_motor(direction, vel):
	if direction == "forward":
		return abs(vel)
	elif direction == "reverse":
		return -abs(vel)

func send(msg):
	window.sendMessageFromGodot(msg, fossbot_name, user_id)

# =======================================================================

func send_axis_vector(in_vector, axis: String):
	# Sends the data of the requested axis (of input vector) back to server.
	# Godot has y vertical (z in "our" 3d space). Also y is x and x is z (converting from godot to "our" 3d space).
	if axis == "x":
		send(in_vector.z)
	elif axis == "z":
		send(in_vector.y)
	elif axis == "y":
		send(in_vector.x)
	else:
		print("Unknown Axis!")
		send("0")

var collided_car = false
func _integrate_forces(state):
	# handles sliding after collision (reduced):
	if state.get_contact_count() >= 1:
		collided_car = true
		collision_occured = true
		if linear_velocity != Vector3.ZERO or angular_velocity != Vector3.ZERO:
			if round(vel_left) == 0 and round(vel_right) == 0:
				linear_damp = 2
				angular_damp = 3
	elif collided_car:
		linear_damp = -1
		angular_damp = -1
		collided_car = false

func _process(delta):
	# updates steps:
	calc_steps_revolutions_degrees(delta)

	if wait_time > 0:
		# does not do anything for wait_time seconds.
		print(wait_time)
		wait_time -= delta
	else:
		wait_time = -1

	# updates values of accelerometer and gyro:
	update_accel_gyro(delta)

func _physics_process(delta):
	if global_transform.origin.y <= respawn_y_pos:
		respawn()

	if music:	# this is for stop looping the music.
		curr_music_pos = music.get_playback_position()
		if curr_music_pos < prev_music_pos:
			music.stop()
			music = null
			prev_music_pos = -1
			curr_music_pos = 0
			print("Sound ended.")
		prev_music_pos = curr_music_pos

	move(vel_right, vel_left)
	# print(rotation.y)
	if target_ros > 0:
		actual_rotate_90(delta, target_ros)	# rotates with time.

	if target_distance > 0:
		count_distance()
	# print(fossbot_name + ": " + str(get_ultrasonic(true)))
	# UPDATE OF COMPONENTS (VERY IMPORTANT TO BE HERE) ======================================
	update_all_camera_sensors()
	# ============================================================================
	# print(get_darkness_percent(middle_sensor))

var init_torque = 40
var torque = init_torque
func move(right_vel, left_vel):
	# Puts input right and left velocities to right and left motors.
	var max_torque = 100	# change this if needed
	if dir_id >= 0:	# rotation:
		torque = 50 * reduce_speed_rot_percent
	elif round(right_vel) !=0 and round(left_vel) !=0:
		torque = lerp(torque, max_torque, 0.01)
	var mx_rpm = max_rpm
	var rpm = abs(motor_right_node.get_rpm())
	motor_right_node.engine_force = -(right_vel/100) * torque * (1 - rpm / mx_rpm)
	rpm = abs(motor_left_node.get_rpm())
	motor_left_node.engine_force = -(left_vel/100) * torque * (1 - rpm / mx_rpm)

func set_foss_material_color(color):
	var foss_material = SpatialMaterial.new()
	if color == 'red':
		foss_material.albedo_color = Color(1, 0, 0)
	elif color == 'green':
		foss_material.albedo_color = Color(0, 1, 0)
	elif color == 'yellow':
		foss_material.albedo_color = Color(1, 1, 0)
	elif color == 'cyan':
		foss_material.albedo_color = Color(0, 1, 1)
	elif color == 'violet':
		foss_material.albedo_color = Color(1, 0, 1)
	elif color == 'white':
		foss_material.albedo_color = Color(1, 1, 1)
	elif color == 'black':
		foss_material.albedo_color = Color(0, 0, 0)
	else:
		return
	$car_body.mesh = $car_body.mesh.duplicate(true)
	$car_body.mesh.surface_set_material(1, foss_material.duplicate(true))


func calc_steps_revolutions_degrees(delta):
	var rotation_angle = abs(sign(rotation.y) * delta * angular_velocity.y)
	total_sum_rot += rotation_angle
	# print(total_sum_rot)
	# Calculating left wheel rev, steps and distance:
	var left_step = abs((motor_left_node.get_rpm() / 60) * delta * sensor_disc)
	total_steps_left += left_step

	total_rev_left = total_steps_left / sensor_disc

	total_left_dist = 2 * PI * motor_left_node.get_radius() * total_rev_left

	# Calculating right wheel rev, steps and distance:
	var right_step = abs((motor_right_node.get_rpm() / 60) * delta * sensor_disc)
	total_steps_right += right_step

	total_rev_right = total_steps_right / sensor_disc

	total_right_dist = 2 * PI * motor_right_node.get_radius() * total_rev_right


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
	total_rev_left = 0
	total_rev_right = 0
	total_steps_left = 0
	total_steps_right = 0
	total_left_dist = 0
	total_right_dist = 0
	total_sum_rot = 0
	torque = init_torque
	# sum_rot = 0
	target_ros = -1
	# sum_distance = 0
	target_distance = -1
	engine_force = 0
	dir_id = -1
	move_func = false
	mode = MODE_RIGID
	linear_damp = 5

func resume():
	# Call this immediately after stop() for movement.
	linear_damp = -1

func get_ultrasonic(calc_distance):
	# If cal_distance == false, just returns if ultrasonic has detected a static body.
	# If cal_distance == true, returns the distance of the nearest obstacle.
	# Parameters: calc_distance = boolean.
	var space_state = get_world().direct_space_state
	var list_detect = $ultrasonic.get_overlapping_bodies() + $ultrasonic.get_overlapping_areas()
	# iterate over the list of overlapping bodies
	var min_d = 10000
	var player_position = self.global_transform.origin
	var dist_center = _find_smallest_ultra_raycast($ultrasonic/center_ray, min_d, player_position, ultrasonic_tradeoff*0.5)
	var dist_right = _find_smallest_ultra_raycast($ultrasonic/right_ray, min_d, player_position, ultrasonic_tradeoff*0.7)
	var dist_left = _find_smallest_ultra_raycast($ultrasonic/left_ray, min_d, player_position, ultrasonic_tradeoff*0.7)
	var dist_top = _find_smallest_ultra_raycast($ultrasonic/top_ray, min_d, player_position, ultrasonic_tradeoff*0.4)
	var min_ray_dist = min(min(min(dist_center, dist_right), dist_left), dist_top)
	min_d = min(min_d, min_ray_dist)
	for body in list_detect:
		# print(body.get_name().to_lower())
		if !calc_distance:
			return true #if no calc_distance, just returns if the object is colliding with static.
		var body_position = body.global_transform.origin
		body_position.y = player_position.y + 3.08
		var res = space_state.intersect_ray(player_position, body_position, [], $ultrasonic.get_collision_mask(), true, true)
		var distance = min_d + 1
		if res:
			# distance = player_position.distance_to(res.position) - ultrasonic_tradeoff
			distance = player_position.distance_to(res.position) - ultrasonic_tradeoff
		var f_dist = min(min_ray_dist, distance)
		min_d = min(f_dist, min_d)
		# print("Distance to ", body.get_name(), " is ", min_d)
	if min_d == 10000 and !calc_distance:
		return false 	# no obstacle has been detected.
	return max(min_d, 0)

func _find_smallest_ultra_raycast(raycast, min_d, player_position, ultra_tradeoff):
	var res = raycast.get_collision_point()
	var dist = min_d + 2
	if res:
		res.y = player_position.y
		dist = player_position.distance_to(res) - ultra_tradeoff
	return dist


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
	var lig_color
	if color == 'red':
		lig_color = Color(1, 0, 0)
	elif color == 'green':
		lig_color = Color(0, 1, 0)
	elif color == 'blue':
		lig_color = Color(0, 0, 1)
	elif color == 'white':
		lig_color = Color(1, 1, 1)
	elif color == 'yellow':
		lig_color = Color(1, 1, 0)
	elif color == 'cyan':
		lig_color = Color(0, 1, 1)
	elif color == 'violet':
		lig_color = Color(1, 0, 1)
	elif color == 'closed':
		lig_color = Color(0, 0, 0)
	else:
		print('Uknown color!')
	$led.light_color = lig_color
	$led/ledlight.light_color = lig_color

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
		move_dist_func_end = true
		stop()

func exit():
	# The simulator exits the connection of the websocket.
	stop()
	change_rgb('closed')
	# client.disconnect_from_host(1000, "User disconnected.")

func rotate_90(dr_id: int, d):
	# Sets the necessary variables and functions for x degree rotation with dir_id rotation.
	# Param: dr_id: the direction id (dir_id) of rotation: clockwise == 1, counterclockwise == 0.
	#		 d: the initial dictionary (json) sent from the server.
	if move_func:
		stop()
	resume()	# ALWAYS add resume() when function is movement related!
	move_func = true
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

func save_current_pos():
	init_player_transform = global_transform.origin
	init_player_rotation = global_rotation

func respawn():
	# stop()
	global_transform.origin = init_player_transform
	global_rotation = init_player_rotation


func actual_rotate_90(delta, target_rot):
	# Stops if fossbot has rotated to target degrees (USE it in physics_process).
	# Param: delta: the delta time of physics process.
	#		 target_rot: the target degrees to be rotated.
	var rotation_angle = abs(sign(rotation.y) * delta * angular_velocity.y)
	sum_rot += rotation_angle
	print(rad2deg(sum_rot))
	if rad2deg(sum_rot) >= target_rot:
		rot_deg_func_end = true
		stop()
		#if horizontal_ground:
		# Sets final player rotation regardles:
		if horizontal_ground and not collision_occured:
			rotation_degrees.y = final_rot_pos
		# init_player_pos
		print("Final rot pos: " + str(self.rotation_degrees.y))
		print(self.global_transform.origin)

func move_distance(d, direction="forward"):
	# Sets the necessaruy variables for moving a specific distance.
	# Param: d: the initial dictionary (json) sent from the server.
	#		 direction: string: the direction to be moved (default is 'forward').
	if d["tar_dist"] <= 0:
		return
	if move_func:
		stop()
	move_func = true
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
	if move_func:
		stop()
	resume()	# ALWAYS add resume() when function is movement related!
	move_func = true
	# Pattern here: velocity = (-) abs(in_velocity)
	move_dir = direction
	if direction == "forward":
		vel_right = abs(d["vel_right"])
		vel_left = abs(d["vel_left"])
	elif direction == "reverse":
		vel_right = -abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])

func just_rotate(d):
	if move_func:
		stop()
	move_func = true
	resume()
	dir_id = d["dir_id"]
	if dir_id == 0:
		vel_right = abs(d["vel_right"])
		vel_left = -abs(d["vel_left"])
	elif dir_id == 1:
		vel_right = -abs(d["vel_right"])
		vel_left = abs(d["vel_left"])

func set_right_motor(motor_name, motor_path):
	motor_right_name = motor_name
	motor_right_node = get_node(motor_path)

func set_left_motor(motor_name, motor_path):
	motor_left_name = motor_name
	motor_left_node = get_node(motor_path)

func set_user_id(new_user):
	user_id = new_user
