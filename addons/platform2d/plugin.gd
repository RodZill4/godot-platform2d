tool
extends EditorPlugin

var edited_object = null
var toolbar       = null
var closed        = false

var handles       = []
var handle_mode
var handle_index
var handle_pos
var buttons       = []

const thin_platform_script = preload("res://addons/platform2d/thin_platform.gd")
const thick_platform_script = preload("res://addons/platform2d/thick_platform.gd")

const handle_tex = preload("res://addons/platform2d/handle.png")
const add_tex = preload("res://addons/platform2d/add.png")
const remove_tex = preload("res://addons/platform2d/remove.png")

const EDIT_NONE                = 0
const EDIT_PLATFORM            = 1

const HANDLE_NONE     = 0
const HANDLE_POS      = 1
const HANDLE_IN       = 2
const HANDLE_OUT      = 3
const BUTTON_ADD      = 4
const BUTTON_REMOVE   = 5

const COLOR_1 = Color(1, 1, 1, 1)
const COLOR_2 = Color(0.5, 0.5, 1, 1)
const COLOR_3 = Color(1, 0, 0, 1)

func _enter_tree():
	add_custom_type("ThinPlatform",  "StaticBody2D", thin_platform_script,  preload("res://addons/platform2d/thin_platform_icon.png"))
	add_custom_type("ThickPlatform", "StaticBody2D", thick_platform_script, preload("res://addons/platform2d/thick_platform_icon.png"))
	handle_tex.set_flags(0)
	add_tex.set_flags(0)
	remove_tex.set_flags(0)

func _exit_tree():
	make_visible(false)
	remove_custom_type("SmartCurve")
	remove_custom_type("SmartSurface")

func _get_state():
	#print("get_state")
	var s = {}
	s.edited_object = edited_object
	s.toolbar =       toolbar
	s.closed =        closed
	s.handles =       handles
	s.handle_mode =   handle_mode
	s.handle_index =  handle_index
	s.handle_pos =    handle_pos
	s.buttons =       buttons
	return s

func _set_state(s):
	print("set_state")
	edited_object = s.edited_object
	toolbar       = s.toolbar
	closed        = s.closed
	handles       = s.handles
	handle_mode   = s.handle_mode
	handle_index  = s.handle_index
	handle_pos    = s.handle_pos
	buttons       = s.buttons

func handles(o):
	if o.get_script() == thick_platform_script || o.get_script() == thin_platform_script:
		return true
	else:
		return false

func edit(o):
	print("Editing "+str(o))
	edited_object = o
	closed = (edited_object.get_script() == thick_platform_script)

func make_visible(b):
	if b:
		update()
		if toolbar == null:
			toolbar = preload("res://addons/platform2d/toolbar.tscn").instance()
			toolbar.plugin = self
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	else:
		if toolbar != null:
			toolbar.queue_free()
			toolbar = null
		edited_object = null

func update():
	update_overlays()

func int_coord(p):
	return Vector2(round(p.x), round(p.y))

func forward_canvas_draw_over_viewport(canvas):
	forward_draw_over_viewport(canvas)

func forward_draw_over_viewport(canvas):
	if !edited_object.is_inside_tree(): print("foo")
	var transform = edited_object.get_viewport_transform() * edited_object.get_global_transform()
	buttons = []
	handles = []
	var curve = edited_object.get_curve()
	var point_count = curve.get_point_count()
	var notclosed_int = 1
	if closed:
		notclosed_int = 0
		point_count = point_count - 1
	for i in range(point_count):
		var p
		var p_in
		var p_out
		var button_rect
		p = transform.xform(curve.get_point_position(i))
		if i == 0 && closed:
			p_in = p+transform.basis_xform(curve.get_point_in(point_count))
		else:
			p_in = p+transform.basis_xform(curve.get_point_in(i))
		p_out = p+transform.basis_xform(curve.get_point_out(i))
		if i > 0 || closed:
			canvas.draw_line(p, p_in, COLOR_2)
			canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p_in)-Vector2(5, 5), Vector2(11, 11)), false)
			handles.append({ position = p_in, mode = HANDLE_IN, index = i })
		if i < point_count - notclosed_int:
			canvas.draw_line(p, p_out, COLOR_2)
			canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p_out)-Vector2(5, 5), Vector2(11, 11)), false)
			handles.append({ position = p_out, mode = HANDLE_OUT, index = i })
		canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p)-Vector2(5, 5), Vector2(11, 11)), false)
		handles.append({ position = p, mode = HANDLE_POS, index = i })
		if curve.get_point_count() + notclosed_int >= 4:
			# minimum number of points is 3 for closed curves and 2 for others
			button_rect = Rect2(int_coord(p)+Vector2(5, 5), remove_tex.get_size())
			canvas.draw_texture_rect(remove_tex, button_rect, false)
			buttons.append({ rect = button_rect, type = BUTTON_REMOVE, index = i })
		if i < curve.get_point_count() - notclosed_int:
			var p_mid = transform.xform(0.5*(curve.get_point_position(i)+curve.get_point_position(i+1))+0.375*(curve.get_point_out(i)+curve.get_point_in(i+1)))
			button_rect = Rect2(int_coord(p_mid), add_tex.get_size())
			canvas.draw_texture_rect(add_tex, button_rect, false)
			buttons.append({ rect = button_rect, type = BUTTON_ADD, index = i })

