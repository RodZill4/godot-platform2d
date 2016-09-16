tool
extends Node2D

var object = null
var closed
var timer
var mode
var index

const handle_tex = preload("res://addons/platform2d/handle.png")
const add_tex = preload("res://addons/platform2d/add.png")
const remove_tex = preload("res://addons/platform2d/remove.png")

const MODE_NONE     = 0
const MODE_MOVE_POS = 1
const MODE_MOVE_IN  = 2
const MODE_MOVE_OUT = 3

const COLOR_1 = Color(1, 1, 1, 1)
const COLOR_2 = Color(0.5, 0.5, 1, 1)
const COLOR_3 = Color(1, 0, 0, 1)

func _ready():
	handle_tex.set_flags(0)
	add_tex.set_flags(0)
	remove_tex.set_flags(0)
	mode = MODE_NONE

func _draw():
	set_transform(get_parent().get_global_canvas_transform().affine_inverse())
	var transform = object.get_viewport().get_global_canvas_transform()*object.get_global_transform()
	var curve = object.get_curve()
	var point_count = curve.get_point_count()
	var notclosed_int = 1
	if closed:
		notclosed_int = 0
		point_count = point_count - 1
	for i in range(point_count):
		var p
		var p_in
		var p_out
		p = transform.xform(curve.get_point_pos(i))
		if i == 0 && closed:
			p_in = p+transform.basis_xform(curve.get_point_in(curve.get_point_count() - 1))
		else:
			p_in = p+transform.basis_xform(curve.get_point_in(i))
		p_out = p+transform.basis_xform(curve.get_point_out(i))
		if i > 0 || closed:
			draw_line(p, p_in, COLOR_2)
			draw_texture_rect(handle_tex, Rect2(p_in-Vector2(5, 5), Vector2(11, 11)), false)
		if i < point_count - notclosed_int:
			draw_line(p, p_out, COLOR_2)
			draw_texture_rect(handle_tex, Rect2(p_out-Vector2(5, 5), Vector2(11, 11)), false)
		draw_texture_rect(handle_tex, Rect2(p-Vector2(5, 5), Vector2(11, 11)), false)
		if curve.get_point_count() + notclosed_int >= 4:
			# minimum number of points is 3 for closed curves and 2 for others
			draw_texture_rect(remove_tex, Rect2(p+Vector2(5, 5), Vector2(11, 11)), false)
		if i < curve.get_point_count() - notclosed_int:
			var p_mid = transform.xform(0.5*(curve.get_point_pos(i)+curve.get_point_pos(i+1))+0.375*(curve.get_point_out(i)+curve.get_point_in(i+1)))
			draw_texture_rect(add_tex, Rect2(p_mid, Vector2(11, 11)), false)

func process_input_event(e):
	if e.type == InputEvent.MOUSE_BUTTON:
		if e.button_index == BUTTON_LEFT:
			if e.is_pressed():
				var transform = object.get_global_transform()
				var viewport_transform = object.get_viewport().get_global_canvas_transform()
				var pos = e.pos
				var curve = object.get_curve()
				var point_count = curve.get_point_count()
				var notclosed_int = 1
				if closed:
					notclosed_int = 0
					point_count = point_count - 1
				for i in range(point_count):
					var p_pos
					var p_in
					var p_out
					p_pos = transform.xform(curve.get_point_pos(i))
					if i == 0:
						if closed:
							p_in = p_pos+transform.basis_xform(curve.get_point_in(curve.get_point_count() - 1))
						else:
							p_in = null
					else:
						p_in = p_pos+transform.basis_xform(curve.get_point_in(i))
					p_out = p_pos+transform.basis_xform(curve.get_point_out(i))
					if (pos-viewport_transform.xform(p_pos)).length() < 6:
						mode = MODE_MOVE_POS
						index = i
						return true
					elif p_in != null && (pos-viewport_transform.xform(p_in)).length() < 6:
						mode = MODE_MOVE_IN
						index = i
						return true
					elif (pos-viewport_transform.xform(p_out)).length() < 6:
						mode = MODE_MOVE_OUT
						index = i
						return true
					elif curve.get_point_count() + notclosed_int >= 4 && Rect2(viewport_transform.xform(p_pos)+Vector2(8, 8), Vector2(15, 15)).has_point(pos):
						# Clicked on a "remove" button
						curve.remove_point(i)
						if closed && i == 0:
							curve.set_point_pos(curve.get_point_count() - 1, curve.get_point_pos(0))
							curve.set_point_in(curve.get_point_count() - 1, curve.get_point_in(0))
						update()
						object.update()
						return true
					elif closed || i < point_count - 1:
						var p_mid = transform.xform(0.5*(curve.get_point_pos(i)+curve.get_point_pos(i+1))+0.375*(curve.get_point_out(i)+curve.get_point_in(i+1)))
						if Rect2(viewport_transform.xform(p_mid)-Vector2(7, 7), Vector2(15, 15)).has_point(pos):
							# clicked on an "add" button
							var p_0 = curve.get_point_pos(i)
							var p_3 = curve.get_point_pos(i+1)
							var p_1 = p_0 + curve.get_point_out(i)
							var p_2 = p_3 + curve.get_point_in(i+1)
							var p_1_2 = 0.5*(p_1+p_2)
							var p_01_12 = 0.5*p_1_2 + 0.25*(p_0 + p_1)
							var p_12_23 = 0.5*p_1_2 + 0.25*(p_2 + p_3)
							var p_new = 0.5*(p_01_12 + p_12_23)
							curve.add_point(p_new, p_01_12 - p_new, p_12_23 - p_new, i+1)
							curve.set_point_out(i, 0.5 * curve.get_point_out(i))
							curve.set_point_in(i+2, 0.5 * curve.get_point_in(i+2))
							update()
							object.update()
							return true
			else:
				mode = MODE_NONE
				object.update_collision_polygon()
	elif e.type == InputEvent.MOUSE_MOTION && mode != MODE_NONE:
		var curve = object.get_curve()
		var transform_inv = object.get_global_transform().affine_inverse()
		var viewport_transform_inv = object.get_viewport().get_global_canvas_transform().affine_inverse()
		var pos = e.pos
		var p = transform_inv.xform(viewport_transform_inv.xform(pos))
		if mode == MODE_MOVE_POS:
			curve.set_point_pos(index, p)
			if closed && index == 0:
				curve.set_point_pos(curve.get_point_count() - 1, p)
		elif mode == MODE_MOVE_IN:
			if closed && index == 0:
				var i = curve.get_point_count() - 1
				curve.set_point_in(i, p-curve.get_point_pos(i))
			else:
				curve.set_point_in(index, p-curve.get_point_pos(index))
		elif mode == MODE_MOVE_OUT:
			curve.set_point_out(index, p-curve.get_point_pos(index))
		update()
		object.update()
		return true
	update()
	return false
