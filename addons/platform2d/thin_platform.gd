tool
extends "platform_base.gd"

func _ready():
	if Style == null:
		Style = preload("res://addons/platform2d/textures/thin_platform_default.tres")

func new_style():
	Style = Resource.new()
	Style.set_script(thin_style_script)
	Style2 = Resource.new()
	Style2.set_script(thin_style_script)
	update()

func set_style(s):
	if s == null || s is Resource && s.script == thin_style_script:
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
		draw_top(self, get_curve(), Style.LeftTexture, Style.MidTexture, Style.RightTexture, Style.LeftOverflow, Style.RightOverflow, Style.Thickness, Style.Position)
