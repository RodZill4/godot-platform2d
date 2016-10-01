tool
extends EditorPlugin

var is_godot21
var edited_object = null
var editor        = null
var toolbar       = null
var closed        = false

var handles       = []
var handle_mode
var handle_index
var buttons       = []

const thin_platform_script = preload("res://addons/platform2d/thin_platform.gd")
const thick_platform_script = preload("res://addons/platform2d/thick_platform.gd")
const curve_editor_script = preload("res://addons/platform2d/curve_editor.gd")

const handle_tex = preload("res://addons/platform2d/handle.png")
const add_tex = preload("res://addons/platform2d/add.png")
const remove_tex = preload("res://addons/platform2d/remove.png")

const HANDLE_NONE   = 0
const HANDLE_POS    = 1
const HANDLE_IN     = 2
const HANDLE_OUT    = 3
const BUTTON_ADD    = 4
const BUTTON_REMOVE = 5

const COLOR_1 = Color(1, 1, 1, 1)
const COLOR_2 = Color(0.5, 0.5, 1, 1)
const COLOR_3 = Color(1, 0, 0, 1)

func _enter_tree():
	var godot_version = OS.get_engine_version()
	is_godot21 = godot_version.major == "2" && godot_version.minor == "1"
	add_custom_type("ThinPlatform",  "StaticBody2D", thin_platform_script,  preload("res://addons/platform2d/thin_platform_icon.png"))
	add_custom_type("ThickPlatform", "StaticBody2D", thick_platform_script, preload("res://addons/platform2d/thick_platform_icon.png"))
	handle_tex.set_flags(0)
	add_tex.set_flags(0)
	remove_tex.set_flags(0)

func _exit_tree():
	make_visible(false)
	remove_custom_type("SmartCurve")
	remove_custom_type("SmartSurface")

func handles(o):
	if o.get_script() == thick_platform_script || o.get_script() == thin_platform_script:
		return true
	else:
		return false

func edit(o):
	edited_object = o

func make_visible(b):
	if b:
		if is_godot21:
			if editor == null:
				var viewport = edited_object.get_viewport()
				editor = curve_editor_script.new()
				editor.plugin = self
				viewport.add_child(editor)
				viewport.connect("size_changed", editor, "update")
		else:
			closed = (edited_object.get_script() == thick_platform_script)
			update()
		if toolbar == null:
			toolbar = preload("res://addons/platform2d/toolbar.tscn").instance()
			toolbar.plugin = self
			toolbar.object = edited_object
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	else:
		if editor != null:
			editor.queue_free()
			editor = null
		if toolbar != null:
			toolbar.queue_free()
			toolbar = null

func update():
	if is_godot21:
		editor.update()
	else:
		update_canvas()

func int_coord(p):
	return Vector2(round(p.x), round(p.y))

func forward_draw_over_canvas(canvas_xform, canvas):
	var transform = canvas_xform*edited_object.get_global_transform()
	var curve = edited_object.get_curve()
	var point_count = curve.get_point_count()
	var notclosed_int = 1
	if closed:
		notclosed_int = 0
		point_count = point_count - 1
	buttons = []
	handles = []
	for i in range(point_count):
		var p
		var p_in
		var p_out
		var button_rect
		p = transform.xform(curve.get_point_pos(i))
		if i == 0 && closed:
			p_in = p+transform.basis_xform(curve.get_point_in(curve.get_point_count() - 1))
		else:
			p_in = p+transform.basis_xform(curve.get_point_in(i))
		p_out = p+transform.basis_xform(curve.get_point_out(i))
		if i > 0 || closed:
			canvas.draw_line(p, p_in, COLOR_2)
			canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p_in)-Vector2(5, 5), Vector2(11, 11)), false)
			handles.append({ pos = p_in, mode = HANDLE_IN, index = i })
		if i < point_count - notclosed_int:
			canvas.draw_line(p, p_out, COLOR_2)
			canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p_out)-Vector2(5, 5), Vector2(11, 11)), false)
			handles.append({ pos = p_out, mode = HANDLE_OUT, index = i })
		canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p)-Vector2(5, 5), Vector2(11, 11)), false)
		handles.append({ pos = p, mode = HANDLE_POS, index = i })
		if curve.get_point_count() + notclosed_int >= 4:
			# minimum number of points is 3 for closed curves and 2 for others
			button_rect = Rect2(int_coord(p)+Vector2(5, 5), remove_tex.get_size())
			canvas.draw_texture_rect(remove_tex, button_rect, false)
			buttons.append({ rect = button_rect, type = BUTTON_REMOVE, index = i })
		if i < curve.get_point_count() - notclosed_int:
			var p_mid = transform.xform(0.5*(curve.get_point_pos(i)+curve.get_point_pos(i+1))+0.375*(curve.get_point_out(i)+curve.get_point_in(i+1)))
			button_rect = Rect2(int_coord(p_mid), add_tex.get_size())
			canvas.draw_texture_rect(add_tex, button_rect, false)
			buttons.append({ rect = button_rect, type = BUTTON_ADD, index = i })

