extends StaticBody2D

export(float) var strength = 10

var energy = 0

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func push(v, delta):
	if v.x != 0:
		energy += abs(v.x) * delta
		if energy > strength:
			collision_mask = 0
			collision_layer = 0
			print(v.x)
			if v.x < 0:
				$AnimationPlayer.play("fall_left")
			else:
				$AnimationPlayer.play("fall_right")
