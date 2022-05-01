class_name Event

extends Node

var event_count = 0
var curr_event = 0

signal done

func _init(events):
	event_count = events.size()
	GlobalVars.event = self
	GlobalVars.event_rn = true
	while curr_event < event_count:
		yield(exec_event(events[curr_event]), "completed")
	emit_signal("done")
	GlobalVars.event_rn = false

func exec_event(event):
	event.exec()
	yield(event, "done")
	curr_event += 1
