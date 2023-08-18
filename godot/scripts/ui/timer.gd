extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	_on_foss_handler_timer()

func _on_foss_handler_timer():
	var time = sim_info.time
	var mils = fmod(time,1)*1000
	var secs = fmod(time,60)
	var mins = fmod(time, 60*60) / 60
	var hr = fmod(fmod(time,3600 * 60) / 3600,24)
	var time_passed = "%02d : %02d : %02d : %03d" % [hr,mins,secs,mils]
	text = time_passed
