extends VehicleWheel

func _ready():
	get_parent().set_right_motor(name, get_node(".").get_path())

