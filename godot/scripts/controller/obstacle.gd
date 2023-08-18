extends RigidBody

func _ready():
	sim_info.init_obs(get_node("."))

