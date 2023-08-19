extends VehicleWheel

func _ready():
	# Saves the left motor name and node path to the parent fossbot.
	get_parent().set_left_motor(name, get_node(".").get_path())

