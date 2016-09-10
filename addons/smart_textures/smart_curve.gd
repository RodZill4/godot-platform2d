tool
extends "platform_base.gd"

export(Curve2D)       var Curve = null setget set_curve
export(float)         var BakeInterval = 5 setget set_bake_interval
export(Texture)       var LeftTexture = null setget set_left_texture
export(Texture)       var MidTexture = null setget set_mid_texture
export(Texture)       var RightTexture = null setget set_right_texture
export(float)         var Height = 10 setget set_height
export(float, 0, 1)   var Position = 0.5 setget set_position

func _ready():
	if Curve == null:
		Curve = load("addons/smart_textures/smart_curve_default.tres")
		Curve = Curve.duplicate()
	Curve.connect("changed", self, "update")

func get_curve():
	return Curve

func set_curve(c):
	Curve = c
	update()

func set_bake_interval(i):
	BakeInterval = i
	update()

func set_left_texture(t):
	LeftTexture = t
	update()

func set_mid_texture(t):
	MidTexture = t
	update()

func set_right_texture(t):
	RightTexture = t
	update()

func set_height(s):
	Height = s
	update()
	update_collision_polygon()

func set_position(p):
	Position = p
	update()
	update_collision_polygon()

func update_collision_polygon():
	if get_tree() != null && get_tree().is_editor_hint():
		var curve = get_curve()
		var point_array = curve.get_baked_points()
		var point_count = point_array.size()
		var polygon_height = Vector2(0, Position * Height)
		for i in range(point_count):
			point_array.append(point_array[point_count-i-1] + polygon_height)
		var polygon = get_node("CollisionPolygon2D")
		if polygon == null:
			polygon = CollisionPolygon2D.new()
			polygon.set_name("CollisionPolygon2D")
			polygon.hide()
			add_child(polygon)
			polygon.set_owner(get_owner())
		polygon.set_polygon(point_array)

func _draw():
	var curve = get_curve()
	var point_array = curve.get_baked_points()
	var point_count = point_array.size()
	if point_count == 0:
		return
	# Draw border
	if MidTexture != null:
		var ratio = BakeInterval*MidTexture.get_height()/Height/MidTexture.get_width()
		var points = Vector2Array()
		points.push_back(Vector2(0, 0))
		points.push_back(Vector2(0, 0))
		points.push_back(Vector2(0, 0))
		points.push_back(Vector2(0, 0))
		var colors = ColorArray()
		colors.push_back(Color(1.0, 1.0, 1.0))
		colors.push_back(Color(1.0, 1.0, 1.0))
		colors.push_back(Color(1.0, 1.0, 1.0))
		colors.push_back(Color(1.0, 1.0, 1.0))
		var uvs = Vector2Array()
		uvs.push_back(Vector2(0, 0))
		uvs.push_back(Vector2(0, 0))
		uvs.push_back(Vector2(0, 0))
		uvs.push_back(Vector2(0, 0))
		var height_vec = Vector2(0, Height)
		for i in range(point_count-1):
			if i == 0:
				points[0] = point_array[i] + height_vec * Position
				points[1] = point_array[i] - height_vec * (1-Position)
			else:
				points[0] = points[3]
				points[1] = points[2]
			points[2] = point_array[i+1] - height_vec * (1-Position)
			points[3] = point_array[i+1] + height_vec * Position
			uvs[0] = Vector2(ratio*i, 1)
			uvs[1] = Vector2(ratio*i, 0)
			uvs[2] = Vector2(ratio*(i+1), 0)
			uvs[3] = Vector2(ratio*(i+1), 1)
			var texture = MidTexture
			draw_polygon(points, colors, uvs, texture)

func get_material():
	var m = {}
	m.BakeInterval = BakeInterval
	if MidTexture != null:
		m.MidTexture = MidTexture.get_path()
	m.Height = Height
	m.Position = Position
	return m

func set_material(m):
	BakeInterval = m.BakeInterval
	if m.has("MidTexture"):
		MidTexture = load(m.MidTexture)
	Height = m.Height
	Position = m.Position
	update()
