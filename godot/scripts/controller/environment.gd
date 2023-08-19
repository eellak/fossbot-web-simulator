extends WorldEnvironment

func _ready():
	pass

func _on_BrightnessSlider_value_changed(value):
	# changes the brightness to specified value.
	environment.background_energy = value / 50
