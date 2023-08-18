extends MeshInstance

func _ready():
	sim_info.set_foss_floor(get_node("."))

func set_material_skin(mat_skin, d):
	var material = get_surface_material(0)
	# material.normal_texture = mat_skin
	material.albedo_texture = mat_skin
	if "color" in d and d["color"] in ["yellow", "cyan", "green", "violet", "red", "white", "black", "blue"]:
		material.albedo_color = get_color_from_string(d["color"])
	if "type" in d:
		if d["type"] == "full":
			material.uv1_triplanar = false
			material.uv1_scale = Vector3(3, 2, 1)
		elif d["type"] == "tripl":
			material.uv1_triplanar = true
			var scale_x = float(d.get("scale_x", 1))
			var scale_y = float(d.get("scale_y", 1))
			material.uv1_scale = Vector3(scale_y, 1, scale_x)
		elif d["type"] == "manual":
			material.uv1_triplanar = false
			var scale_x = float(d.get("scale_x", 1))
			var scale_y = float(d.get("scale_y", 1))
			material.uv1_scale = Vector3(scale_y, scale_x, 1)
	else:
		material.uv1_triplanar = false
		material.uv1_scale = Vector3(3, 2, 1)
	set_surface_material(0, material)

func get_color_from_string(color):
	if color == 'red':
		return Color(1, 0, 0)
	elif color == 'green':
		return Color(0, 1, 0)
	elif color == 'yellow':
		return Color(1, 1, 0)
	elif color == 'cyan':
		return Color(0, 1, 1)
	elif color == 'violet':
		return Color(1, 0, 1)
	elif color == 'black':
		return Color(0, 0, 0)
	elif color == 'blue':
		return Color(0, 0, 1)
	else:	# returns white by default.
		return Color(1, 1, 1)
