extends Button

var make_noise = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _pressed():
	# If the button is pressed -> sets the boolean make noise of sim_info to true.
	# If it is pressed again, it sets it to false.
	make_noise = !make_noise
	if make_noise:
		text = "Stop Noise"
	else:
		text = "Make Noise"
	sim_info.make_noise = make_noise
