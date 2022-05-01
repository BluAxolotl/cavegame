class_name Character

extends Node

const node = preload("res://objects/character.tscn")

func c_return(c_name, c_type, c_x, c_y):
	var c = node.instance()
	c.character_name = c_name
	c.type = c_type
	match c.type:
		c.CharType.NPC:
			pass
		c.CharType.PLAYER:
			pass
		c.CharType.PARTY:
			pass
		c.CharType.OTHER_PLAYER:
			pass
	c.position.x = c_x
	c.position.y = c_y
	GlobalVars.current_scene.get_node("RelevantChars").add_child(c)
	var info = CharacterLib.new()[c_name]
	for i in info:
		c[i] = info[i]
	return c
