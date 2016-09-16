tool
extends EditorPlugin

var edited_object = null
var editor        = null
var toolbar       = null

const thin_platform_script = preload("res://addons/platform2d/thin_platform.gd")
const thick_platform_script = preload("res://addons/platform2d/thick_platform.gd")
const curve_editor_script = preload("res://addons/platform2d/curve_editor.gd")

func _enter_tree():
	add_custom_type("ThinPlatform",  "StaticBody2D", thin_platform_script,  preload("res://addons/platform2d/thin_platform_icon.png"))
	add_custom_type("ThickPlatform", "StaticBody2D", thick_platform_script, preload("res://addons/platform2d/thick_platform_icon.png"))

func _exit_tree():
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
		if editor == null:
			var viewport = edited_object.get_viewport()
			editor = curve_editor_script.new()
			editor.object = edited_object
			editor.closed = (edited_object.get_script() == thick_platform_script)
			viewport.add_child(editor)
			viewport.connect("size_changed", editor, "update")
		if toolbar == null:
			toolbar = preload("res://addons/platform2d/toolbar.tscn").instance()
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