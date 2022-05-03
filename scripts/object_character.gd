extends KinematicBody2D

const UP = Vector2(0, -1)
const anim_names = [
	"idle",
	"run",
	"jump",
	"fall",
	"crouch",
	"dash"
]

enum CharType { NPC, PLAYER, PARTY, OTHER_PLAYER = -1 }

export var type = CharType.NPC
export var character_name = ""
export var debug_mode = false
export var hurtbox = Vector2(50,50)
export var offset = Vector2(0,0)
export var max_speed = 500
export var accel = 100
export var weight = 25
export var max_fall = 1000
export var friction = 120.0
export var jump_force = 700
export var dash_speed = 1300
export var dash_time = 0.30

var motion = Vector2(0,0)
var anims = {}
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
var curr_dash = 0
var jump_start = false
var crouching = false
var curr_texture
var old_texture
var new_anim_timer = 0
var cant_move = false
var cant_move_val = 0
var old_cant_move = 0
var jump_count = 0
var cant_input = false
var cant_input_val = 0
var old_cant_input = 0
var readied = false
var override_input = []
var idle_timer = 0
var game_frame = 0

var prev_VirtualInputs = null
var prev_pos = null

var VirtualInputs = {
	"pressed": {
		"U": false,
		"D": false,
		"L": false,
		"R": false,
		"A": false,
		"DASH": false,
	},
	"down": {
		"U": false,
		"D": false,
		"L": false,
		"R": false,
		"A": false,
		"DASH": false,
	},
	"cant_input_val": cant_input_val,
	"idle": false
}

func _ready():
	readied = true
	GlobalVars.current_camera = $Camera
	var root_dir = "."
	var placeholder_sprite = load("%s/sprites/placeholder.png" % root_dir)
	if OS.is_debug_build():
		root_dir = "res:/"
	for i in anim_names:
		anims["adv_" + i] = false
		var anim_texture = AnimatedTexture.new()
		var temp_arr = []
		var dir = Directory.new()
		if dir.open("%s/sprites/character/%s" % [root_dir, character_name]) == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					pass
				else:
					if file_name.begins_with(i) and file_name.get_extension() == "png":
						temp_arr.append(file_name)
				file_name = dir.get_next()
		if temp_arr.size() == 1:
			var texture = load("%s/sprites/character/%s/%s.png" % [root_dir, character_name, i])
			anims[i] = texture
		elif temp_arr.size() != 0:
			print(i)
			var curr_frame = 0
			anim_texture.frames = temp_arr.size()
			anim_texture.fps = 100
			for o in temp_arr:
				var texture = load("%s/sprites/character/%s/%s" % [root_dir, character_name, o])
				var args = o.split("-")
				if curr_frame == 0:
					anim_texture.oneshot = bool(args[3].replace(".png", ""))
					print(anim_texture.oneshot)
				var cool_number = (float(args[2])/1000.0)
				anim_texture.set_frame_texture(curr_frame,texture)
				anim_texture.set_frame_delay(curr_frame,cool_number)
				curr_frame += 1
			anims[i] = anim_texture
			anims["adv_" + i] = true
		else:
			anims[i] = placeholder_sprite

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
	
	if VirtualInputs.pressed.L and not cant_input:
		last_pressed = "L"
	if VirtualInputs.pressed.L and not cant_input:
		last_pressed = "R"
	
	if VirtualInputs.down.L and not cant_input:
		joy_dir = -1
	if VirtualInputs.down.R and not cant_input:
		if last_pressed == "L" and VirtualInputs.down.L and not cant_input:
			joy_dir = -1
		else:
			joy_dir = 1
	if not VirtualInputs.down.L and not VirtualInputs.down.R:
		joy_dir = 0
	
	if cant_input_val == 1:
		joy_dir = 0
	
	if joy_dir != 0 and not cant_move:
		moving = true
		if not free:
			spr_dir = joy_dir
			motion.x += accel*joy_dir
		else:
			motion.x += 50*joy_dir
	else:
		moving = false
		if is_zero_approx(motion.x):
			motion.x = 0
			dash_jumping = false
		elif not dash_jumping:
			motion.x /= (friction/100.0)
	
	if VirtualInputs.pressed.A and jump_count < 2 and not cant_input:
		if not dashing:
			if not free:
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
	
	if VirtualInputs.down.D and not free and not cant_input:
		crouching = true
		cant_move_val += 1
	else:
		crouching = false
	
	if VirtualInputs.pressed.D:
		motion.y = max_fall*0.6
	
	if VirtualInputs.pressed.DASH and not cant_input:
		if not dashing :
			curr_dash += 1
			dash_jumping = false
			if joy_dir != 0:
				dash_dir = joy_dir
			else:
				dash_dir = spr_dir
			dashing = true
			dash_accel = dash_speed
			var old_dash = curr_dash
			yield(get_tree().create_timer(dash_time), "timeout")
			if curr_dash == old_dash:
				dashing = false 
	
	if not dashing and not dash_jumping:
		motion.x = clamp(motion.x, -max_speed, max_speed)
	elif dashing:
		motion.x = dash_accel*dash_dir
		dash_accel /= 1.03
		motion.y = 0
	elif dash_jumping:
		cant_move_val += 1
		motion.x /= 1.025641026
		motion.x += joy_dir*20
	
	move_and_slide( motion, UP, false )
	
	if cant_move_val != old_cant_move:
		cant_move = true
	else:
		cant_move = false
		
	old_cant_move = cant_move_val

