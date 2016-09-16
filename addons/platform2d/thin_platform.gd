tool
extends "platform_base.gd"

export(Curve2D)       var Curve = null setget set_curve
export(float)         var BakeInterval = 5 setget set_bake_interval
export(Texture)       var LeftTexture = null setget set_left_texture
export(Texture)       var MidTexture = null setget set_mid_texture
export(Texture)       var RightTexture = null setget set_right_texture
export(float)         var Thickness = 10 setget set_thickness
export(float, 0, 1)   var Position = 0.5 setget set_position

func _ready():
	if Curve == null:
		Curve = load("addons/platform2d/thin_platform_default.tres")
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

func set_left_texture(t):
	LeftTexture = t
	update()

func set_mid_texture(t):
	MidTexture = t
	update()

func set_right_texture(t):
	RightTexture = t
	update()

func set_thickness(s):
	Thickness = s
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
		var polygon_height = Vector2(0, Position * Thickness)
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
	if point_count == 0 || MidTexture == null:
		return
	if LeftTexture != null && RightTexture != null:
		var curve_length = curve.get_baked_length()
		var left_length = LeftTexture.get_width() * Thickness / LeftTexture.get_height()
		var mid_length = MidTexture.get_width() * Thickness / MidTexture.get_height()
		var right_length = RightTexture.get_width() * Thickness / RightTexture.get_height()
		var mid_texture_count = floor(0.5 + (curve_length - left_length - right_length) / mid_length)
		var ratio_adjust = (left_length + mid_texture_count * mid_length + right_length) / curve_length
		var sections = []
		sections.append({texture = LeftTexture, limit = 1.0, scale = ratio_adjust * LeftTexture.get_height() / (Thickness * LeftTexture.get_width())})
		if mid_texture_count > 0:
			sections.append({texture = MidTexture, limit = mid_texture_count, scale = ratio_adjust * MidTexture.get_height() / (Thickness * MidTexture.get_width())})
		sections.append({texture = RightTexture, limit = 1.0, scale = ratio_adjust * RightTexture.get_height() / (Thickness * RightTexture.get_width())})
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
				i0 = 0
			var i2 = i+1
			if i2 == point_count:
				i2 = point_count-1
			normal.append((point_array[i2] - point_array[i0]).rotated(-PI/2).normalized() * Thickness)
		var u = 0
		var texture_index = 0
		var texture = sections[0].texture
		var limit   = sections[0].limit
		var scale   = sections[0].scale
		for i in range(point_count-1):
			var interval = (point_array[i+1] - point_array[i]).length()
			if i == 0:
				points[0] = point_array[i] + normal[i] * Position
				points[1] = point_array[i] - normal[i] * (1-Position)
			else:
				points[0] = points[3]
				points[1] = points[2]
			uvs[0] = Vector2(u, 1)
			uvs[1] = Vector2(u, 0)
			var length = (point_array[i+1] - point_array[i]).length()
			var next_u = u + length * scale
			if next_u > limit:
				var r = (limit - u) / (next_u - u)
				var p = point_array[i] + r * (point_array[i+1] - point_array[i])
				var n = (normal[i] + r * (normal[i+1] - normal[i])).normalized() * Thickness
				points[2] = p - n * (1-Position)
				points[3] = p + n * Position
				uvs[2] = Vector2(limit, 0)
				uvs[3] = Vector2(limit, 1)
				draw_polygon(points, colors, uvs, texture)
				texture_index = texture_index + 1
				if texture_index >= sections.size():
					break
				u = 0
				texture = sections[texture_index].texture
				limit   = sections[texture_index].limit
				scale   = sections[texture_index].scale
				points[0] = points[3]
				points[1] = points[2]
				uvs[0] = Vector2(0, 1)
				uvs[1] = Vector2(0, 0)
				u = length * (1 - r) * scale
				points[2] = point_array[i+1] - normal[i+1] * (1-Position)
				points[3] = point_array[i+1] + normal[i+1] * Position
				uvs[2] = Vector2(u, 0)
				uvs[3] = Vector2(u, 1)
				draw_polygon(points, colors, uvs, texture)
			else:
				points[2] = point_array[i+1] - normal[i+1] * (1-Position)
				points[3] = point_array[i+1] + normal[i+1] * Position
				uvs[2] = Vector2(next_u, 0)
				uvs[3] = Vector2(next_u, 1)
				draw_polygon(points, colors, uvs, texture)
				u = next_u
	else:
		var ratio = BakeInterval*MidTexture.get_height()/Thickness/MidTexture.get_width()
		var length = curve.get_baked_length() / MidTexture.get_width()
		ratio = ratio * max(1.0, floor(length+0.5)) / length
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
		var height_vec = Vector2(0, Thickness)
		var normal = Vector2Array()
		for i in range(point_count):
			var i0 = i-1
			if i0 == -1:
				i0 = 0
			var i2 = i+1
			if i2 == point_count:
				i2 = point_count-1
			normal.append((point_array[i2] - point_array[i0]).rotated(-PI/2).normalized() * Thickness)
		for i in range(point_count-1):
			if i == 0:
				points[0] = point_array[i] + normal[i] * Position
				points[1] = point_array[i] - normal[i] * (1-Position)
			else:
				points[0] = points[3]
				points[1] = points[2]
			points[2] = point_array[i+1] - normal[i+1] * (1-Position)
			points[3] = point_array[i+1] + normal[i+1] * Position
			uvs[0] = Vector2(ratio*i, 1)
			uvs[1] = Vector2(ratio*i, 0)
			uvs[2] = Vector2(ratio*(i+1), 0)
			uvs[3] = Vector2(ratio*(i+1), 1)
			var texture = MidTexture
			draw_polygon(points, colors, uvs, texture)

func get_material():
	var m = {}
	m.BakeInterval = BakeInterval
	if LeftTexture != null:
		m.LeftTexture = LeftTexture.get_path()
	if MidTexture != null:
		m.MidTexture = MidTexture.get_path()
	if RightTexture != null:
		m.RightTexture = RightTexture.get_path()
	m.Thickness = Thickness
	m.Position = Position
	return m

func set_material(m):
	BakeInterval = m.BakeInterval
	if m.has("LeftTexture"):
		LeftTexture = load(m.LeftTexture)
	if m.has("MidTexture"):
		MidTexture = load(m.MidTexture)
	if m.has("RightTexture"):
		RightTexture = load(m.RightTexture)
	Thickness = m.Thickness
	Position = m.Position
	update()
