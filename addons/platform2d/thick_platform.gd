tool
extends "platform_base.gd"

export(Curve2D)               var Curve = null setget set_curve
export(float)                 var BakeInterval = 50 setget set_bake_interval
export(Texture)               var FillTexture = null setget set_fill_texture
export(float)                 var FillSize = 1.0 setget set_fill_size
export(Texture)               var TopLeftTexture = null setget set_topleft_texture
export(Texture)               var TopTexture = null setget set_top_texture
export(Texture)               var TopRightTexture = null setget set_topright_texture
export(float)                 var TopThickness = 100 setget set_top_thickness
export(float, 0.0, 1.0, 0.01) var TopPosition = 0.5 setget set_top_position
export(float, 0.0, 1.0, 0.01) var TopLeftOverflow = 0.0 setget set_topleft_overflow
export(float, 0.0, 1.0, 0.01) var TopRightOverflow = 0.0 setget set_topright_overflow
export(Texture)               var SideTexture = null setget set_side_texture
export(float)                 var SideThickness = 10 setget set_side_thickness
export(float, 0.0, 1.0, 0.01) var SidePosition = 0.5 setget set_side_position
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

func set_topleft_texture(t):
	TopLeftTexture = t
	update()

func set_topright_texture(t):
	TopRightTexture = t
	update()

func set_top_texture(t):
	TopTexture = t
	update()

func set_top_thickness(s):
	TopThickness = s
	update()
	
func set_top_position(p):
	TopPosition = p
	update()

func set_topleft_overflow(o):
	TopLeftOverflow = o
	update()

func set_topright_overflow(o):
	TopRightOverflow = o
	update()

func set_side_texture(t):
	SideTexture = t
	update()

func set_side_thickness(s):
	SideThickness = s
	update()
	
func set_side_position(p):
	SidePosition = p
	update()

func set_angle(a):
	Angle = a
	update()

func update_collision_polygon():
	if is_inside_tree() && get_tree().is_editor_hint():
		var curve = get_curve()
		var point_array = baked_points(curve)
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
	var point_array = baked_points(curve)
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
	if TopTexture != null:
		if SideTexture != null:
			var current_curve = Curve2D.new()
			var first_curve = current_curve
			var curve_is_border2
			var top_curves = []
			for i in range(curve.get_point_count()):
				current_curve.add_point(curve.get_point_pos(i), curve.get_point_in(i), curve.get_point_out(i))
				var out_normal_angle = curve.get_point_out(i).rotated(PI/2).angle()
				var is_border2 = abs(out_normal_angle) < Angle
				if i == 0:
					curve_is_border2 = is_border2
				elif is_border2 != curve_is_border2:
					if curve_is_border2:
						current_curve.set_bake_interval(BakeInterval)
						var baked_points_and_length = baked_points_and_length(current_curve)
						point_array = baked_points_and_length.points
						point_count = point_array.size()
						var sections = []
						var curve_length = baked_points_and_length.length
						var mid_length = SideTexture.get_width() * SideThickness / SideTexture.get_height()
						var mid_texture_count = curve_length / mid_length
						sections.append({texture = SideTexture, limit = mid_texture_count, scale = SideTexture.get_height() / (SideThickness * SideTexture.get_width())})
						draw_border(point_array, SideThickness, SidePosition, sections)
					else:
						top_curves.append(current_curve)
					current_curve = Curve2D.new()
					current_curve.add_point(curve.get_point_pos(i), curve.get_point_in(i), curve.get_point_out(i))
					curve_is_border2 = is_border2
			for c in top_curves:
				c.set_bake_interval(BakeInterval)
				var baked_points_and_length = baked_points_and_length(c)
				point_array = baked_points_and_length.points
				point_count = point_array.size()
				var sections = []
				var curve_length = baked_points_and_length.length
				var mid_length = TopTexture.get_width() * TopThickness / TopTexture.get_height()
				var left_overflow = 0
				if TopLeftTexture != null && TopRightTexture != null:
					var left_length = (1.0 - TopLeftOverflow) * TopLeftTexture.get_width() * TopThickness / TopLeftTexture.get_height()
					var right_length = (1.0 - TopRightOverflow) * TopRightTexture.get_width() * TopThickness / TopRightTexture.get_height()
					var mid_texture_count = floor(0.5 + (curve_length - left_length - right_length) / mid_length)
					var ratio_adjust = (left_length + mid_texture_count * mid_length + right_length) / curve_length
					sections.append({texture = TopLeftTexture, limit = 1.0, scale = ratio_adjust * TopLeftTexture.get_height() / (TopThickness * TopLeftTexture.get_width())})
					if mid_texture_count > 0:
						sections.append({texture = TopTexture, limit = mid_texture_count, scale = ratio_adjust * TopTexture.get_height() / (TopThickness * TopTexture.get_width())})
					sections.append({texture = TopRightTexture, limit = 1.0, scale = ratio_adjust * TopRightTexture.get_height() / (TopThickness * TopRightTexture.get_width())})
					left_overflow = TopLeftOverflow
				else:
					var mid_texture_count = curve_length / mid_length
					sections.append({texture = TopTexture, limit = mid_texture_count, scale = TopTexture.get_height() / (TopThickness * TopTexture.get_width())})
				draw_border(point_array, TopThickness, TopPosition, sections, left_overflow)
		else:
			var ratio1 = BakeInterval*TopTexture.get_height()/TopThickness/TopTexture.get_width()
			var ratio2 = 0
			if SideTexture != null:
				ratio2 = BakeInterval*SideTexture.get_height()/SideThickness/SideTexture.get_width()
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
				var texture = TopTexture
				var ratio = ratio1
				var thickness = TopThickness
				var position = TopPosition
				var angle = normal[i].angle()
				if SideTexture != null && abs(angle) < Angle:
					texture = SideTexture
					ratio = ratio2
					thickness = SideThickness
					position = SidePosition
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
	if TopTexture != null:
		m.TopTexture = TopTexture.get_path()
		m.TopThickness = TopThickness
		m.TopPosition = TopPosition
	if TopLeftTexture != null:
		m.TopLeftTexture = TopLeftTexture.get_path()
		m.TopLeftOverflow = TopLeftOverflow
	if TopRightTexture != null:
		m.TopRightTexture = TopRightTexture.get_path()
		m.TopRightOverflow = TopRightOverflow
	if SideTexture != null:
		m.SideTexture = SideTexture.get_path()
		m.SideThickness = SideThickness
		m.SidePosition = SidePosition
		m.Angle = Angle
	return m

func set_material(m):
	BakeInterval = m.BakeInterval
	if m.has("FillTexture"):
		FillTexture = load(m.FillTexture)
	if m.has("FillSize"):
		FillSize = m.FillSize
	if m.has("TopTexture"):
		TopTexture = load(m.TopTexture)
		TopThickness = m.TopThickness
		TopPosition = m.TopPosition
		if m.has("TopLeftTexture"):
			TopLeftTexture = load(m.TopLeftTexture)
			TopLeftOverflow = m.TopLeftOverflow
		if m.has("TopRightTexture"):
			TopRightTexture = load(m.TopRightTexture)
			TopRightOverflow = m.TopRightOverflow
	if m.has("SideTexture"):
		SideTexture = load(m.SideTexture)
		SideThickness = m.SideThickness
		SidePosition = m.SidePosition
	update()
