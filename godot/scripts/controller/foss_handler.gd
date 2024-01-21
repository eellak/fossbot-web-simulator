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
var cone_model = preload("res://scenes/models/obstacles/cone.tscn")

func _ready():
	# Initializes foss_handler by saving this instance to a dict in sim_info.
	# Also, here the connection to socketio happens (and the callback for sending data from socketio back to godot is initialized).
	sim_info.init_foss_handler(get_node("."))
	# When debugging comment out the following two lines
	window.initGodotSocket()
	window.initCallBack(data_callback)

func spawn_obstacle(d, obs):
	# Spawns an obstacle that can be scaled in all axis (not like sphere which only has radius).
	# Param: d: Its location and other characteristics of the obstacle.
	#		 obs: the obstacle instance.
	var obs_inst = obs.instance()
	get_parent().add_child(obs_inst, true)
	obs_inst.get_child(0).global_scale(Vector3(float(d.get("scale_y", 1)), float(d.get("scale_z", 1)), float(d.get("scale_x", 1))))
	obs_inst.global_transform.origin.x = float(d["pos_y"])
	obs_inst.global_transform.origin.z = float(d["pos_x"])
	obs_inst.global_transform.origin.y = float(d.get("scale_z", 1)) + float(d["pos_z"])
	set_obs_color(d, obs_inst)
	if not "counterclockwise" in d:
		return
	if d["counterclockwise"]:
		obs_inst.rotation_degrees.y = _calc_rot_pos(d.get("rotation", 0))
	else:
		obs_inst.rotation_degrees.y = - _calc_rot_pos(d.get("rotation", 0))


func spawn_sphere(d):
	# Spawns a sphere. Its location and other characteristics are specified in d.
	if d.get("radius", 1) <= 0:
		return
	var obs_inst = sphere_model.instance()
	get_parent().add_child(obs_inst, true)
	obs_inst.get_child(0).global_scale(Vector3(float(d.get("radius", 1)), float(d.get("radius", 1)), float(d.get("radius", 1))))
	obs_inst.global_transform.origin.x = float(d["pos_y"])
	obs_inst.global_transform.origin.z = float(d["pos_x"])
	obs_inst.global_transform.origin.y = 1.8 * float(d.get("radius", 1)) + float(d["pos_z"])
	set_obs_color(d, obs_inst)

func set_obs_color(d, obs_inst):
	# Sets a color for an obstacle.
	# Param: d: the dictionary with the requested color.
	#		 obs_inst: the instance of the object to be changed.
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

func change_foss_opt(fossbot_inst, d):
	# Changes characteristics of fossbot.
	# Param: fossbot_inst: the fossbot instance to be  changed.
	#		 d: the dictionary with the options.
	if "color" in d and d["color"] in ["yellow", "cyan", "green", "violet", "red", "white", "black", "blue"]:
		fossbot_inst.set_foss_material_color(d["color"])
	fossbot_inst.global_transform.origin.x = float(d["pos_y"])
	fossbot_inst.global_transform.origin.z = float(d["pos_x"])
	fossbot_inst.global_transform.origin.y = 1 + float(d["pos_z"])
	if d["counterclockwise"]:
		fossbot_inst.rotation_degrees.y = _calc_rot_pos(d.get("rotation", 0))
	else:
		fossbot_inst.rotation_degrees.y = - _calc_rot_pos(d.get("rotation", 0))
	fossbot_inst.horizontal_ground = sim_info.horizontal_ground
	fossbot_inst.save_current_pos()
	# fossbot_inst.stop()

