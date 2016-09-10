tool
extends HBoxContainer

var materials = {
	smart_curve= {},
	smart_surface= {}
}
var object = null
var object_type

const smart_curve_script = preload("res://addons/smart_textures/smart_curve.gd")
const smart_surface_script = preload("res://addons/smart_textures/smart_surface.gd")

func _ready():
	if object.get_script() == smart_curve_script:
		object_type = "smart_curve"
	else:
		object_type = "smart_surface"
	var file = File.new()
	if file.open("res://addons/smart_textures/materials.json", File.READ) == 0:
		materials.parse_json(file.get_line())
		file.close()
	update_material_list()

func save_materials():
	var file = File.new()
	if file.open("res://addons/smart_textures/materials.json", File.WRITE) == 0:
		file.store_line(materials.to_json())
		file.close()

func update_material_list():
	var select = get_node("Select")
	select.clear()
	select.add_item("<Materials>")
	for n in materials[object_type].keys():
		select.add_item(n)

func _on_Select_item_selected(ID):
	var select = get_node("Select")
	if ID > 0:
		object.set_material(materials[object_type][select.get_item_text(ID)])

func _on_Name_text_entered(text):
	if text != "":
		materials[object_type][text] = object.get_material()
		update_material_list()
		save_materials()