func forward_canvas_input_event(canvas_xform, event):
	var curve = edited_object.get_curve()
	if event.type == InputEvent.MOUSE_BUTTON:
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				for b in buttons:
					if b.rect.has_point(event.pos):
						if b.type == BUTTON_ADD:
							# Clicked on an "add" button
							var p_0 = curve.get_point_pos(b.index)
							var p_3 = curve.get_point_pos(b.index+1)
							var p_1 = p_0 + curve.get_point_out(b.index)
							var p_2 = p_3 + curve.get_point_in(b.index+1)
							var p_1_2 = 0.5*(p_1+p_2)
							var p_01_12 = 0.5*p_1_2 + 0.25*(p_0 + p_1)
							var p_12_23 = 0.5*p_1_2 + 0.25*(p_2 + p_3)
							var p_new = 0.5*(p_01_12 + p_12_23)
							curve.add_point(p_new, p_01_12 - p_new, p_12_23 - p_new, b.index+1)
							curve.set_point_out(b.index, 0.5 * curve.get_point_out(b.index))
							curve.set_point_in(b.index+2, 0.5 * curve.get_point_in(b.index+2))
						elif b.type == BUTTON_REMOVE:
							# Clicked on a "remove" button
							curve.remove_point(b.index)
							if closed && b.index == 0:
								curve.set_point_pos(curve.get_point_count() - 1, curve.get_point_pos(0))
								curve.set_point_in(curve.get_point_count() - 1, curve.get_point_in(0))
						update()
						edited_object.update()
						return true
				for h in handles:
					if (event.pos - h.pos).length() < 6:
						# Activate handle
						handle_mode = h.mode
						handle_index = h.index
						return true
			elif handle_mode != HANDLE_NONE:
				handle_mode = HANDLE_NONE
				edited_object.update_collision_polygon()
				return true
	elif event.type == InputEvent.MOUSE_MOTION && handle_mode != HANDLE_NONE:
		var curve = edited_object.get_curve()
		var transform_inv = edited_object.get_global_transform().affine_inverse()
		var viewport_transform_inv = edited_object.get_viewport().get_global_canvas_transform().affine_inverse()
		var p = transform_inv.xform(viewport_transform_inv.xform(event.pos))
		if handle_mode == HANDLE_POS:
			curve.set_point_pos(handle_index, p)
			if closed && handle_index == 0:
				curve.set_point_pos(curve.get_point_count() - 1, p)
		elif handle_mode == HANDLE_IN:
			if closed && handle_index == 0:
				var i = curve.get_point_count() - 1
				curve.set_point_in(i, p-curve.get_point_pos(i))
			else:
				curve.set_point_in(handle_index, p-curve.get_point_pos(handle_index))
		elif handle_mode == HANDLE_OUT:
			curve.set_point_out(handle_index, p-curve.get_point_pos(handle_index))
		update()
		edited_object.update()
		return true
	update()
	return false

# Godot 2.1
func forward_input_event(event):
	if editor == null:
		return false
	return forward_canvas_input_event(editor.get_viewport().get_global_canvas_transform(), event)
