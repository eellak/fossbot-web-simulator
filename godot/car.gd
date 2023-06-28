extends VehicleBody

var vel_right = 0
var vel_left = 0
var floor_name = "Floor"
var ultrasonic_tradeoff = 2.7	# change it according to the position of ultrasonic in comparison to the player
# Tip for defining ultrasonic_tradeoff: put an object in front and make it so when it is diectly near it for the ultrasonic to be 0.
var middle_sensor = "MiddleContainer/Viewport/MiddleSensor"		# path to ground sensors (change it if needed).
var left_sensor = "LeftContainer/Viewport/LeftSensor"
var right_sensor = "RightContainer/Viewport/RightSensor"
# rotation related:
var radians = 0
var target_ros = 0
var dir_id = -1

# acceleration - gyroscope related:
var accelerometer = Vector3(0, 0, 0)
var gyroscope = Vector3(0, 0, 0)
# METHODS FOR WEBSOCKET CONNECTION ====================================
var client = WebSocketClient.new()
var url = "ws://localhost:5000"

func _ready():
	middle_sensor = get_node(middle_sensor)
	left_sensor = get_node(left_sensor)
	right_sensor = get_node(right_sensor)
	client.connect("data_received", self, "data_received")
	var err = client.connect_to_url(url)
	if err != OK:
		set_process(false)
		print("Unable to connect to server.")


func data_received():
	# BLOCK HERE FOR ROTATION TARGET DEGREES (before radians = 0).
	radians = 0
	var pkt = client.get_peer(1).get_packet()
	var parsedJson: JSONParseResult = JSON.parse(pkt.get_string_from_ascii())
	var d = parsedJson.get_result()
	# print("Got data from server: " + pkt.get_string_from_utf8())
	# changes player's velocity accordind to input:
	var req_func = d["func"]
	if req_func == "move_forward":
		resume()
		vel_right = d["vel_right"]
		vel_left = d["vel_left"]
		vel_right = abs(vel_right)
		vel_left = abs(vel_left)
	elif req_func == "move_backward":
		resume()
		vel_right = d["vel_right"]
		vel_left = d["vel_left"]
		vel_right = -abs(vel_right)
		vel_left = -abs(vel_left)
	elif req_func == "rotate_clockwise":
		resume()
		vel_right = d["vel_right"]
		vel_left = d["vel_left"]
		vel_right = -abs(vel_right)
		vel_left = abs(vel_left)
	elif req_func == "rotate_counterclockwise":
		resume()
		vel_right = d["vel_right"]
		vel_left = d["vel_left"]
		vel_right = abs(vel_right)
		vel_left = -abs(vel_left)
	elif req_func == "rotate_clockwise_deg":
		resume()
		vel_right = d["vel_right"]
		vel_left = d["vel_left"]
		dir_id = 1
		target_ros = d["degree"]
		vel_right = -abs(vel_right)
		vel_left = abs(vel_left)
	elif req_func == "rotate_counterclockwise_deg":
		resume()
		vel_right = d["vel_right"]
		vel_left = d["vel_left"]
		dir_id = 0
		target_ros = d["degree"]
		vel_right = abs(vel_right)
		vel_left = -abs(vel_left)
	elif req_func == "get_position":
		print("Position requested.")
		var pos_x = self.global_transform.origin.x
		var pos_z = self.global_transform.origin.z
		var msg = "Player position = x: " + str(pos_x) + ", z: " + str(pos_z)
		send(msg)	# sends data back to server
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

	# run ultrasonic:
	# print(get_ultrasonic(true))

	if target_ros > 0:
		rotate_degrees(target_ros, dir_id)

	# UPDATE OF COMPONENTS (VERY IMPORTANT TO BE HERE) ======================================
	update_all_ground_sensors()
	# updates values of accelerometer and gyro:
	update_accel_gyro(delta)
	# ============================================================================
	# print(get_darkness_percent(middle_sensor))


func move(right_vel, left_vel):
	# var steer = 0
	var max_torque = 100	# change this if needed
	var max_rpm = 100
	var rpm = abs($"front-right-wheel".get_rpm())
	$"front-right-wheel".engine_force = (right_vel/100) * max_torque * (1 - rpm / max_rpm)
	rpm = abs($"front-left-wheel".get_rpm())
	$"front-left-wheel".engine_force = (left_vel/100) * max_torque * (1 - rpm / max_rpm)

var v0
var r0
func update_accel_gyro(delta):
	# source: https://godotengine.org/qa/69346/how-to-get-rigidbody2d-linear-acceleration
	# Calculates acceleration and gyroscope (USE it in physics process).
	if v0 and r0:
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
		if body.get_name() != floor_name:
			if !calc_distance:
				return true #if no calc_distance, just returns if the object is colliding with static.
			var player_position = self.global_transform.origin
			var body_position = body.global_transform.origin
			var distance = player_position.distance_to(body_position) - ultrasonic_tradeoff
			# print("Distance to ", body.get_name(), " is ", distance)
			if distance < min_d:
				min_d = distance
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
			var grayscale = c.v
			total_grayscale += grayscale

	return total_grayscale / (64 * 64)

func is_dark(camera: Camera):
	# returns true if input ground sensor is above dark color.
	var dark_threshold = 0.5
	if get_darkness_percent(camera) < dark_threshold:
		return true
	else:
		return false

func set_ground_sensor_pos(sensor: Camera, offset_x, offset_z, offset_deg_x):
	# Used to update the input ground sensor position when the bot moves (recommended to be used in _physics_process).
	# Parameters: 
	#   sensor: the ground sensor to be moved (path).
	#	offset_x: the x position offset (position difference of main vehicle body, to wanted x position of ground sensor).
	#	offset_x: the z position offset (position difference of main vehicle body, to wanted z position of ground sensor).
	# 	offset_deg_x: the rotation offset in x axis (rotation difference of main vehicle body, to wanted x position of ground sensor).
	sensor.global_translation.z = self.global_transform.origin.z + offset_z
	sensor.global_translation.x = self.global_transform.origin.x + offset_x
	sensor.rotation = self.rotation
	sensor.rotation.x = offset_deg_x

func update_all_ground_sensors():
	# Updates all ground sensors position when the bot moves (MUST be to be used in _physics_process).
	# change offsets if needed -> see set_ground_sensor_pos documentation to understand what values to put.
	set_ground_sensor_pos(middle_sensor, 0, -1.45, -90)
	set_ground_sensor_pos(right_sensor, 0.4, -1.45, -90)
	set_ground_sensor_pos(left_sensor, -0.4, -1.45, -90)

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
			stop()
			print(rotation_degrees.y)
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
			stop()
			print(rotation_degrees.y)
			#print(rotation_degrees.y)
			target_ros = 0
			dir_id = -1
