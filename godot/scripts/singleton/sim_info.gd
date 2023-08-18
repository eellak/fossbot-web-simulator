extends Node

var time = 0
var make_noise = false
var foss_dict = {}	# dictionary with fossbots in the scene: key the name of the fossbot and value the scene path to it.
var floor_dict = {}	# dictionary with all the floors in the scene: key the floor index and value the actual floor node.
var user_image = {}	# dictionary with the base64 img of each user_id: the key is the user_id and the value is a priority queue with parts of the image.
var user_index_img_part = {}	# a dictionary that saves a counter for each user_id and their images (parts).
var foss_handler_node	# saves the current foss handler node.
var obs_list = []	# a list with all the obstacles
var pq = preload("res://scripts/data_struct/pq.gd")

var horizontal_ground = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_time():
	return time

func get_make_noise():
	return make_noise

func reset_info():
	# used in reset_all:
	time = 0
	make_noise = false
	foss_dict = {}
	floor_dict = {}
	obs_list = []
	foss_handler_node = null
	user_image = {}
	user_index_img_part = {}
	horizontal_ground = true

func init_fossbot(fossbot_path):
	var n = get_node(fossbot_path)
	foss_dict[str(n.name)] = fossbot_path

func init_foss_handler(new_foss_handler):
	foss_handler_node = new_foss_handler

func set_foss_floor(new_floor):
	var indx = floor_dict.size()
	floor_dict[str(indx)] = new_floor

func append_user_image(user_id, img_part, img_num, img_size):
	#user_id = str(user_id)
	if not user_id in user_image:
		user_index_img_part[user_id] = 1
		user_image[user_id] = pq.new()
		user_image[user_id].make()
		user_image[user_id].push({pqval = abs(img_size - img_num), img=img_part})
	else:
		user_index_img_part[user_id] += 1
		user_image[user_id].push({pqval = abs(img_size - img_num), img=img_part})
	print("Current Image Part: " + str(user_index_img_part[user_id]))

func get_reset_user_image(user_id):
	var u_img = ""
	while !user_image[user_id].empty():
		u_img += user_image[user_id].pop().img
	reset_user_image(user_id)
	return u_img

func reset_user_image(user_id):
	user_image.erase(user_id)
	user_index_img_part.erase(user_id)

func init_obs(new_obs):
	obs_list.append(new_obs)

func remove_all_extra_nodes():
	for n_path in foss_dict.values():
		var n = get_node(n_path)
		n.queue_free()
	foss_dict = {}
	foss_handler_node.reset_dropdown()
	for obs in obs_list:
		obs.queue_free()
	obs_list = []
	user_image = {}
	user_index_img_part = {}
