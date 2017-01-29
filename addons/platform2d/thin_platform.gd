tool
extends "platform_base.gd"

export(Curve2D)               var Curve = null setget set_curve
export(float)                 var BakeInterval = 50 setget set_bake_interval
export(Texture)               var LeftTexture = null setget set_left_texture
export(Texture)               var MidTexture = null setget set_mid_texture
export(Texture)               var RightTexture = null setget set_right_texture
export(float, 0.0, 1.0, 0.01) var LeftOverflow = 0.0 setget set_left_overflow
export(float, 0.0, 1.0, 0.01) var RightOverflow = 0.0 setget set_right_overflow
export(float)                 var Thickness = 100 setget set_thickness
export(float, 0.0, 1.0, 0.01) var Position = 0.5 setget set_position

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

func set_left_overflow(o):
	LeftOverflow = o
	update()

func set_right_overflow(o):
	RightOverflow = o
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
	if is_inside_tree() && get_tree().is_editor_hint():
		var curve = get_curve()
		var point_array = baked_points(curve)
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
	var baked_points_and_length = baked_points_and_length(curve)
	var point_array = baked_points_and_length.points
	var point_count = point_array.size()
	if point_count == 0 || MidTexture == null:
		return
	var sections = []
	var curve_length = baked_points_and_length.length
	var mid_length = MidTexture.get_width() * Thickness / MidTexture.get_height()
	if LeftTexture != null && RightTexture != null:
		var left_length = (1.0 - LeftOverflow) * LeftTexture.get_width() * Thickness / LeftTexture.get_height()
		var right_length = (1.0 - RightOverflow) * RightTexture.get_width() * Thickness / RightTexture.get_height()
		var mid_texture_count = floor(0.5 + (curve_length - left_length - right_length) / mid_length)
		var ratio_adjust = (left_length + mid_texture_count * mid_length + right_length) / curve_length
		sections.append({texture = LeftTexture, limit = 1.0, scale = ratio_adjust * LeftTexture.get_height() / (Thickness * LeftTexture.get_width())})
		if mid_texture_count > 0:
			sections.append({texture = MidTexture, limit = mid_texture_count, scale = ratio_adjust * MidTexture.get_height() / (Thickness * MidTexture.get_width())})
		sections.append({texture = RightTexture, limit = 1.0, scale = ratio_adjust * RightTexture.get_height() / (Thickness * RightTexture.get_width())})
	else:
		var mid_texture_count = curve_length / mid_length
		sections.append({texture = MidTexture, limit = mid_texture_count, scale = MidTexture.get_height() / (Thickness * MidTexture.get_width())})
	draw_border(point_array, Thickness, Position, sections, LeftOverflow)

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
