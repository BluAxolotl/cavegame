class_name Textbox

extends Node

var text = ""
var color = Color(1,1,1)
var control = null
var text_coloring = null

signal done

const textbox = preload("res://objects/textbox.tscn")

func _init(text2, color2, control2, text_coloring2):
	text = text2
	color = color2
	control = control2
	text_coloring = text_coloring2
	return self

func exec():
	GlobalVars.textbox_text = text
	GlobalVars.textbox_color = color
	GlobalVars.textbox_control = control
	GlobalVars.text_coloring = text_coloring
	var tb = textbox.instance()
	GlobalVars.hud_elements.append(tb)
	yield(GlobalVars.current_scene.get_tree().create_timer(0.01), "timeout")
	GlobalVars.current_scene.add_child(tb)
	yield(tb, "done")
	emit_signal("done")
