extends Node

signal ChangedScene

const InputTemplate = {
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
	"cant_input_val": 0,
	"idle": false
}

var textbox_text = ""
var textbox_color = ""
var textbox_control = ""
var text_coloring = []

var current_scene
var current_character = null
var current_camera = null

var hud_elements = []
var camera_limits = []

var event
var event_rn = false
var old_inputs = []

var party_offset = 10

var mode = "single"

var is_playing = false
var is_play_val = 0
var old_is_play = 0

func _process(_delta):
	if is_play_val != old_is_play:
		is_playing = true
	else:
		is_playing = false
		is_play_val = 0
		old_is_play = 0

func change_current_scene(scene):
	current_scene = scene
	emit_signal("ChangedScene")

func id_gen():
	var ints = [0,1,2,3,4,5,6,7,8,9]
	var to_return = PoolStringArray([])
	for i in 18:
		ints.shuffle()
		to_return.append(String(ints[0]))
	return to_return.join("")
