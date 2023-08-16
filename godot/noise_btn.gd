extends Button

var make_noise = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _pressed():
	make_noise = !make_noise
	if make_noise:
		text = "Stop Noise"
	else:
		text = "Make Noise"
	sim_info.make_noise = make_noise
