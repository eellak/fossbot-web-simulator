extends VehicleWheel

func _ready():
	# Saves the right motor name and node path to the parent fossbot.
	get_parent().set_right_motor(name, get_node(".").get_path())

