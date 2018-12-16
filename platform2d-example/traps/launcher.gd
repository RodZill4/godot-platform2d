tool
extends Position2D

export(String) var projectile = "" setget set_projectile
export(float) var iterations = 20 setget set_iterations
export(float) var timestep = 0.2
export(float) var initial_speed = 2000 setget set_initial_speed
export(float) var friction = 5 setget set_friction
export(float) var gravity = 40 setget set_gravity
export(bool) var rotate_projectile = false

var projectile_scene = null
var world = null
var path = null
var rotation_list = null

func _ready():
	pass

func set_projectile(p):
	projectile = p
	projectile_scene = load(projectile)
	
func set_iterations(i):
	iterations = i
	update_path()

func set_initial_speed(s):
	initial_speed = s
	update_path()

func set_friction(f):
	friction = f
	update_path()

func set_gravity(g):
	gravity = g
	update_path()

func update_path():
	if world == null:
		path = null
		return
	var world_transform = get_relative_transform_to_parent(world)
	var world_transform_inv = world_transform.affine_inverse()
	print(world_transform.get_scale())
	var p = world_transform.get_origin()
	var speed = Vector2(initial_speed, 0).rotated(PI-world_transform_inv.get_rotation())
	path = PoolVector2Array([p])
	var angle = speed.angle()
	if rotate_projectile:
		rotation_list = PoolRealArray([angle])
	else:
		rotation_list = null
	for i in range(0, iterations):
		p = p + speed
		speed *= 1.0-(friction*0.01)
		speed += Vector2(0, gravity)
		path.append(p)
		if rotate_projectile:
			var next_angle = speed.angle()
			var next_angle_alt = next_angle + 2*PI*sign(angle - next_angle)
			angle = next_angle_alt if (abs(angle - next_angle) > abs(angle - next_angle_alt)) else next_angle
			rotation_list.append(angle)
	update()

func fire():
	if projectile_scene == null || world == null || path == null:
		return
	var projectile = projectile_scene.instance()
	var tween
	if projectile.has_node("Tween"):
		tween = projectile.get_node("Tween")
	else:
		tween = Tween.new()
		projectile.add_child(tween)
	for i in range(iterations):
		tween.interpolate_property(projectile, "position", path[i], path[i+1], timestep, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN, i*timestep)
		if rotation_list != null:
			tween.interpolate_property(projectile, "rotation", rotation_list[i], rotation_list[i+1], timestep, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN, i*timestep)
	projectile.position = path[0]
	if rotation_list != null:
		projectile.rotation = rotation_list[0]
	world.add_child(projectile)
	tween.start()

func _draw():
	if !Engine.editor_hint || world == null || path == null:
		return
	var transformed_path = PoolVector2Array()
	var world_transform = get_relative_transform_to_parent(world)
	for i in range(iterations):
		transformed_path.append(world_transform.xform_inv(path[i]))
	draw_polyline(transformed_path, Color(1, 1, 1), 2, true)