func data_received(pkt):
	# This method is used to handle the package sent from socketio.
	# It also executes the correct method (specified in the pkt) and sends the data to the correct fossbot,
	# so it can execute it.
	# Param: pkt: the package sent from socketio.
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
	# Environment functions ========================================
	elif d["func"] == "exit_env":
		if d["user_id"] in sim_info.user_image or d["user_id"] in sim_info.user_index_img_part:
			sim_info.reset_user_image(d["user_id"])	# removes
			$image_label.text = ""
		return
	elif d["func"] == "foss_spawn":
		if not "pos_x" in d or not "pos_y" in d:
			return
		var fossbot_inst = fossbot_scene.instance()
		get_parent().add_child(fossbot_inst, true)
		change_foss_opt(fossbot_inst, d)
		return
	elif d["func"] == "obs_spawn":
		if not "pos_x" in d or not "pos_y" in d or not "type" in d:
			return
		if d["type"] == "cube":
			spawn_obstacle(d, cube_model)
		elif d["type"] == "sphere":
			spawn_sphere(d)
		elif d["type"] == "cone":
			spawn_obstacle(d, cone_model)
		return
	elif d["func"] == "change_floor_skin":
		var image = load_user_image(d, "Loading Image...")
		if not image:
			return
		var floor_indx = "0"
		if "floor_index" in d:
			floor_indx = d["floor_index"]
		var floor_node = sim_info.floor_dict[floor_indx]
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		floor_node.set_material_skin(texture, d)
		sendMessageGodotEnv("Image loaded.", d["user_id"])
		return
	elif d["func"] == "change_floor_terrain":
		var image = load_user_image(d, "Loading Terrain...")
		if not image:
			return
		image_terrain(image, d)
		return
	elif d["func"] == "change_fossbot":
		if not "fossbot_name" in d:
			return
		if not d["fossbot_name"] in foss_dict:
			return
		var foss_inst = get_node(foss_dict[d["fossbot_name"]])
		change_foss_opt(foss_inst, d)
		return
	elif d["func"] == "change_floor":
		if not "scale_y" in d and not "scale_x" in d:
			return
		var floor_indx = "0"
		if "floor_index" in d:
			floor_indx = d["floor_index"]
		var floor_node = sim_info.floor_dict[floor_indx]
		var scale_x = 1
		var scale_y = 1
		if "scale_y" in d:
			scale_y = float(d["scale_y"])
		if "scale_x" in d:
			scale_x = float(d["scale_x"])
		floor_node.global_scale(Vector3(scale_y, 1, scale_x))
		return
	elif d["func"] == "change_brightness":
		$WorldEnvironment/BrightnessSlider.value = int(d["value"])
		return
	elif d["func"] == "connect_env":
		print("Environment client connected successfully!")
		return
	elif d["func"] == "remove_all_objects":
		sim_info.remove_all_extra_nodes()
		return
	elif d["func"] == "reset_terrain":
		var floor_indx = "0"
		if "floor_index" in d:
			floor_indx = d["floor_index"]
		var floor_node = sim_info.floor_dict[floor_indx]
		floor_node.reset_mesh()
		sendMessageGodotEnv("Terrain Reset.", d["user_id"])
		return
	# ============================================

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

	# here, all the connection tests have been successful - if now user function is "connect" -> returns.
	if d["func"] == "connect":
		print("Client connected successfully!")
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

func _calc_rot_pos(initial_rot):
	# Calculates the final rotation position (in godot it is in the range [-180, 180].
	# Param: initial_rot: the rotation in range [0, 360, 361 ... infinity) -> (more convenient for user).
	return fmod((initial_rot + 180), 360) - 180

func image_terrain(image, d):
	# Loads an image on the terrain. It also removes all objects of scene (so the terrain loads with no bugs).
	# Param: image: the image to be loaded.
	#		 d: other characteristics (for example floor_index). You can see the list of options in the docs of python client.
	var floor_indx = "0"
	if "floor_index" in d:
		floor_indx = d["floor_index"]
	var floor_node = sim_info.floor_dict[floor_indx]
	floor_node.load_terrain(image, float(d.get("intensity", 3)))
	sendMessageGodotEnv("Terrain loaded.", d["user_id"])


func load_user_image(d, img_label_text):
	# Loads a user image specified in d. 
	# Param: img_lable_text: the text that will be put to a label when loading the image.
	#		 d: the image options.

	#if not "img_num" in d:
	#	return
	if not "image_size" in d:
		return null
	print("Total Image Size: "+ str(d["image_size"]))
	if sim_info.user_index_img_part.get(str(d["user_id"]), 0) < d["image_size"]:
		sim_info.append_user_image(d["user_id"], d["image"], int(d["img_num"]), int(d["image_size"]))
		$image_label.text = img_label_text
		return null
	$image_label.text = ""
	print("Image Ready!")
	var image_data = Marshalls.base64_to_raw(sim_info.get_reset_user_image(d["user_id"]))
	var image = Image.new()
	if image.load_png_from_buffer(image_data):
		if image.load_jpg_from_buffer(image_data):
			return null
	return image



func update_timer(delta):
	# Updates the timer (use it in physics process).
	time += delta
	sim_info.time = time


func send_null_all_fossbots():
	# sends null to all fossbots (used when no data arrives).
	for foss_name in foss_dict.keys():
		get_node(foss_dict[foss_name]).data_received(null)

func sendGodotError(msg, fossbot_name, user_id):
	# Sends a godot error to specified user_id (uses method in js).
	window.sendErrorFromGodot(msg, fossbot_name, user_id)

func sendMessageGodotEnv(msg, user_id):
	# Sends a godot environment message to specified user_id (uses method in js).
	window.sendEnvMessageFromGodot(msg, user_id)


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
	# Updates the dropdown list to match the fossbots in foss_dict of sim_info.
	var keys1 = foss_dict.keys()
	var keys2 = sim_info.foss_dict.keys()
	var diff = []
	for key in keys2:
		if !keys1.has(key):
			diff.append(key)
	for key in diff:
		foss_dict[str(key)] = sim_info.foss_dict[key]
		$foss_dropdown.add_item(str(key))

func reset_dropdown():
	# Resets the dropdown list (with the foss_dict and user_dict). Used when we want to delete all fossbots from scene.
	foss_dict = {}
	user_dict = {}
	$foss_dropdown.clear()
	$camera_handler.set_target($camera_null.get_path())
	prev_sel_id = -1
