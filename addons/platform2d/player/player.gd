extends KinematicBody2D

export(float) var max_speed      = 800
export(float) var gravity        = 1500
export(float) var max_fall_speed = 2000
export(float) var jump_height    = 700

var state = STATE_IDLE
var motion = Vector2(0, 0)
var previous_up = false
var teleport_destination

onready var respawn_point

const STATE_IDLE       = 0
const STATE_RUN        = 1
const STATE_JUMP       = 2
const STATE_FALL       = 3
const STATE_WALL_SLIDE = 4
const STATE_DEAD       = 5

const STATE_ANIM       = [ "idle", "run", "jump", "fall", "wall_slide", "die" ]
const STATE_ANIM_SPEED = [ 1,      4,     4,      1,      1,            1     ]

func _ready():
	respawn_point = position

func _physics_process(delta):
	var up = Input.is_action_pressed("ui_up")
	var jump = up && !previous_up
	previous_up = up
	var previous_state = state
	var reset_anim = false
	var target_motion_x = 0
	var wall = 0
	if previous_state == STATE_DEAD:
		motion.x = lerp(motion.x, 0, 10*delta)
		motion.y = min(motion.y + delta * gravity, max_fall_speed)
	else:
		if Input.is_action_pressed("ui_left"):
			target_motion_x -= max_speed
		if Input.is_action_pressed("ui_right"):
			target_motion_x += max_speed
		if is_on_floor() || previous_state == STATE_IDLE || previous_state == STATE_RUN:
			if $GroundRay.is_colliding():
				motion.x = lerp(motion.x, target_motion_x, 10*delta)
				if jump:
					motion.y = -jump_height
					state = STATE_JUMP
				else:
					motion.y = 0
					if abs(motion.x) > 10:
						state = STATE_RUN
					else:
						state = STATE_IDLE
					motion = motion.rotated((Vector2(0, -1).angle_to($GroundRay.get_collision_normal())))
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
				else:
					state = STATE_WALL_SLIDE
					if motion.y > 50:
						motion.y = lerp(motion.y, 50, 10*delta)
			elif previous_state != STATE_JUMP || motion.y > 0:
				state = STATE_FALL
		if wall != 0:
			$Gfx.scale.x = wall*abs($Gfx.scale.x)
		elif abs(motion.x) > 10:
			$Gfx.scale.x = sign(motion.x)*abs($Gfx.scale.x)
	motion = move_and_slide(motion, Vector2(0, -1))
	if state != previous_state || reset_anim:
		$AnimationPlayer.play(STATE_ANIM[state], -1, STATE_ANIM_SPEED[state])
		#$Sprite.play(STATE_ANIM[state])
		#$Sprite.frame = 0
	#update()

#func _draw():
#	draw_line(Vector2(0, 0), 10*motion, Color(1, 1, 1))

func set_state(s):
	state = s
	$AnimationPlayer.play(STATE_ANIM[state], -1, STATE_ANIM_SPEED[state])

func kill(angle):
	print(angle)
	set_state(STATE_DEAD)
	$Gfx/BloodParticles.rotation = angle - 0.5*PI
	$Gfx/BloodParticles.emitting = true

func teleport(destination):
	teleport_destination = destination
	$TeleportAnimation.play("teleport")

func do_teleport():
	position = teleport_destination
	set_state(STATE_IDLE)

func respawn():
	teleport(respawn_point)

