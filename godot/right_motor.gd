extends VehicleWheel

func _ready():
	get_parent().set_right_motor_name(name)

