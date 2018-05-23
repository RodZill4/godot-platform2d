tool
extends HBoxContainer

var plugin = null

const MENU_CREATE_NEW  = 100
const MENU_LOAD        = 101
const MENU_SAVE        = 102
const MENU_CLEAR       = 103
const MENU_MAKE_UNIQUE = 104

func _ready():
	var menu = $MenuButton.get_popup()
	menu.clear()
	menu.add_item("Create New", MENU_CREATE_NEW)
	menu.add_item("Load", MENU_LOAD)
	menu.add_item("Save", MENU_SAVE)
	menu.add_item("Clear", MENU_CLEAR)
	menu.add_item("Make unique", MENU_MAKE_UNIQUE)
	menu.connect("id_pressed", self, "on_menu")

func on_menu(id):
	var object = plugin.edited_object
	print("Menu "+str(id)+" selected")
	if id == MENU_CREATE_NEW:
		object.new_style()
	elif id == MENU_LOAD:
		var dialog = EditorFileDialog.new()
		add_child(dialog)
		dialog.mode = EditorFileDialog.MODE_OPEN_FILE
		dialog.set_size(Vector2(600, 400))
		dialog.add_filter("*.tres")
		dialog.connect("file_selected", self, "load_style")
		dialog.popup_centered()
	elif id == MENU_CLEAR:
		object.Style = null
	if object.Style != null:
		if id == MENU_MAKE_UNIQUE:
			object.Style = object.Style.duplicate()
		elif id == MENU_SAVE:
			var dialog = EditorFileDialog.new()
			add_child(dialog)
			dialog.mode = EditorFileDialog.MODE_SAVE_FILE
			dialog.set_size(Vector2(600, 400))
			dialog.add_filter("*.tres")
			dialog.connect("file_selected", self, "save_style")
			dialog.popup_centered()

func load_style(f):
	print("Loading style from "+str(f))
	var style = load(f)
	if style != null:
		plugin.edited_object.Style = style

func save_style(f):
	print("Saving style to "+str(f))
	ResourceSaver.save(f, plugin.edited_object.Style)

