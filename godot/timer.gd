extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_fossbot_timer(time_passed):
	get_node(".").text = time_passed
