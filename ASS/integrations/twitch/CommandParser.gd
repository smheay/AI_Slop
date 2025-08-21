extends Node
class_name CommandParser

signal command_parsed(user: String, command: String, args: Array)

@export var prefix: String = "!"

func parse(user: String, message: String) -> void:
	if not message.begins_with(prefix):
		return
	var parts := message.substr(prefix.length()).strip_edges().split(" ")
	if parts.is_empty():
		return
	var command := String(parts[0]).to_lower()
	var args := parts.slice(1, parts.size())
	emit_signal("command_parsed", user, command, args)


