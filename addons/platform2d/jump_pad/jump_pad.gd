tool
extends Area2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	call_deferred("create_target")

func create_target():
	if !has_node("Target"):
		var target = Position2D.new()
		target.position = Vector2(0, -100)
		target.name = "Target"
		add_child(target)
		target.set_owner(get_owner())
		print(get_owner())

func _on_JumpPad_body_entered(body):
	if body.has_method("jump"):
		body.jump(5*$Target.position)
