extends RigidBody

func _ready():
	# Initializes obstacle by saving it to a list in sim_info.
	sim_info.init_obs(get_node("."))

