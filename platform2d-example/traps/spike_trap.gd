extends Area2D

func _on_Trap_body_entered(body):
	if !$AnimationPlayer.is_playing():
		$AnimationPlayer.play("trigger")
		if body.has_method("kill"):
			body.kill(get_relative_transform_to_parent(body.get_parent()).get_rotation())
