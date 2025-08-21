extends Node
class_name StateMachine

signal state_changed(prev: StringName, next: StringName)

var _current: StringName = &"idle"

func set_state(next: StringName) -> void:
	if _current == next:
		return
	var prev := _current
	_current = next
	emit_signal("state_changed", prev, next)

func get_state() -> StringName:
	return _current


