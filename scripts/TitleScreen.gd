extends Node2D

func _ready():
	$Single.connect("pressed", self, "_singleplayer")
	$Multi.connect("pressed", self, "_multiplayer")

func _singleplayer():
	GlobalVars.mode = "single"
	get_tree().change_scene("res://scenes/Test.tscn")

func _multiplayer():
	Network.initialize()
	GlobalVars.mode = "multi"
	get_tree().change_scene("res://scenes/RoomDirectory.tscn")
