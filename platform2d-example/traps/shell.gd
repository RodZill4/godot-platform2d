extends Area2D

func _ready():
	$shell.flip_v = abs(fposmod(rotation, 2*PI)-PI) < 0.5*PI

func _on_Shell_body_entered(body):
	shape_owner_set_disabled(0, true)
	if body.has_method("kill"):
		body.kill(rotation)
	$shell.hide()
	$Tween.stop_all()
	rotation = 0
	$Blast.emitting = true
	$FreeTimer.start()