extends RigidBody2D

var push_force = Vector2(0, 0)

func push(v, delta):
	var force = v
	add_force(Vector2(0, 0), -push_force)
	add_force(Vector2(0, 0), force)
	push_force = force
	friction = 1 if (force.length() == 0.0) else 0
