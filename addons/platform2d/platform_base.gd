tool
extends StaticBody2D

export(bool)             var MovingPlatform = false setget set_moving_platform
export(Curve2D)          var Curve = null setget set_curve
export(float)            var BakeInterval = 50 setget set_bake_interval
export(Resource)         var Style = null setget set_style
export(Resource)         var Style2 = null setget set_style2
export(int)              var Layer2Z = 0 setget set_layer2_z
export(Array)            var Objects = [] setget set_objects
export(float, 1, 250, 1) var ObjectsDistance = 50 setget set_objects_distance

var last_position

const thin_style_script = preload("res://addons/platform2d/thin_platform_style.gd")
const LAYER_NODE_NAME : String = "PlatformLayer2"
const OBJECTS_NODE_NAME : String = "PlatformObjects"

func _ready():
	last_position = global_position
	set_physics_process(MovingPlatform)
	last_position = get_global_position()
	if Engine.editor_hint:
		var curve = get_curve()
		if curve == null:
			curve = get_default_curve()
		set_curve(curve.duplicate())

func get_default_curve():
	return preload("res://addons/platform2d/thin_platform_default_curve.tres")

func get_curve():
	return Curve

func set_curve(c):
	Curve = c
	Curve.connect("changed", self, "update")
	Curve.set_bake_interval(BakeInterval)
	on_curve_update()

func get_top_curves() -> Array:
	return [ get_curve() ]

func set_bake_interval(i):
	BakeInterval = i
	Curve.set_bake_interval(BakeInterval)
	on_curve_update()

func set_moving_platform(b):
	MovingPlatform = b
	set_physics_process(MovingPlatform)
	last_position = global_position

func set_style(s):
	if Style != null:
		Style.disconnect("changed", self, "on_style_changed")
	Style = s
	if Style != null:
		Style.connect("changed", self, "on_style_changed")
	update()

func set_style2(s):
	if Style2 != null:
		Style2.disconnect("changed", self, "on_style_changed")
	Style2 = s
	if Style2 != null:
		Style2.connect("changed", self, "on_style_changed")
	update()

func set_layer2_z(z):
	Layer2Z = z
	update()

func set_objects(o):
	Objects = o
	update_objects()

func set_objects_distance(d):
	ObjectsDistance = d
	update_objects()

func on_style_changed():
	update()

func on_curve_update():
	update()
	update_objects()
	update_collision_polygon()

func _physics_process(delta):
	set_constant_linear_velocity((global_position - last_position) / delta)
	last_position = global_position

static func aligned(p1, p2, p3):
	return (p2-p1).normalized().dot((p2-p3).normalized()) > 0.999

static func baked_points_and_length(curve):
	return { points = curve.tessellate(), length = curve.get_baked_length() }

static func baked_points(curve):
	return baked_points_and_length(curve).points

static func baked_length(curve):
	return baked_points_and_length(curve).length

