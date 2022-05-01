extends Sprite

var control = "A"
var full_text = ""
var skipped = false
var finished = false

signal done

func _ready():
	$Text.add_color_override("font_color", GlobalVars.textbox_color)
	$Text.text = ""
	full_text = GlobalVars.textbox_text
	var string_arr = PoolStringArray([])
	yield(get_tree().create_timer(0.025), "timeout")
	if GlobalVars.text_coloring != null:
		for i in GlobalVars.text_coloring:
			$Text.add_keyword_color(i[0], i[1])
	for i in full_text:
		if not skipped:
			string_arr.append(i)
			$Text.text = string_arr.join("")
			yield(get_tree().create_timer(0.025), "timeout")
			if string_arr.join("") == full_text:
				finished = true
		elif not finished:
			$Text.text = full_text
			yield(get_tree().create_timer(0.01), "timeout")
			finished = true

func _process(delta):
	if GlobalVars.textbox_control != null:
		control = GlobalVars.textbox_control
	if Input.is_action_just_pressed(control) and finished:
		yield(get_tree().create_timer(0.01), "timeout")
		emit_signal("done")
		GlobalVars.hud_elements.erase(self)
		queue_free()
	if Input.is_action_just_pressed(control) and not finished:
		skipped = true
