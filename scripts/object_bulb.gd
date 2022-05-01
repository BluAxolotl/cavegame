extends KinematicBody2D

const UP = Vector2(0, -1)
const max_speed = 500
const accel = 100
const weight = 25
const max_fall = 1000
const friction = 120.0
const jump_force = 700
const dash_speed = 1300
const dash_time = 0.30

var motion = Vector2(0,0)
var spr_dir = 1
var joy_dir = 1
var dash_dir = 1
var last_pressed = ""
var moving = false
var free = false
var free_timer = 0
var ground_timer = 0
var dash_accel = 0
var dashing = false
var dash_jumping = false
var jump_start = false
var crouching = false
var cant_move = false
var cant_move_val = 0
var old_cant_move = 0
var jump_count = 0
var cant_input = false
var cant_input_val = 0
var old_cant_input = 0

func _ready():
	GlobalVars.current_camera = $Camera

func _physics_process(delta):
	if not dashing and free:
		if motion.y < max_fall:
			motion.y += weight
		else:
			motion.y = max_fall
	elif not free and ground_timer <= 1:
		motion.y = 5
	
	if is_on_ceiling():
		motion.y = 1
	
	if is_on_wall():
		motion.x = -2*spr_dir
	
	if Input.is_action_just_pressed("L") and not cant_input:
		last_pressed = "L"
	if Input.is_action_just_pressed("R") and not cant_input:
		last_pressed = "R"
	
	if Input.is_action_pressed("L") and not cant_input:
		joy_dir = -1
	if Input.is_action_pressed("R") and not cant_input:
		if last_pressed == "L" and Input.is_action_pressed("L") and not cant_input:
			joy_dir = -1
		else:
			joy_dir = 1
	if not Input.is_action_pressed("L") and not Input.is_action_pressed("R"):
		joy_dir = 0
	
	if joy_dir != 0 and not cant_move:
		moving = true
		if not free:
			spr_dir = joy_dir
		motion.x += accel*joy_dir
	else:
		moving = false
		if is_zero_approx(motion.x):
			motion.x = 0
			dash_jumping = false
		elif not dash_jumping:
			motion.x /= (friction/100.0)
	
	if Input.is_action_just_pressed("A") and jump_count < 2 and not cant_input:
		if not dashing:
			jump_start = true
			cant_move_val += 1
			yield(get_tree().create_timer(0.1), "timeout")
			jump_count += 1
			motion.y = -jump_force
			jump_start = false
		else: # Dash Jumping
			jump_count += 1
			dashing = false
			dash_jumping = true
			cant_move_val += 1
			motion.y = -jump_force
			jump_start = false
	
	if Input.is_action_pressed("D") and not free and not cant_input:
		crouching = true
		cant_move_val += 1
	else:
		crouching = false
	
	if Input.is_action_just_pressed("DASH") and not cant_input:
		if not dashing:
			if joy_dir != 0:
				dash_dir = joy_dir
			else:
				dash_dir = spr_dir
			dashing = true
			dash_accel = dash_speed
			yield(get_tree().create_timer(dash_time), "timeout")
			dashing = false
	
	if not dashing and not dash_jumping:
		motion.x = clamp(motion.x, -max_speed, max_speed)
	elif dashing:
		motion.x = dash_accel*dash_dir
		dash_accel /= 1.03
		motion.y = 0
	elif dash_jumping:
		cant_move_val += 1
		motion.x /= (friction/117.0)
		motion.x += joy_dir*20
	
	move_and_slide( motion, UP, false )
	
	if cant_move_val != old_cant_move:
		cant_move = true
	else:
		cant_move = false
		
	old_cant_move = cant_move_val

func _process(delta):
	$Camera.limit_top = -GlobalVars.camera_limits[0]
	$Camera.limit_bottom = GlobalVars.camera_limits[1]
	$Camera.limit_left = -GlobalVars.camera_limits[2]
	$Camera.limit_right = GlobalVars.camera_limits[3]
	if $Camera.current:
		var cv = $Camera.get_camera_screen_center()-Vector2((1280/2)*$Camera.zoom.x,(720/2)*$Camera.zoom.y)
		for i in GlobalVars.hud_elements:
			if ClassDB.get_parent_class(i.get_class()) == "Control":
				i.rect_position = cv
				i.rect_scale = $Camera.zoom
				i.rect_rotation = $Camera.rotation_degrees
			else:
				i.position = cv
				i.scale = $Camera.zoom
				i.rotation_degrees = $Camera.rotation_degrees
	
	if cant_input_val != old_cant_input:
		cant_input = true
	else:
		cant_input = false
		
	old_cant_input = cant_input_val
	
	if not is_on_floor():
		free = true
		ground_timer = 0
		free_timer += 1
	else:
		dash_jumping = false
		jump_count = 0
		free_timer = 0
		ground_timer += 1
		free = false
	
	if not dashing:
		$Sprite.scale.x = spr_dir
	else:
		$Sprite.scale.x = dash_dir
		spr_dir = dash_dir
	
	if not dashing:
		if not free:
			if jump_start or crouching:
				$AnimationPlayer.play("crouch")
			elif moving:
				$AnimationPlayer.play("run")
			else:
				$AnimationPlayer.play("idle")
		else:
			if motion.y < 1:
				$AnimationPlayer.play("jump")
			else:
				$AnimationPlayer.play("fall")
	else:
		$AnimationPlayer.play("dash")
