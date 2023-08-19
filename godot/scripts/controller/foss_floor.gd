extends MeshInstance

var init_mesh
var init_col_shape
func _ready():
	sim_info.set_foss_floor(get_node("."))	# puts floor in foss_floor dict (located in sim_info).
	init_mesh = mesh.duplicate(true).duplicate(true)	# duplicates floor mesh and collision shape.
	init_col_shape = get_child(0).get_child(0).shape.duplicate(true).duplicate(true)

func set_material_skin(mat_skin, d):
	# sets an image to floor.
	# Param: mat_skin: the image to be set on the floor.
	#		 d: other image options (dictionary).
	var material = get_surface_material(0)
	# material.normal_texture = mat_skin
	material.albedo_texture = mat_skin
	if "color" in d and d["color"] in ["yellow", "cyan", "green", "violet", "red", "white", "black", "blue"]:
		material.albedo_color = get_color_from_string(d["color"])
	if "type" in d:
		if d["type"] == "full":	# resizes image automatically to match the floor.
			material.uv1_triplanar = false
			material.uv1_scale = Vector3(3, 2, 1)
		elif d["type"] == "tripl":	# uses triplanar (many images) to put the image on the floor.
			material.uv1_triplanar = true
			var scale_x = float(d.get("scale_x", 1))
			var scale_y = float(d.get("scale_y", 1))
			material.uv1_scale = Vector3(scale_y, 1, scale_x)
		elif d["type"] == "manual":	# resizes the image by scecified parameters.
			material.uv1_triplanar = false
			var scale_x = float(d.get("scale_x", 1))
			var scale_y = float(d.get("scale_y", 1))
			material.uv1_scale = Vector3(scale_y, scale_x, 1)
	else:
		material.uv1_triplanar = false
		material.uv1_scale = Vector3(3, 2, 1)
	set_surface_material(0, material)

func get_color_from_string(color):
	# Takes as input a color string and returns the color for the fossbot floor.
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


var width;
var height;

var heightData = {}

var vertices = PoolVector3Array()
var UVs = PoolVector2Array()
var normals = PoolVector3Array()

func reset_mesh():
	# resets the properties of the floor (used when loading new terrain, so it can have more accurate represantation).
	mesh = init_mesh
	#mesh = mesh.duplicate(true)
	vertices = PoolVector3Array()
	UVs = PoolVector2Array()
	normals = PoolVector3Array()
	heightData = {}
	tmpMesh = Mesh.new()
	get_child(0).get_child(0).shape = init_col_shape

var tmpMesh = Mesh.new()

func load_terrain(heightmap: Image, intensity):
	# Loads terrain on floor
	# Param: heightmap: the image to create the terrain from.
	# 		 intensity: how high the heightmap will be.
	reset_mesh()
	var size_x = mesh.size.x
	var size_y = mesh.size.z
	heightmap.resize(size_x, size_y)

	width = heightmap.get_width()
	height = heightmap.get_height()

	if float(intensity) < 3:
		sim_info.horizontal_ground = true
	else:
		sim_info.horizontal_ground = false

	# parse image file
	heightmap.lock()
	for x in range(0,width):
		for y in range(0,height):
			heightData[Vector2(x - (size_x / 2),y - (size_y / 2))] = heightmap.get_pixel(x,y).r*float(intensity)
	heightmap.unlock()

	# generate terrain
	for x in range(0,width-1):
		for y in range(0,height-1):
			createQuad(x - (size_x / 2),y - (size_y / 2))

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(get_surface_material(0))

	for v in vertices.size():
		st.add_color(Color(1,1,1))
		st.add_uv(UVs[v])
		st.add_normal(normals[v])
		st.add_vertex(vertices[v])

	st.commit(tmpMesh)

	mesh = tmpMesh
	var shape = ConcavePolygonShape.new()
	shape.set_faces(tmpMesh.get_faces())
	get_child(0).get_child(0).shape = shape


func createQuad(x,y):
	var vert1 # vertex positions (Vector2)
	var vert2
	var vert3
	
	var side1 # sides of each triangle (Vector3)
	var side2
	
	var normal # normal for each triangle (Vector3)
	
	# triangle 1
	vert1 = Vector3(x,heightData[Vector2(x,y)],-y)
	vert2 = Vector3(x,heightData[Vector2(x,y+1)],-y-1)
	vert3 = Vector3(x+1,heightData[Vector2(x+1,y+1)],-y-1)
	vertices.push_back(vert1)
	vertices.push_back(vert2)
	vertices.push_back(vert3)
	
	UVs.push_back(Vector2(vert1.x/5, -vert1.z/5))
	UVs.push_back(Vector2(vert2.x/5, -vert2.z/5))
	UVs.push_back(Vector2(vert3.x/5, -vert3.z/5))
	
	side1 = vert2-vert1
	side2 = vert2-vert3
	normal = side1.cross(side2)
	
	for i in range(0,3):
		normals.push_back(normal)
	
	# triangle 2
	vert1 = Vector3(x,heightData[Vector2(x,y)],-y)
	vert2 = Vector3(x+1,heightData[Vector2(x+1,y+1)],-y-1)
	vert3 = Vector3(x+1,heightData[Vector2(x+1,y)],-y)
	vertices.push_back(vert1)
	vertices.push_back(vert2)
	vertices.push_back(vert3)
	
	UVs.push_back(Vector2(vert1.x/5, -vert1.z/5))
	UVs.push_back(Vector2(vert2.x/5, -vert2.z/5))
	UVs.push_back(Vector2(vert3.x/5, -vert3.z/5))
	
	side1 = vert2-vert1
	side2 = vert2-vert3
	normal = side1.cross(side2)
	
	for i in range(0,3):
		normals.push_back(normal)



