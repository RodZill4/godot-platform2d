tool
extends WindowDialog

var toolbar
var confirm = false

onready var line_edit     = get_node("VBoxContainer/LineEdit")
onready var confirm_text  = get_node("VBoxContainer/Label2")
onready var ok_button     = get_node("VBoxContainer/HBoxContainer/OK")
onready var cancel_button = get_node("VBoxContainer/HBoxContainer/Cancel")

func _ready():
	pass

func save(name):
	if toolbar.save_material(name, confirm):
		queue_free()
	else:
		confirm_text.set_opacity(1)
		confirm = true

func _on_LineEdit_text_changed(text):
	confirm_text.set_opacity(0)
	confirm = false
	ok_button.set_disabled(text == "")

func _on_LineEdit_text_entered(text):
	if text != "":
		save(text)

func _on_OK_pressed():
	save(line_edit.get_text())

func _on_Cancel_pressed():
	queue_free()