func forward_canvas_gui_input(event):
	var curve = null
	curve = edited_object.get_curve()
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				for b in buttons:
					if b.rect.has_point(event.position):
						if b.type == BUTTON_ADD:
							# Clicked on an "add" button
							var p_0 = curve.get_point_position(b.index)
							var p_3 = curve.get_point_position(b.index+1)
							var p_1 = p_0 + curve.get_point_out(b.index)
							var p_2 = p_3 + curve.get_point_in(b.index+1)
							var p_1_2 = 0.5*(p_1+p_2)
							var p_01_12 = 0.5*p_1_2 + 0.25*(p_0 + p_1)
							var p_12_23 = 0.5*p_1_2 + 0.25*(p_2 + p_3)
							var p_new = 0.5*(p_01_12 + p_12_23)
							var undoredo = get_undo_redo()
							undoredo.create_action("Add platform control point")
							undoredo.add_do_method(curve, "add_point", p_new, p_01_12 - p_new, p_12_23 - p_new, b.index+1)
							undoredo.add_do_method(curve, "set_point_out", b.index, 0.5 * curve.get_point_out(b.index))
							undoredo.add_do_method(curve, "set_point_in", b.index+2, 0.5 * curve.get_point_in(b.index+2))
							undoredo.add_undo_method(curve, "remove_point", b.index+1)
							undoredo.add_undo_method(curve, "set_point_out", b.index, curve.get_point_out(b.index))
							undoredo.add_undo_method(curve, "set_point_in", b.index+1, curve.get_point_in(b.index+1))
							undoredo.add_do_method(edited_object, "update_collision_polygon")
							undoredo.add_undo_method(edited_object, "update_collision_polygon")
							undoredo.commit_action()
						elif b.type == BUTTON_REMOVE:
							# Clicked on a "remove" button
							var undoredo = get_undo_redo()
							undoredo.create_action("Remove platform control point")
							undoredo.add_do_method(curve, "remove_point", b.index)
							undoredo.add_undo_method(curve, "add_point", curve.get_point_position(b.index), curve.get_point_in(b.index), curve.get_point_out(b.index), b.index)
							if closed && b.index == 0:
								var i = curve.get_point_count() - 1
								undoredo.add_do_method(curve, "set_point_pos", i-1, curve.get_point_position(1))
								undoredo.add_do_method(curve, "set_point_in", i-1, curve.get_point_in(1))
								undoredo.add_undo_method(curve, "set_point_pos", i, curve.get_point_position(i))
								undoredo.add_undo_method(curve, "set_point_in", i, curve.get_point_in(i))
							undoredo.add_do_method(edited_object, "update_collision_polygon")
							undoredo.add_undo_method(edited_object, "update_collision_polygon")
							undoredo.commit_action()
						update()
						edited_object.update()
						return true
				for h in handles:
					if (event.position - h.position).length() < 6:
						# Activate handle
						handle_mode = h.mode
						handle_index = h.index
						# Keep initial value for undo/redo
						if handle_mode == HANDLE_POS:
							handle_pos = curve.get_point_position(handle_index)
						elif handle_mode == HANDLE_IN:
							if closed && handle_index == 0:
								var i = curve.get_point_count() - 1
								handle_pos = curve.get_point_in(i)
							else:
								handle_pos = curve.get_point_in(handle_index)
						elif handle_mode == HANDLE_OUT:
							handle_pos = curve.get_point_out(handle_index)
						return true
			elif handle_mode != HANDLE_NONE:
				var undoredo = get_undo_redo()
				undoredo.create_action("Move control point")
				var i
				if curve != null:
					i = curve.get_point_count() - 1
				if handle_mode == HANDLE_POS:
					undoredo.add_do_method(curve, "set_point_pos", handle_index, curve.get_point_position(handle_index))
					undoredo.add_undo_method(curve, "set_point_pos", handle_index, handle_pos)
					if closed && handle_index == 0:
						undoredo.add_do_method(curve, "set_point_pos", i, curve.get_point_position(i))
						undoredo.add_undo_method(curve, "set_point_pos", i, handle_pos)
				elif handle_mode == HANDLE_IN:
					if closed && handle_index == 0:
						undoredo.add_do_method(curve, "set_point_in", i, curve.get_point_in(i))
						undoredo.add_undo_method(curve, "set_point_in", i, handle_pos)
					else:
						undoredo.add_do_method(curve, "set_point_in", handle_index, curve.get_point_in(handle_index))
						undoredo.add_undo_method(curve, "set_point_in", handle_index, handle_pos)
				elif handle_mode == HANDLE_OUT:
					undoredo.add_do_method(curve, "set_point_out", handle_index, curve.get_point_out(handle_index))
					undoredo.add_undo_method(curve, "set_point_out", handle_index, handle_pos)
				if curve != null:
					undoredo.add_do_method(edited_object, "update_collision_polygon")
					undoredo.add_undo_method(edited_object, "update_collision_polygon")
				undoredo.commit_action()
				handle_mode = HANDLE_NONE
				return true
	elif event is InputEventMouseMotion && handle_mode != HANDLE_NONE:
		if !edited_object.is_inside_tree(): print("foo1")
		var transform_inv = edited_object.get_global_transform().affine_inverse()
		var viewport_transform_inv = edited_object.get_viewport().get_global_canvas_transform().affine_inverse()
		var p = transform_inv.xform(viewport_transform_inv.xform(event.position))
		if handle_mode == HANDLE_POS:
			curve.set_point_position(handle_index, p)
			if closed && handle_index == 0:
				curve.set_point_position(curve.get_point_count() - 1, p)
		elif handle_mode == HANDLE_IN:
			if closed && handle_index == 0:
				var i = curve.get_point_count() - 1
				curve.set_point_in(i, p-curve.get_point_position(i))
			else:
				curve.set_point_in(handle_index, p-curve.get_point_position(handle_index))
		elif handle_mode == HANDLE_OUT:
			curve.set_point_out(handle_index, p-curve.get_point_position(handle_index))
		update()
		edited_object.update()
		return true
	update()
	return false