static func draw_border(canvas_item : CanvasItem, point_array, thickness, position, sections, left_overflow = 0.0):
	var point_count = point_array.size()
	var points = PoolVector2Array()
	points.push_back(Vector2(0, 0))
	points.push_back(Vector2(0, 0))
	points.push_back(Vector2(0, 0))
	points.push_back(Vector2(0, 0))
	var colors = PoolColorArray()
	colors.push_back(Color(1.0, 1.0, 1.0))
	colors.push_back(Color(1.0, 1.0, 1.0))
	colors.push_back(Color(1.0, 1.0, 1.0))
	colors.push_back(Color(1.0, 1.0, 1.0))
	var uvs = PoolVector2Array()
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(0, 0))
	var normal = PoolVector2Array()
	for i in range(point_count):
		var i0 = i-1
		if i0 == -1:
			i0 = 0
		var i2 = i+1
		if i2 == point_count:
			i2 = point_count-1
		normal.append((point_array[i2] - point_array[i0]).rotated(PI/2).normalized() * thickness)
	var u = left_overflow
	var texture_index = 0
	var texture = sections[0].texture
	var limit   = sections[0].limit
	var scale   = sections[0].scale
	if u != 0.0:
		points[3] = point_array[0] + normal[0] * position
		points[2] = point_array[0] - normal[0] * (1-position)
		var overflow = normal[0].rotated(PI/2).normalized() * left_overflow / scale
		points[0] = points[3] + overflow
		points[1] = points[2] + overflow
		uvs[0] = Vector2(0, 1)
		uvs[1] = Vector2(0, 0)
		uvs[2] = Vector2(u, 0)
		uvs[3] = Vector2(u, 1)
		canvas_item.draw_polygon(points, colors, uvs, texture)
	for i in range(point_count-1):
		var interval = (point_array[i+1] - point_array[i]).length()
		if i == 0:
			points[0] = point_array[i] + normal[i] * position
			points[1] = point_array[i] - normal[i] * (1-position)
		else:
			points[0] = points[3]
			points[1] = points[2]
		uvs[0] = Vector2(u, 1)
		uvs[1] = Vector2(u, 0)
		var length = (point_array[i+1] - point_array[i]).length()
		var next_u = u + length * scale
		if next_u >= limit:
			var r = (limit - u) / (next_u - u)
			var p = point_array[i] + r * (point_array[i+1] - point_array[i])
			var n = (normal[i] + r * (normal[i+1] - normal[i])).normalized() * thickness
			points[2] = p - n * (1-position)
			if (points[2]-points[1]).dot(point_array[i+1] - point_array[i]) < 0:
				points[2] = points[1]
			points[3] = p + n * position
			if (points[3]-points[0]).dot(point_array[i+1] - point_array[i]) < 0:
				points[3] = points[0]
			uvs[2] = Vector2(limit, 0)
			uvs[3] = Vector2(limit, 1)
			canvas_item.draw_polygon(points, colors, uvs, texture)
			texture_index = texture_index + 1
			if texture_index >= sections.size():
				u = next_u
				break
			texture = sections[texture_index].texture
			limit   = sections[texture_index].limit
			scale   = sections[texture_index].scale
			points[0] = points[3]
			points[1] = points[2]
			uvs[0] = Vector2(0, 1)
			uvs[1] = Vector2(0, 0)
			u = length * (1 - r) * scale
			points[2] = point_array[i+1] - normal[i+1] * (1-position)
			points[3] = point_array[i+1] + normal[i+1] * position
			uvs[2] = Vector2(u, 0)
			uvs[3] = Vector2(u, 1)
			canvas_item.draw_polygon(points, colors, uvs, texture)
		else:
			points[2] = point_array[i+1] - normal[i+1] * (1-position)
			if (points[2]-points[1]).dot(point_array[i+1] - point_array[i]) < 0:
				points[2] = points[1]
			points[3] = point_array[i+1] + normal[i+1] * position
			if (points[3]-points[0]).dot(point_array[i+1] - point_array[i]) < 0:
				points[3] = points[0]
			uvs[2] = Vector2(next_u, 0)
			uvs[3] = Vector2(next_u, 1)
			canvas_item.draw_polygon(points, colors, uvs, texture)
			u = next_u
	if u < limit:
		points[0] = points[3]
		points[1] = points[2]
		var overflow = normal[point_count-2].rotated(-PI/2).normalized() * (limit - u) / scale
		points[2] = points[2] + overflow
		points[3] = points[3] + overflow
		uvs[0] = Vector2(u, 1)
		uvs[1] = Vector2(u, 0)
		uvs[2] = Vector2(limit, 0)
		uvs[3] = Vector2(limit, 1)
		canvas_item.draw_polygon(points, colors, uvs, texture)

