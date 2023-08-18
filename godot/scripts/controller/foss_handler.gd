extends Spatial

var foss_dict = {}
var user_dict = {}

var prev_sel_id = -1
var window = JavaScript.get_interface("window")
var pkt_received = false
var time_on = false
var time = 0
var data_callback = JavaScript.create_callback(self, "data_received")

var fossbot_scene = preload("res://scenes/models/fossbot.tscn")
var cube_model = preload("res://scenes/models/obstacles/cube.tscn")
var sphere_model = preload("res://scenes/models/obstacles/sphere.tscn")

func _ready():
	window.initGodotSocket()
	window.initCallBack(data_callback)

func spawn_obstacle(d, obs):
	var obs_inst = obs.instance()
	get_parent().add_child(obs_inst, true)
	obs_inst.global_transform.origin.x = float(d["pos_y"])
	obs_inst.global_transform.origin.z = float(d["pos_x"])
	if "pos_z" in d:
		obs_inst.global_transform.origin.y = float(d["pos_z"])
	else:
		obs_inst.global_transform.origin.y = float(d.get("scale_z", 1))
	obs_inst.get_child(0).global_scale(Vector3(float(d.get("scale_y", 1)), float(d.get("scale_z", 1)), float(d.get("scale_x", 1))))
	set_obs_color(d, obs_inst)

func spawn_sphere(d):
	if d.get("radius", 1) <= 0:
		return
	var obs_inst = sphere_model.instance()
	get_parent().add_child(obs_inst, true)
	obs_inst.global_transform.origin.x = float(d["pos_y"])
	obs_inst.global_transform.origin.z = float(d["pos_x"])
	if "pos_z" in d:
		obs_inst.global_transform.origin.y = float(d["pos_z"])
	else:
		obs_inst.global_transform.origin.y = 1.8 * float(d.get("radius", 1))
	obs_inst.get_child(0).global_scale(Vector3(float(d.get("radius", 1)), float(d.get("radius", 1)), float(d.get("radius", 1))))
	set_obs_color(d, obs_inst)

func set_obs_color(d, obs_inst):
	if not "color" in d or not d["color"] in ["yellow", "cyan", "green", "violet", "red", "white", "black", "blue"]:
		return
	var color = d["color"]
	var obs_material = SpatialMaterial.new()
	if color == 'red':
		obs_material.albedo_color = Color(1, 0, 0)
	elif color == 'green':
		obs_material.albedo_color = Color(0, 1, 0)
	elif color == 'yellow':
		obs_material.albedo_color = Color(1, 1, 0)
	elif color == 'cyan':
		obs_material.albedo_color = Color(0, 1, 1)
	elif color == 'violet':
		obs_material.albedo_color = Color(1, 0, 1)
	elif color == 'white':
		obs_material.albedo_color = Color(1, 1, 1)
	elif color == 'black':
		obs_material.albedo_color = Color(0, 0, 0)
	elif color == 'blue':
		obs_material.albedo_color = Color(0, 0, 1)
	else:
		return
	obs_inst.get_child(0).get_child(0).material_override = obs_material


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
	elif d["func"] == "foss_spawn":
		if not "pos_x" in d or not "pos_y" in d:
			return
		var fossbot_inst = fossbot_scene.instance()
		get_parent().add_child(fossbot_inst, true)
		if "color" in d and d["color"] in ["yellow", "cyan", "green", "violet", "red", "white", "black"]:
			fossbot_inst.set_foss_material_color(d["color"])
		fossbot_inst.global_transform.origin.x = float(d["pos_y"])
		fossbot_inst.global_transform.origin.z = float(d["pos_x"])
		fossbot_inst.global_transform.origin.y = float(d.get("pos_z", 1))
		return
	elif d["func"] == "obs_spawn":
		if not "pos_x" in d or not "pos_y" in d or not "type" in d:
			return
		if d["type"] == "cube":
			spawn_obstacle(d, cube_model)
		elif d["type"] == "sphere":
			spawn_sphere(d)
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


func send_null_all_fossbots():
	for foss_name in foss_dict.keys():
		get_node(foss_dict[foss_name]).data_received(null)

func sendGodotError(msg, fossbot_name, user_id):
	window.sendErrorFromGodot(msg, fossbot_name, user_id)

func _process(delta):
	update_dropdown()
	var sel_id = $foss_dropdown.get_selected_id()
	if prev_sel_id != sel_id:
		var f_name = $foss_dropdown.get_item_text(sel_id)
		$camera_handler.set_target(foss_dict[f_name])
		prev_sel_id = sel_id
	if not pkt_received:
		send_null_all_fossbots()

	if time_on:
		update_timer(delta)


func update_dropdown():
	var keys1 = foss_dict.keys()
	var keys2 = sim_info.foss_dict.keys()
	var diff = []
	for key in keys2:
		if !keys1.has(key):
			diff.append(key)
	for key in diff:
		foss_dict[str(key)] = sim_info.foss_dict[key]
		$foss_dropdown.add_item(str(key))

