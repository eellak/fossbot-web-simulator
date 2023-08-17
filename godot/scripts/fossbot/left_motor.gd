extends VehicleWheel

func _ready():
	get_parent().set_left_motor(name, get_node(".").get_path())

