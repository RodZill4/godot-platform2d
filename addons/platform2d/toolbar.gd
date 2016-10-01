tool
extends HBoxContainer

var plugin = null
var object = null
var object_type

var materials = {
	thin_platform= {},
	thick_platform= {}
}

const thin_platform_script = preload("res://addons/platform2d/thin_platform.gd")
const thick_platform_script = preload("res://addons/platform2d/thick_platform.gd")

func _ready():
	if object.get_script() == thin_platform_script:
		object_type = "thin_platform"
	else:
		object_type = "thick_platform"
	var file = File.new()
	if file.open("res://addons/platform2d/materials.json", File.READ) == 0:
		materials.parse_json(file.get_line())
		file.close()
	update_material_list()

func save_materials():
	var file = File.new()
	if file.open("res://addons/platform2d/materials.json", File.WRITE) == 0:
		file.store_line(materials.to_json())
		file.close()

func update_material_list():
	var select = get_node("SelectMaterial")
	select.clear()
	select.add_item("<Materials>")
	for n in materials[object_type].keys():
		select.add_item(n)

func SelectMaterial(ID):
	var select = get_node("SelectMaterial")
	if ID > 0:
		object.set_material(materials[object_type][select.get_item_text(ID)])

func save_material(text, confirm = false):
	if text != "" && (confirm || !materials[object_type].has(text)):
		materials[object_type][text] = object.get_material()
		update_material_list()
		save_materials()
		return true
	return false

func _on_SaveMaterial_pressed():
	var dialog = preload("res://addons/platform2d/material_dialog.tscn").instance()
	dialog.toolbar = self
	plugin.get_base_control().add_child(dialog)
	dialog.popup_centered()
