extends StaticBody2D

export(bool) var MovingPlatform = false setget set_moving_platform
var last_position = null

func _ready():
	if MovingPlatform:
		set_fixed_process(true)
		last_position = get_global_pos()

func set_moving_platform(b):
	MovingPlatform = b
	set_fixed_process(MovingPlatform)
	last_position = get_global_pos()

func _fixed_process(delta):
	var position = get_global_pos()
	set_constant_linear_velocity((position - last_position) / delta)
	last_position = position