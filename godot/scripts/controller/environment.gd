extends WorldEnvironment

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_BrightnessSlider_value_changed(value):
	environment.background_energy = value / 50
