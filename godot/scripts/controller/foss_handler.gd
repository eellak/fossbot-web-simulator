extends Spatial

var foss_dict = {}
var user_dict = {}
signal timer(time_passed)

var prev_sel_id = -1
var window = JavaScript.get_interface("window")
var pkt_received = false
var time_on = false
var time = 0
var data_callback = JavaScript.create_callback(self, "data_received")

func data_received(pkt):
	pkt = pkt[0]
	var tmp_d = str(pkt)
	var d = JSON.parse(tmp_d)
	d = d.get_result()

	if d["func"] == "exit":
		for foss_name in user_dict.keys():
			if user_dict[foss_name] == d["user_id"]:
				user_dict.erase(foss_name)
				get_node(foss_dict[foss_name]).data_received(d)
				get_node(foss_dict[foss_name]).set_user_id(null)
				break
		return

	if not "fossbot_name" in d:
		return

	if not d["fossbot_name"] in foss_dict:	# if fossbot name not in scene -> returns
		sendGodotError("Requested " +d["fossbot_name"] + " does not exist in scene.", d["fossbot_name"], d["user_id"])
		return

	if not d["fossbot_name"] in user_dict:
		user_dict[d["fossbot_name"]] = d["user_id"]
		get_node(foss_dict[d["fossbot_name"]]).set_user_id(d["user_id"])
	else:
		if d["user_id"] != user_dict[d["fossbot_name"]]:	# not the same user (returns).
			sendGodotError(d["fossbot_name"] + " is already controlled by another user!", d["fossbot_name"], d["user_id"])
			return

	if "vel_right" in d:
		d["vel_right"] = float(d["vel_right"])
	if "vel_left" in d:
		d["vel_left"] = float(d["vel_left"])
	if "degree" in d:
		d["degree"] = float(d["degree"])
	if "sensor_id" in d:
		d["sensor_id"] = int(d["sensor_id"])
	if "tar_dist" in d:
		d["tar_dist"] = float(d["tar_dist"])
	if "dark_value" in d:
		d["dark_value"] = float(d["dark_value"])
	if "light_val" in d:
		d["light_val"] = float(d["light_val"])
	if "wait_time" in d:
		d["wait_time"] = float(d["wait_time"])
	if "dir_id" in d:
		d["dir_id"] = int(d["dir_id"])
	if "def_dist" in d:
		d["def_dist"] = float(d["def_dist"])

	var req_func = d["func"]

	if req_func == "restart_all":
		window.disconnectGodotSocket()
		sim_info.reset_info()
		get_tree().reload_current_scene()
	elif req_func == "stop_timer":
		time_on = false
	elif req_func == "start_timer":
		time = 0
		time_on = true
	else:
		for foss_name in foss_dict.keys():	# checks for the same names in foss_dict:
			if d["fossbot_name"] == foss_name:
				get_node(foss_dict[d["fossbot_name"]]).data_received(d)
			else:
				get_node(foss_dict[d["fossbot_name"]]).data_received(null)


func update_timer(delta):
	# Updates the timer (use it in physics process).
	time += delta
	sim_info.time = time
	var mils = fmod(time,1)*1000
	var secs = fmod(time,60)
	var mins = fmod(time, 60*60) / 60
	var hr = fmod(fmod(time,3600 * 60) / 3600,24)
	var time_passed = "%02d : %02d : %02d : %03d" % [hr,mins,secs,mils]
	emit_signal("timer", time_passed)

func _ready():
	window.initGodotSocket()
	window.initCallBack(data_callback)


func send_null_all_fossbots():
	for foss_name in foss_dict.keys():
		get_node(foss_dict[foss_name]).data_received(null)

func sendGodotError(msg, fossbot_name, user_id):
	window.sendErrorFromGodot(msg, fossbot_name, user_id)

func _process(delta):
	var sel_id = $foss_dropdown.get_selected_id()
	if prev_sel_id != sel_id:
		var f_name = $foss_dropdown.get_item_text(sel_id)
		$camera_handler.set_target(foss_dict[f_name])
		prev_sel_id = sel_id
	if not pkt_received:
		send_null_all_fossbots()

	if time_on:
		update_timer(delta)


func _on_fossbot_fossbot(fossbot_path):
	var n = get_node(fossbot_path)
	foss_dict[str(n.name)] = fossbot_path
	$foss_dropdown.add_item(str(n.name))
