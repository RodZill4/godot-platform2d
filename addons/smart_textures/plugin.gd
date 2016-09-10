tool
extends EditorPlugin

var edited_object = null
var editor        = null
var toolbar       = null

const smart_curve_script = preload("res://addons/smart_textures/smart_curve.gd")
const smart_surface_script = preload("res://addons/smart_textures/smart_surface.gd")
const curve_editor_script = preload("res://addons/smart_textures/curve_editor.gd")

func _enter_tree():
	add_custom_type("SmartCurve",   "StaticBody2D", smart_curve_script,   preload("res://addons/smart_textures/smart_curve_icon.png"))
	add_custom_type("SmartSurface", "StaticBody2D", smart_surface_script, preload("res://addons/smart_textures/smart_surface_icon.png"))

func _exit_tree():
	remove_custom_type("SmartCurve")
	remove_custom_type("SmartSurface")

func handles(o):
	if o.get_script() == smart_surface_script || o.get_script() == smart_curve_script:
		return true
	else:
		return false

func edit(o):
	edited_object = o

func make_visible(b):
	if b:
		if editor == null:
			var viewport = edited_object.get_viewport()
			editor = curve_editor_script.new()
			editor.object = edited_object
			editor.closed = (edited_object.get_script() == smart_surface_script)
			viewport.add_child(editor)
			viewport.connect("size_changed", editor, "update")
		if toolbar == null:
			toolbar = preload("res://addons/smart_textures/toolbar.tscn").instance()
			toolbar.object = edited_object
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	else:
		if editor != null:
			editor.queue_free()
			editor = null
		if toolbar != null:
			toolbar.queue_free()
			toolbar = null

func forward_input_event(e):
	if editor == null:
		return false
	return editor.process_input_event(e)