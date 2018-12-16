extends KinematicBody2D

export(float) var max_speed      = 800
export(float) var gravity        = 1500
export(float) var max_fall_speed = 2000
export(float) var jump_height    = 700
export(int)   var max_air_jumps  = 1
export(float) var push_strength  = 50

var state = STATE_IDLE
var motion = Vector2(0, 0)
var previous_up = false
var air_jumps = 0
var teleport_destination
var previous_pushed_object = null

onready var respawn_position

const STATE_IDLE       = 0
const STATE_RUN        = 1
const STATE_JUMP       = 2
const STATE_FALL       = 3
const STATE_WALL_SLIDE = 4
const STATE_PUSH       = 5
const STATE_DEAD       = 6

const STATE_ANIM       = [ "idle", "run", "jump", "fall", "wall_slide", "push", "die" ]
const STATE_ANIM_SPEED = [ 1,      4,     4,      1,      1,            1,      1     ]

func _ready():
	respawn_position = position

func _physics_process(delta):
	var up = Input.is_action_pressed("ui_up")
	var jump = up && !previous_up
	previous_up = up
	var previous_state = state
	var reset_anim = false
	var target_motion_x = 0
	var wall = 0
	var pushed_object = null
	var push_vector
	if previous_state == STATE_DEAD:
		motion.x = lerp(motion.x, 0, 10*delta)
		motion.y = min(motion.y + delta * gravity, max_fall_speed)
	else:
		if Input.is_action_pressed("ui_left"):
			target_motion_x -= max_speed
			pushed_object = get_pushed_object($LeftRay)
			push_vector = Vector2(-push_strength, -20)
		if Input.is_action_pressed("ui_right"):
			target_motion_x += max_speed
			pushed_object = get_pushed_object($RightRay)
			push_vector = Vector2(push_strength, -20)
		if previous_state != STATE_JUMP && (previous_state == STATE_IDLE || previous_state == STATE_RUN || previous_state == STATE_PUSH || is_on_floor()):
			if is_on_floor() || test_move(transform, Vector2(0, 10)):
				motion.x = lerp(motion.x, target_motion_x, 10*delta)
				if jump:
					motion.y = -jump_height
					state = STATE_JUMP
					air_jumps = 0
					pushed_object = null
				else:
					motion.y = 1
					if abs(motion.x) > 10:
						state = STATE_RUN
					else:
						state = STATE_IDLE
					var collision = move_and_collide(Vector2(0, 10))
					if collision != null:
						var angle = Vector2(0, -1).angle_to(collision.normal)
						motion = motion.rotated(angle)
						if push_vector != null:
							push_vector = push_vector.rotated(angle)
					if pushed_object != null:
						pushed_object.push(push_vector, delta)
						state = STATE_PUSH
			else:
				state = STATE_FALL
				motion.y = min(motion.y + delta * gravity, max_fall_speed)
		else:
			motion.x = lerp(motion.x, target_motion_x, delta)
			motion.y = min(motion.y + delta * gravity, max_fall_speed)
			if $LeftRay.is_colliding():
				wall = -1
			elif $RightRay.is_colliding():
				wall = 1
			if wall != 0:
				if jump:
					motion.x = -jump_height * wall
					motion.y = -jump_height
					state = STATE_JUMP
					reset_anim = true
					air_jumps = 0
				else:
					state = STATE_WALL_SLIDE
					if motion.y > 50:
						motion.y = lerp(motion.y, 50, 10*delta)
			else:
				if jump && air_jumps < max_air_jumps:
					motion.y = -jump_height
					state = STATE_JUMP
					air_jumps += 1
					reset_anim = true
				elif previous_state != STATE_JUMP || motion.y > 0:
					state = STATE_FALL
		if wall != 0:
			$Gfx.scale.x = wall*abs($Gfx.scale.x)
		elif abs(motion.x) > 10:
			$Gfx.scale.x = sign(motion.x)*abs($Gfx.scale.x)
	motion = move_and_slide(motion, Vector2(0, -1))
	if state != previous_state || reset_anim:
		print("state: "+str(state))
		$AnimationPlayer.play(STATE_ANIM[state], -1, STATE_ANIM_SPEED[state])
	if previous_pushed_object != pushed_object:
		if previous_pushed_object != null:
			previous_pushed_object.push(Vector2(0, 0), 0)
		previous_pushed_object = pushed_object
		print("Pushing "+str(pushed_object))
	#update()

func get_pushed_object(ray):
	if ray.is_colliding():
		var object = ray.get_collider()
		if object != null && object.has_method("push"):
			return object
	return null

func jump(s):
	motion = s
	set_state(STATE_JUMP)

func set_state(s):
	state = s
	$AnimationPlayer.play(STATE_ANIM[state], -1, STATE_ANIM_SPEED[state])

func set_respawn(p):
	respawn_position = p

func kill(angle):
	set_state(STATE_DEAD)
	$BloodParticles.rotation = angle - 0.5*PI
	$BloodParticles.emitting = true

func teleport(destination):
	teleport_destination = destination
	$TeleportAnimation.play("teleport")

func do_teleport():
	position = teleport_destination
	set_state(STATE_IDLE)

func respawn():
	teleport(respawn_position)

