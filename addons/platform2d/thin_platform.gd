tool
extends "platform_base.gd"

const style_script = preload("res://addons/platform2d/thin_platform_style.gd")

func _ready():
	if Style == null:
		Style = preload("res://addons/platform2d/textures/thin_platform_default.tres")

func new_style():
	Style = Resource.new()
	Style.set_script(style_script)
	update()

func set_style(s):
	if s == null || s is Resource && s.script == style_script:
		.set_style(s)
	else:
		print("Set style failed")

func generate_collision_polygon():
	var curve = get_curve()
	var point_array = baked_points(curve)
	var point_count = point_array.size()
	var polygon_height = Vector2(0, 10)
	if Style != null:
		polygon_height = Vector2(0, Style.Position * Style.Thickness)
	for i in range(point_count):
		point_array.append(point_array[point_count-i-1] + polygon_height)
	return point_array

func _draw():
	if Style != null:
		var LeftTexture = Style.LeftTexture
		var MidTexture = Style.MidTexture
		var RightTexture = Style.RightTexture
		var LeftOverflow = Style.LeftOverflow
		var RightOverflow = Style.RightOverflow
		var Thickness = Style.Thickness
		var Position = Style.Position
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