func _process(delta):
	game_frame += 1
	if GlobalVars.event_rn and type == CharType.PLAYER:
		cant_input_val += 1
	$debug_hurtbox.visible = debug_mode
	var da_shape = RectangleShape2D.new()
	da_shape.extents = hurtbox
	$CollisionShape2D.set_shape(da_shape)
	$debug_hurtbox.rect_position = -$CollisionShape2D.shape.extents
	$debug_hurtbox.rect_size = $CollisionShape2D.shape.extents*2
	$Sprite.offset = offset
	match type:
		CharType.PARTY:
			$Camera.current = false
			if not override_input.empty():
				var iter_input = override_input.back()
				VirtualInputs = iter_input
				override_input.erase(iter_input)
			elif GlobalVars.old_inputs.size() > GlobalVars.party_offset:
				VirtualInputs = GlobalVars.old_inputs[GlobalVars.old_inputs.size()-GlobalVars.party_offset]
				cant_input_val = VirtualInputs.cant_input_val
				if VirtualInputs.idle:
					idle_timer += 1
				else:
					idle_timer = 0
				if idle_timer == 1:
					var main_x = GlobalVars.current_character.position.x
					var my_x = self.position.x
					if main_x > my_x:
						print_debug("Left of player")
					elif my_x > main_x:
						print_debug("Right of player")
		CharType.PLAYER:
			GlobalVars.is_play_val += 1
			var result = true
			if Input.is_action_just_pressed("U") or Input.is_action_just_pressed("D") or Input.is_action_just_pressed("L") or Input.is_action_just_pressed("R") or Input.is_action_just_pressed("A") or Input.is_action_just_pressed("DASH"):
				result = false
			if Input.is_action_pressed("U") or Input.is_action_pressed("D") or Input.is_action_pressed("L") or Input.is_action_pressed("R") or Input.is_action_pressed("A") or Input.is_action_pressed("DASH"):
				result = false
			VirtualInputs = {
				"pressed": {
					"U": Input.is_action_just_pressed("U"),
					"D": Input.is_action_just_pressed("D"),
					"L": Input.is_action_just_pressed("L"),
					"R": Input.is_action_just_pressed("R"),
					"A": Input.is_action_just_pressed("A"),
					"DASH": Input.is_action_just_pressed("DASH"),
				},
				"down": {
					"U": Input.is_action_pressed("U"),
					"D": Input.is_action_pressed("D"),
					"L": Input.is_action_pressed("L"),
					"R": Input.is_action_pressed("R"),
					"A": Input.is_action_pressed("A"),
					"DASH": Input.is_action_pressed("DASH"),
				},
				"cant_input_val": cant_input_val,
				"idle": result
			}
			GlobalVars.old_inputs.append(VirtualInputs)
			if GlobalVars.old_inputs.size() > GlobalVars.party_offset+1:
				GlobalVars.old_inputs.remove(0)
			GlobalVars.current_character = self
			$Camera.current = true
		CharType.NPC:
			VirtualInputs = GlobalVars.InputTemplate
	############################################################
	if GlobalVars.mode == "multi":
		match type:
			CharType.PLAYER:
				if (prev_pos != JSON.print({"x": position.x, "y": position.y})):
#					print("WOW " + str(game_frame))
					Network._set_pos(position.x, position.y)
				if (prev_VirtualInputs != JSON.print(VirtualInputs)):
					print(VirtualInputs.pressed.A)
					Network._send_input(VirtualInputs)
	############################################################
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
		cant_input_val = 0
		old_cant_input = 0
		
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
				curr_texture = [anims.crouch, anims.adv_crouch, "crouch"]
			elif moving:
				curr_texture = [anims.run, anims.adv_run, "run"]
			else:
				curr_texture = [anims.idle, anims.adv_idle, "idle"]
		else:
			if motion.y < 1:
				curr_texture = [anims.jump, anims.adv_jump, "jump"]
			else:
				curr_texture = [anims.fall, anims.adv_fall, "fall"]
	else:
		curr_texture = [anims.dash, anims.adv_dash, "dash"]
	
	if (old_texture != curr_texture[2]):
		new_anim_timer = 0
	new_anim_timer += 1
	
	$Sprite.texture = curr_texture[0]
	
	if (new_anim_timer == 1):
		if curr_texture[1]:
			$Sprite.texture.current_frame = 0
	
	old_texture = curr_texture[2]
	
	prev_VirtualInputs = JSON.print(VirtualInputs)
	prev_pos = JSON.print({"x": position.x, "y": position.y})
