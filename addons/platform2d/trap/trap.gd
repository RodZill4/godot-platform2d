extends Area2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Trap_body_entered(body):
	if !$AnimationPlayer.is_playing():
		$AnimationPlayer.play("trigger")
		if body.has_method("kill"):
			body.kill(get_relative_transform_to_parent(body.get_parent()).get_rotation())
