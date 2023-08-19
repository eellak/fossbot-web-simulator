extends Node

var time = 0
var make_noise = false
var foss_dict = {}	# dictionary with fossbots in the scene: key the name of the fossbot and value the scene path to it.
var floor_dict = {}	# dictionary with all the floors in the scene: key the floor index and value the actual floor node.
var user_image = {}	# dictionary with the base64 img of each user_id: the key is the user_id and the value is a priority queue with parts of the image.
var user_index_img_part = {}	# a dictionary that saves a counter for each user_id and their images (parts).
var foss_handler_node	# saves the current foss handler node.
var obs_list = []	# a list with all the obstacles
var pq = preload("res://scripts/data_struct/pq.gd")	# preloads priority queue.

var horizontal_ground = true

func _ready():
	pass # Replace with function body.

func get_time():
	# Returns the elapsed time from the timer.
	return time

func get_make_noise():
	# Returns true if the make_noise button is pressed. Else false.
	return make_noise

func reset_info():
	# Resets the info saved by the singleton.
	# It is used in reset_all (when reseting a scene, so some data of this singleton will be reset):
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
	# Saves fossbot node in foss_dict of this singleton.
	# Param: fossbot_path: the path of the fossbot to be saved.
	var n = get_node(fossbot_path)
	foss_dict[str(n.name)] = fossbot_path

func init_foss_handler(new_foss_handler):
	# Saves foss_handler to specified variable in this singleton.
	foss_handler_node = new_foss_handler

func set_foss_floor(new_floor):
	# Saves the foss_floor in dictionary of this singleton. The floor takes a floor index in this dictionary.
	var indx = floor_dict.size()
	floor_dict[str(indx)] = new_floor

func append_user_image(user_id, img_part, img_num, img_size):
	# Saves images part to a priority queue so it can then reconstruct the entire image for each user.
	# Param: user_id: the id of the user.
	#		 img_part: the part of the base64 string of the image.
	#		 img_num: the number of slice of the string.
	#		 img_size: the total number of slices for the image.
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
	# Returns and erases the base64 image of a user. Used when 
	# we want to get the image and erase it after (so a new one can be saved).
	var u_img = ""
	while !user_image[user_id].empty():
		u_img += user_image[user_id].pop().img
	reset_user_image(user_id)
	return u_img

func reset_user_image(user_id):
	# Erases the base64 image of a user. Used when the image has been loaded to floor or terrain (so a new one can be saved).
	user_image.erase(user_id)
	user_index_img_part.erase(user_id)

func init_obs(new_obs):
	# Puts an obstacle to the obstacle list of this singleton.
	# Param: new_obs (node): the node of the new obstacle to be added in the list.
	obs_list.append(new_obs)

func remove_all_extra_nodes():
	# Removes all extra nodes (like fossbots and obstacles) from the scene.
	# It is used if user wants to update terrain (so there will be no clipping with the old obstacles).
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
