tool
extends "platform_base.gd"

var top_curves : Array
var side_curves : Array

const style_script = preload("res://addons/platform2d/thick_platform_style.gd")

func _ready():
	if Style == null:
		Style = preload("res://addons/platform2d/textures/thick_platform_default.tres")

func new_style():
	Style = Resource.new()
	Style.set_script(style_script)
	Style2 = Resource.new()
	Style2.set_script(thin_style_script)
	update()

func set_style(s):
	if s == null || s is Resource && s.script == style_script:
		.set_style(s)
	else:
		print("Set style failed")

func get_default_curve():
	return preload("res://addons/platform2d/thick_platform_default_curve.tres")

func generate_collision_polygon():
	var curve = get_curve()
	return baked_points(curve)

func get_top_curves() -> Array:
	return top_curves

func update():
	precalculate()
	.update()

func precalculate() -> void:
	if Style == null:
		return
	var Angle = Style.Angle
	var SideTexture = Style.SideTexture
	var SideThickness = Style.SideThickness
	var SidePosition = Style.SidePosition
	var curve = get_curve()
	var current_curve = Curve2D.new()
	var curve_is_border2
	var point_array
	var point_count
	top_curves = []
	side_curves = []
	for i in range(curve.get_point_count()):
		current_curve.add_point(curve.get_point_position(i), curve.get_point_in(i), curve.get_point_out(i))
		var out_normal_angle = curve.get_point_out(i).angle()
		var is_border2 = abs(out_normal_angle) > Angle
		if i == 0:
			curve_is_border2 = is_border2
		elif is_border2 != curve_is_border2:
			if curve_is_border2:
				current_curve.set_bake_interval(BakeInterval)
				var baked_points_and_length = baked_points_and_length(current_curve)
				point_array = baked_points_and_length.points
				point_count = point_array.size()
				var curve_length = baked_points_and_length.length
				var mid_length = SideTexture.get_width() * SideThickness / SideTexture.get_height()
				var mid_texture_count = curve_length / mid_length
				side_curves.append({point_array = point_array, texture = SideTexture, limit = mid_texture_count, scale = SideTexture.get_height() / (SideThickness * SideTexture.get_width())})
			else:
				top_curves.append(current_curve)
			current_curve = Curve2D.new()
			current_curve.add_point(curve.get_point_position(i), curve.get_point_in(i), curve.get_point_out(i))
			curve_is_border2 = is_border2

func _draw():
	if Style != null:
		var FillTexture = Style.FillTexture
		var FillNormalMap = Style.FillNormalMap
		var FillSize = Style.FillSize
		var TopLeftTexture = Style.TopLeftTexture
		var TopTexture = Style.TopTexture
		var TopRightTexture = Style.TopRightTexture
		var TopThickness = Style.TopThickness
		var TopPosition = Style.TopPosition
		var TopLeftOverflow = Style.TopLeftOverflow
		var TopRightOverflow = Style.TopRightOverflow
		var SideTexture = Style.SideTexture
		var SideThickness = Style.SideThickness
		var SidePosition = Style.SidePosition
		var Angle = Style.Angle
		var curve = get_curve()
		var point_array = baked_points(curve)
		var point_count = point_array.size()
		if point_count == 0:
			return
		point_array.remove(point_count - 1)
		# Fill
		if FillTexture != null:
			var scale = FillSize/FillTexture.get_width()
			var uvs = PoolVector2Array()
			for p in point_array:
				uvs.append(scale*p)
			draw_colored_polygon(point_array, Color(1, 1, 1, 1), uvs, FillTexture, FillNormalMap)
		# Draw border
		if TopTexture != null:
			if SideTexture != null:
				for c in side_curves:
					draw_border(self, c.point_array, SideThickness, SidePosition, [ c ])
				for c in top_curves:
					draw_top(self, c, Style.TopLeftTexture, Style.TopTexture, Style.TopRightTexture, Style.TopLeftOverflow, Style.TopRightOverflow, Style.TopThickness, Style.TopPosition)
			else:
				var baked_points_and_length = baked_points_and_length(curve)
				point_array = baked_points_and_length.points
				point_count = point_array.size()
				var sections = []
				var curve_length = baked_points_and_length.length
				var length = TopTexture.get_width() * TopThickness / TopTexture.get_height()
				var texture_count = curve_length / length
				sections.append({texture = TopTexture, limit = texture_count, scale = TopTexture.get_height() / (TopThickness * TopTexture.get_width())})
				draw_border(self, point_array, TopThickness, TopPosition, sections)
