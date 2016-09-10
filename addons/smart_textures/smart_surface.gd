tool
extends "platform_base.gd"

export(Curve2D) var Curve = null setget set_curve
export(float)   var BakeInterval = 5 setget set_bake_interval
export(Texture) var FillTexture = null setget set_fill_texture
export(float)   var FillScale = 1.0 setget set_fill_scale
export(Texture) var BorderTexture1 = null setget set_border_texture1
export(float)   var BorderSize = 10 setget set_border_size
export(float, 0, 1)   var BorderPosition = 0.5 setget set_border_position
export(Texture) var BorderTexture2 = null setget set_border_texture2
export(float)   var Angle = 0.5 setget set_angle

func _ready():
	if Curve == null:
		Curve = load("addons/smart_textures/smart_surface_default.tres")
		Curve = Curve.duplicate()
	Curve.connect("changed", self, "update")

func get_curve():
	return Curve

func set_curve(c):
	Curve = c
	Curve.set_bake_interval(BakeInterval)
	update()
	update_collision_polygon()

func set_bake_interval(i):
	BakeInterval = i
	Curve.set_bake_interval(BakeInterval)
	update()
	update_collision_polygon()

func set_fill_texture(t):
	FillTexture = t
	update()

func set_fill_scale(s):
	FillScale = s
	update()

func set_border_texture1(t):
	BorderTexture1 = t
	update()

func set_border_size(s):
	BorderSize = s
	update()
	
func set_border_position(p):
	BorderPosition = p
	update()

func set_border_texture2(t):
	BorderTexture2 = t
	update()

func set_angle(a):
	Angle = a
	update()

func update_collision_polygon():
	if get_tree() != null && get_tree().is_editor_hint():
		var curve = get_curve()
		var point_array = curve.get_baked_points()
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
	point_array.remove(point_count - 1)
	# Fill
	if FillTexture != null:
		var uvs = Vector2Array()
		for p in point_array:
			uvs.append(FillScale*p)
		draw_colored_polygon(point_array, Color(1, 1, 1, 1), uvs, FillTexture)
	# Draw border
	if BorderTexture1 != null:
		var ratio = BakeInterval*BorderTexture1.get_height()/BorderSize/BorderTexture1.get_width()
		point_array.append(point_array[0])
		point_array.append(point_array[1])
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
		var normal = Vector2Array()
		for i in range(point_count):
			var i0 = i-1
			if i0 == -1:
				i0 = point_count - 1
			var i2 = i+1
			if i2 == point_count:
				i2 = 0
			normal.append((point_array[i2] - point_array[i0]).rotated(PI/2).normalized())
		for i in range(point_count):
			var i2 = i+1
			if i2 == point_count:
				i2 = 0
			if i == 0:
				points[0] = point_array[i]+normal[i] * BorderSize * (1-BorderPosition)
				points[1] = point_array[i]-normal[i] * BorderSize * BorderPosition
			else:
				points[0] = points[3]
				points[1] = points[2]
			points[2] = point_array[i2]-normal[i2] * BorderSize * BorderPosition
			points[3] = point_array[i2]+normal[i2] * BorderSize * (1-BorderPosition)
			uvs[0] = Vector2(ratio*i, 0)
			uvs[1] = Vector2(ratio*i, 1)
			uvs[2] = Vector2(ratio*(i+1), 1)
			uvs[3] = Vector2(ratio*(i+1), 0)
			var texture = BorderTexture1
			var angle = normal[i].angle()
			if BorderTexture2 != null && abs(angle) < Angle:
				texture = BorderTexture2
			draw_polygon(points, colors, uvs, texture)

func get_material():
	var m = {}
	m.BakeInterval = BakeInterval
	if FillTexture != null:
		m.FillTexture = FillTexture.get_path()
		m.FillScale = FillScale
	if BorderTexture1 != null:
		m.BorderTexture1 = BorderTexture1.get_path()
		m.BorderSize = BorderSize
		m.BorderPosition = BorderPosition
	return m

func set_material(m):
	BakeInterval = m.BakeInterval
	if m.has("FillTexture"):
		FillTexture = load(m.FillTexture)
		FillScale = m.FillScale
	if m.has("BorderTexture1"):
		BorderTexture1 = load(m.BorderTexture1)
		BorderSize = m.BorderSize
		BorderPosition = m.BorderPosition
	update()
