extends Node

var time = 0
var make_noise = false
var foss_dict = {}

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

func init_fossbot(fossbot_path):
	var n = get_node(fossbot_path)
	foss_dict[str(n.name)] = fossbot_path
