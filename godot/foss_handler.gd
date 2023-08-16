extends Spatial

var foss_dict = {}
var prev_sel_id = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	var sel_id = $foss_dropdown.get_selected_id()
	if prev_sel_id != sel_id:
		var f_name = $foss_dropdown.get_item_text(sel_id)
		$camera_handler.set_target(foss_dict[f_name])
		prev_sel_id = sel_id

func _on_fossbot_fossbot(fossbot_path):
	var n = get_node(fossbot_path)
	foss_dict[str(n.name)] = fossbot_path
	$foss_dropdown.add_item(str(n.name))
