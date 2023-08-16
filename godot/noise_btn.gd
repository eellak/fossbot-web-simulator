extends Button

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_fossbot_change_noise_text(noise_text):
	get_node(".").text = noise_text
