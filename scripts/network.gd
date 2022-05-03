extends Node

export var websocket_url = "wss://MultiplayerWebSocket.donovanedwards.repl.co"

var _client = WebSocketClient.new()
var connected = false
var connecting = false
var start_connecting = false
var obj = {
	"name": "",
	"charname": "",
	"id": null,
	"is_host": false,
	"room": {
		"name": "",
		"password": "",
		"id": null,
		"player": [],
		"my_index": null
	}
}
var other_players = {}
var ping_time = 0

signal GotRooms

func _ready():
	print(OS.is_debug_build())
	if OS.is_debug_build():
		websocket_url = websocket_url
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")

func initialize():
	start_connecting = true

func _closed(was_clean = false):
	connected = false
	set_process(false)

func _connected(_proto):
	connecting = false
	print("connected!")
	ping()
	connected = true

func _on_data():
	var json_string = JSON.parse(_client.get_peer(1).get_packet().get_string_from_utf8())
	var message = json_string.result
	if (message.type == "pong"):
		print("RECIEVED PONG")
		ping_time = OS.get_system_time_msecs() - message.timestamp
	elif (message.type != "send_input" and message.type != "broadcast_send_input"): print(message)
	if String(message.type).begins_with("broadcast_") and message.requestingID != obj.id:
		message.type = message.type.replace("broadcast_", "")
		match message.type:
			"leave_room":
				if other_players.has(message.requestingID):
					other_players[message.requestingID].queue_free()
			"join_room":
				var c = Character.new().c_return(message.content.charname, -1, 320, 240)
				other_players[message.requestingID] = c
			"send_input":
				if other_players.has(message.requestingID):
					other_players[message.requestingID].VirtualInputs = message.content
	else:
		match message.type:
			"make_room":
				get_tree().change_scene("res://scenes/Test.tscn")
				yield(GlobalVars, "ChangedScene")
				var new_main = Character.new().c_return(Network.obj.charname, 1, 320, 240)
				GlobalVars.current_character = new_main
				Network.obj.room.id = message.content.id
				Network.obj.room.name = message.content.name
				Network.obj.room.password = message.content.pass
				Network.obj.room.players = []
				Network.obj.room.my_index = 0
			"connection":
				obj.id = message.id
				print(message.id)
			"return_rooms":
				emit_signal("GotRooms", message.content)
			"join_room":
				obj.room.id = message.content.room_id
				get_tree().change_scene("res://scenes/Test.tscn")
				yield(GlobalVars, "ChangedScene")
				obj.room.my_index = int(message.content.your_index)
				print(obj.room.my_index)
				var new_main = Character.new().c_return(obj.charname, 1, 320, 240)
				GlobalVars.current_character = new_main
				for i in message.content.players:
					print(i.name)
					var c = Character.new().c_return(i.charname, -1, i.x, i.y)
					other_players[i.id] = c

func _process(delta):
	if (start_connecting):
		_client.poll()
		if not connected and not connecting:
			connecting = true
			print(websocket_url)
			var err = _client.connect_to_url(websocket_url)
			if err != OK:
				connecting = false
				OS.alert("Unable to connect", "ERROR!")
				set_process(false)

func _send_input(inputs):
	var to_send = {
		"room_id": obj.room.id,
		"requestingID": obj.id,
		"type": "send_input",
		"inputs": inputs
	}
	_client.get_peer(1).put_packet(JSON.print(to_send).to_utf8())

func _get_rooms():
	var to_send = {
		"requestingID": obj.id,
		"type": "return_rooms",
		"name": obj.name,
		"id": obj.id,
	}
	_client.get_peer(1).put_packet(JSON.print(to_send).to_utf8())

func _join_room(id):
	var to_send = {
		"requestingID": obj.id,
		"type": "join_room",
		"player": get_player(),
		"room_id": id,
	}
	_client.get_peer(1).put_packet(JSON.print(to_send).to_utf8())

func _make_room(_name, _pass, _id):
	var to_send = {
		"requestingID": obj.id,
		"type": "make_room",
		"room": {"id": _id, "name": _name, "pass": _pass},
		"player": {"name": "BluAxolotl", "id": obj.id},
	}
	_client.get_peer(1).put_packet(JSON.print(to_send).to_utf8())

func _set_pos(_x, _y):
	var to_send = {
		"requestingID": obj.id,
		"requestingIndex": obj.room.my_index,
		"type": "set_pos",
		"room_id": obj.room.id,
		"x": _x,
		"y": _y,
	}
	_client.get_peer(1).put_packet(JSON.print(to_send).to_utf8())

func get_player():
	if GlobalVars.is_playing:
		return {
			"name": obj.name,
			"id": obj.id,
			"charname": obj.charname,
			"x": GlobalVars.current_character.position.x,
			"y": GlobalVars.current_character.position.y
		}
	else:
		return {
			"name": obj.name,
			"id": obj.id,
			"charname": obj.charname,
		}

func ping():
	print("Pinging...")
	var room_id = null
	if (obj.room != null):
		room_id = obj.room.my_index
	var to_send = {
		"type": "ping",
		"requestingID": obj.id,
		"timestamp": OS.get_system_time_msecs(),
		"room_id": room_id
	}
	_client.get_peer(1).put_packet(JSON.print(to_send).to_utf8())
	yield(get_tree().create_timer(1.0), "timeout")
	ping()
