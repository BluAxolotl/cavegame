extends Control

const RoomButton = preload("res://objects/RoomButton.tscn")

var RoomList = {}
var selected_room = null
var selected_room_id = null
var got_rooms = false

func _ready():
	GlobalVars.mode = "multi"
	Network.connect("GotRooms", self, "load_room_list")
	$Back.connect("pressed", self, "go_home")
	$Join.connect("pressed", self, "join_room")
	$Refresh.connect("pressed", Network, "_get_rooms")
	$Host.connect("pressed", $RoomSetup, "popup")
	$Setup.connect("confirmed", self, "setup_done")
	$RoomSetup.connect("confirmed", self, "make_room")
	
	$Setup.popup()

func _process(delta):
	$Fade.visible = ($Setup.visible or $RoomSetup.visible)
	if not got_rooms and Network.connected:
		got_rooms = true
		Network._get_rooms()
	if selected_room == null:
		$Join.visible = false
	else:
		$Join.visible = true

func setup_done():
	var s_name = $Setup/Control/LineEdit.text
	var s_char_name = $Setup/Control/OptionButton.text.to_lower()
	print(s_name)
	print(s_char_name)
	Network.obj.name = s_name
	Network.obj.charname = s_char_name

func make_room():
	var r_name = $RoomSetup/Control/LineEdit.text
	var r_pass = $RoomSetup/Control/LineEdit2.text
	var r_id = GlobalVars.id_gen()
	Network._make_room(r_name, r_pass, r_id)

func go_home():
	get_tree().change_scene("res://scenes/TitleScreen.tscn")

func join_room():
	Network._join_room(selected_room_id)

func load_room_list(rooms):
	for i in $ScrollContainer/VSplitContainer.get_children():
		$ScrollContainer/VSplitContainer.remove_child(i)
	for i in rooms:
		var rb = RoomButton.instance()
		rb.connect("pressed", self, "select_room", [i.id])
		RoomList[i.id] = rb
		rb.text = "%s - %s " % [i.name, i.id]
		$ScrollContainer/VSplitContainer.add_child(rb)

func select_room(id):
	var rb = RoomList[id]
	selected_room = rb
	selected_room_id = id
