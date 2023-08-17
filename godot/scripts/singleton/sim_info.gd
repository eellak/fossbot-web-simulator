extends Node

var time = 0
var make_noise = false

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
