extends VehicleBody

var vel_right = 0
var vel_left = 0
var prev_mass = mass
# METHODS FOR WEBSOCKET CONNECTION ====================================
var client = WebSocketClient.new()
var url = "ws://localhost:5000"
func _ready():
	client.connect("data_received", self, "data_received")
	var err = client.connect_to_url(url)
	if err != OK:
		set_process(false)
		print("Unable to connect to server.")


func data_received():
	resume()
	var pkt = client.get_peer(1).get_packet()
	var parsedJson: JSONParseResult = JSON.parse(pkt.get_string_from_ascii())
	var d = parsedJson.get_result()
	# print("Got data from server: " + pkt.get_string_from_utf8())
	# changes player's velocity accordind to input:
	vel_right = d["vel_right"]
	vel_left = d["vel_left"]
	var req_func = d["func"]
	if req_func == "move_forward":
		vel_right = abs(vel_right)
		vel_left = abs(vel_left)
	elif req_func == "move_backward":
		vel_right = -abs(vel_right)
		vel_left = -abs(vel_left)
	elif req_func == "rotate_clockwise":
		vel_right = -abs(vel_right)
		vel_left = abs(vel_left)
	elif req_func == "rotate_counterclockwise":
		vel_right = abs(vel_right)
		vel_left = -abs(vel_left)
	elif req_func == "get_position":
		print("Position requested.")
		var pos_x = self.global_transform.origin.x
		var pos_z = self.global_transform.origin.z
		var msg = "Player position = x: " + str(pos_x) + ", z: " + str(pos_z)
		send(msg)	# sends data back to server
	elif req_func == "stop":	# stops
		stop()
		vel_right = 0
		vel_left = 0

func send(msg):
	client.get_peer(1).put_packet(JSON.print(msg).to_utf8())

# =======================================================================


func _physics_process(delta):
	client.poll()	# used for websockets
	move(vel_right, vel_left)
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

func move(right_vel, left_vel):
	# var steer = 0
	var max_torque = 100	# change this if needed
	var max_rpm = 100
	var rpm = abs($"front-right-wheel".get_rpm())
	$"front-right-wheel".engine_force = (right_vel/100) * max_torque * (1 - rpm / max_rpm)
	rpm = abs($"front-left-wheel".get_rpm())
	$"front-left-wheel".engine_force = (left_vel/100) * max_torque * (1 - rpm / max_rpm)

func stop():
	prev_mass = mass
	print("stop")
	mass = 10000

func resume():
	mass = prev_mass
	pass
