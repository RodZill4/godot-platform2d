tool
extends "platform_base.gd"

export(Curve2D)               var Curve = null setget set_curve
export(float)                 var BakeInterval = 5 setget set_bake_interval
export(Texture)               var FillTexture = null setget set_fill_texture
export(float)                 var FillSize = 1.0 setget set_fill_size
export(Texture)               var BorderTexture1 = null setget set_border_texture1
export(float)                 var BorderThickness1 = 10 setget set_border_thickness1
export(float, 0.0, 1.0, 0.01) var BorderPosition1 = 0.5 setget set_border_position1
export(Texture)               var BorderTexture2 = null setget set_border_texture2
export(float)                 var BorderThickness2 = 10 setget set_border_thickness2
export(float, 0.0, 1.0, 0.01) var BorderPosition2 = 0.5 setget set_border_position2
export(float, 0.0, 3.2, 0.01) var Angle = 0.5 setget set_angle

func _ready():
	if Curve == null:
		Curve = load("addons/platform2d/thick_platform_default.tres")
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

func set_fill_size(s):
	FillSize = s
	update()

func set_border_texture1(t):
	BorderTexture1 = t
	update()

func set_border_thickness1(s):
	BorderThickness1 = s
	update()
	
func set_border_position1(p):
	BorderPosition1 = p
	update()

func set_border_texture2(t):
	BorderTexture2 = t
	update()

func set_border_thickness2(s):
	BorderThickness2 = s
	update()
	
func set_border_position2(p):
	BorderPosition2 = p
	update()

func set_angle(a):
	Angle = a
	update()

func update_collision_polygon():
	if is_inside_tree() && get_tree().is_editor_hint():
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
		var scale = FillSize/FillTexture.get_width()
		var uvs = Vector2Array()
		for p in point_array:
			uvs.append(scale*p)
		draw_colored_polygon(point_array, Color(1, 1, 1, 1), uvs, FillTexture)
	# Draw border
	if BorderTexture1 != null:
		if BorderTexture2 != null:
			var current_curve = Curve2D.new()
			var first_curve = current_curve
			var curve_is_border2
			var border_1_curves = []
			for i in range(curve.get_point_count()):
				current_curve.add_point(curve.get_point_pos(i), curve.get_point_in(i), curve.get_point_out(i))
				var out_normal_angle = curve.get_point_out(i).rotated(PI/2).angle()
				var is_border2 = abs(out_normal_angle) < Angle
				if i == 0:
					curve_is_border2 = is_border2
				elif is_border2 != curve_is_border2:
					if curve_is_border2:
						current_curve.set_bake_interval(BakeInterval)
						var point_array = current_curve.get_baked_points()
						var point_count = point_array.size()
						var sections = []
						var curve_length = current_curve.get_baked_length()
						var mid_length = BorderTexture2.get_width() * BorderThickness2 / BorderTexture2.get_height()
						var mid_texture_count = curve_length / mid_length
						sections.append({texture = BorderTexture2, limit = mid_texture_count, scale = BorderTexture2.get_height() / (BorderThickness2 * BorderTexture2.get_width())})
						draw_border(point_array, BorderThickness2, BorderPosition2, sections)
					else:
						border_1_curves.append(current_curve)
					current_curve = Curve2D.new()
					current_curve.add_point(curve.get_point_pos(i), curve.get_point_in(i), curve.get_point_out(i))
					curve_is_border2 = is_border2
			for c in border_1_curves:
				c.set_bake_interval(BakeInterval)
				var point_array = c.get_baked_points()
				var point_count = point_array.size()
				var sections = []
				var curve_length = c.get_baked_length()
				var mid_length = BorderTexture1.get_width() * BorderThickness1 / BorderTexture1.get_height()
				var mid_texture_count = curve_length / mid_length
				sections.append({texture = BorderTexture1, limit = mid_texture_count, scale = BorderTexture1.get_height() / (BorderThickness1 * BorderTexture1.get_width())})
				draw_border(point_array, BorderThickness1, BorderPosition1, sections)
		else:
			var ratio1 = BakeInterval*BorderTexture1.get_height()/BorderThickness1/BorderTexture1.get_width()
			var ratio2 = 0
			if BorderTexture2 != null:
				ratio2 = BakeInterval*BorderTexture2.get_height()/BorderThickness2/BorderTexture2.get_width()
			point_array.append(point_array[0])
			point_array.append(point_array[1])
			var points = Vector2Array()
			points.push_back(Vector2(0, 0))
			points.push_back(Vector2(0, 0))
			points.push_back(Vector2(0, 0))
			var colors = ColorArray()
			colors.push_back(Color(1.0, 1.0, 1.0))
			colors.push_back(Color(1.0, 1.0, 1.0))
			colors.push_back(Color(1.0, 1.0, 1.0))
			var uvs = Vector2Array()
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
				var texture = BorderTexture1
				var ratio = ratio1
				var thickness = BorderThickness1
				var position = BorderPosition1
				var angle = normal[i].angle()
				if BorderTexture2 != null && abs(angle) < Angle:
					texture = BorderTexture2
					ratio = ratio2
					thickness = BorderThickness2
					position = BorderPosition2
				var i2 = i+1
				if i2 == point_count:
					i2 = 0
				if i == 0:
					points[0] = point_array[i]+normal[i] * thickness * (1-position)
					points[1] = point_array[i]-normal[i] * thickness * position
				else:
					points[0] = points[1]
					points[1] = points[2]
				uvs[0] = Vector2(ratio*i, 0)
				uvs[1] = Vector2(ratio*i, 1)
				points[2] = point_array[i2]-normal[i2] * thickness * position
				uvs[2] = Vector2(ratio*(i+1), 1)
				draw_polygon(points, colors, uvs, texture)
				points[1] = point_array[i2]+normal[i2] * thickness * (1-position)
				uvs[1] = Vector2(ratio*(i+1), 0)
				draw_polygon(points, colors, uvs, texture)

func get_material(): 
	var m = {}
	m.BakeInterval = BakeInterval
	if FillTexture != null:
		m.FillTexture = FillTexture.get_path()
		m.FillSize = FillSize
	if BorderTexture1 != null:
		m.BorderTexture1 = BorderTexture1.get_path()
		m.BorderThickness1 = BorderThickness1
		m.BorderPosition1 = BorderPosition1
	if BorderTexture2 != null:
		m.BorderTexture2 = BorderTexture2.get_path()
		m.BorderThickness2 = BorderThickness2
		m.BorderPosition2 = BorderPosition2
		m.Angle = Angle
	return m

func set_material(m):
	BakeInterval = m.BakeInterval
	if m.has("FillTexture"):
		FillTexture = load(m.FillTexture)
	if m.has("FillSize"):
		FillSize = m.FillSize
	if m.has("BorderTexture1"):
		BorderTexture1 = load(m.BorderTexture1)
		BorderThickness1 = m.BorderThickness1
		BorderPosition1 = m.BorderPosition1
	if m.has("BorderTexture2"):
		BorderTexture2 = load(m.BorderTexture2)
		BorderThickness2 = m.BorderThickness2
		BorderPosition2 = m.BorderPosition2
	update()
