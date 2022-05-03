extends Node2D

func _ready():
	#                          U D L R
	GlobalVars.camera_limits = [670, 830, 40, 3390]
	GlobalVars.hud_elements = [
		$Screen,
		$ScreenTop,
		$Background,
		$PingLabel
	]
	GlobalVars.change_current_scene(self)
	match GlobalVars.mode:
		"single":
			Character.new().c_return("lodges", 2, 320, 240)
			var new_main = Character.new().c_return("bulb", 1, 320, 240)
			GlobalVars.current_character = new_main
		"multi":
			pass
	Event.new([
		Textbox.new("Anyways :/", Color(1,1,1), null, null),
		Textbox.new("Sans Sans Sans Sans Sans ", Color(1,1,1), null, null),
		Textbox.new("The quick brown fox jumps over the lazy dog", Color("#5BA8FF"), null, [["dog", Color(1,0,0)], ["fox", Color(1,0,0)]]),
	])
	yield(GlobalVars.event, "done")

func _process(delta):
	$PingLabel.text = "%sms" % Network.ping_time
	if GlobalVars.current_character != null:
		if GlobalVars.current_character.position.distance_to($Ans.position) < 100 and not GlobalVars.event_rn:
			$"Ans/!".visible = true
			if Input.is_action_just_pressed("U"):
				Event.new([
					Textbox.new("Oh hey, %s" % GlobalVars.current_character.character_name.capitalize(), Color(1,1,1), null, [[GlobalVars.current_character.character_name.capitalize(), Color("#FFE737")]]),
				])
		else:
			$"Ans/!".visible = false