static func draw_top(canvas_item : CanvasItem, curve, LeftTexture, MidTexture, RightTexture, LeftOverflow, RightOverflow, Thickness, Position):
	var baked_points_and_length = baked_points_and_length(curve)
	var point_array = baked_points_and_length.points
	var point_count = point_array.size()
	if point_count == 0 || MidTexture == null:
		return
	var sections = []
	var curve_length = baked_points_and_length.length
	var mid_length = MidTexture.get_width() * Thickness / MidTexture.get_height()
	if LeftTexture != null and RightTexture != null:
		var left_length = (1.0 - LeftOverflow) * LeftTexture.get_width() * Thickness / LeftTexture.get_height()
		var right_length = (1.0 - RightOverflow) * RightTexture.get_width() * Thickness / RightTexture.get_height()
		var mid_texture_count = floor(0.5 + (curve_length - left_length - right_length) / mid_length)
		var ratio_adjust = (left_length + mid_texture_count * mid_length + right_length) / curve_length
		sections.append({texture = LeftTexture, limit = 1.0, scale = ratio_adjust * LeftTexture.get_height() / (Thickness * LeftTexture.get_width())})
		if mid_texture_count > 0:
			sections.append({texture = MidTexture, limit = mid_texture_count, scale = ratio_adjust * MidTexture.get_height() / (Thickness * MidTexture.get_width())})
		sections.append({texture = RightTexture, limit = 1.0, scale = ratio_adjust * RightTexture.get_height() / (Thickness * RightTexture.get_width())})
	else:
		var mid_texture_count = curve_length / mid_length
		sections.append({texture = MidTexture, limit = mid_texture_count, scale = MidTexture.get_height() / (Thickness * MidTexture.get_width())})
	draw_border(canvas_item, point_array, Thickness, Position, sections, LeftOverflow)

# Redefined in thick_platform and thin_platform
func generate_collision_polygon():
	return null

func update_collision_polygon():
	if is_inside_tree() and Engine.editor_hint:
		var polygon = get_node("CollisionPolygon2D")
		if collision_layer == 0 and collision_mask == 0:
			if polygon != null:
				polygon.queue_free()
		else:
			if polygon == null:
				polygon = CollisionPolygon2D.new()
				polygon.set_name("CollisionPolygon2D")
				polygon.hide()
				add_child(polygon)
			polygon.set_owner(get_owner())
			polygon.set_polygon(generate_collision_polygon())

func update() -> void:
	if !is_inside_tree():
		return
	var layer2 = null
	if has_node(LAYER_NODE_NAME):
		layer2 = get_node(LAYER_NODE_NAME)
	if Style2 == null:
		if layer2 != null:
			layer2.queue_free()
	else:
		if layer2 == null:
			layer2 = Node2D.new()
			layer2.set_script(load("res://addons/platform2d/platform_layer2.gd"))
			layer2.name = LAYER_NODE_NAME
			add_child(layer2)
			layer2.set_owner(get_owner())
		layer2.z_index = Layer2Z
		layer2.update()
	.update()

func update_objects():
	if Objects == null or Objects.size() == 0:
		if has_node(OBJECTS_NODE_NAME):
			get_node(OBJECTS_NODE_NAME).queue_free()
	else:
		var objects_node
		if has_node(OBJECTS_NODE_NAME):
			objects_node = get_node(OBJECTS_NODE_NAME)
		else:
			objects_node = Node2D.new()
			objects_node.name = OBJECTS_NODE_NAME
			add_child(objects_node)
			objects_node.set_owner(get_owner())
		objects_node.transform = Transform2D()
		for c in objects_node.get_children():
			c.queue_free()
		for c in get_top_curves():
			var baked_curve = baked_points_and_length(c)
			var p = randf()*0.5*ObjectsDistance
			var count = 0
			while p < baked_curve.length:
				var s = Objects[randi()%Objects.size()]
				if s != null:
					var o = s.instance()
					objects_node.add_child(o)
					o.position = c.interpolate_baked(p)
					p += (randf()+0.5)*ObjectsDistance
					var angle = (c.interpolate_baked(p+0.1)-o.position).angle()
					o.rotation = angle
					objects_node.set_owner(get_owner())
					count += 1
					if count > 100:
						break

func _edit_get_rect():
	var curve = get_curve()
	var rect = Rect2(curve.get_point_position(0), Vector2(0, 0))
	for i in range(curve.get_point_count()):
		rect.expand(curve.get_point_position(i))
	return rect

func _edit_use_rect():
	return true

