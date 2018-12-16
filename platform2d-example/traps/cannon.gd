tool
extends Node2D

export(bool)          var flip = false setget set_flip
export(float,0.0,1.0) var angle = 0 setget set_angle

func _ready():
	$cannon.rotation = angle
	update_launcher()

func set_flip(f):
	flip = f
	scale = Vector2(abs(scale.x) * (-1 if f else 1), scale.y)
	update_launcher()

func set_angle(a):
	angle = a
	if $cannon != null:
		$cannon.rotation = a
	update_launcher()

func update_launcher():
	if $cannon/Launcher != null:
		$cannon/Launcher.world = get_parent()
		$cannon/Launcher.update_path()

func fire():
	$cannon/Launcher.fire()

func old_fire():
	var shell = preload("res://platform2d-example/traps/shell.tscn").instance()
	shell.position = $cannon/Position2D.get_relative_transform_to_parent(get_parent()).origin
	shell.rotation = -($cannon.rotation)
	if !flip:
		shell.rotation = PI - shell.rotation
	get_parent().add_child(shell)
	
func _on_Timer_timeout():
	fire()