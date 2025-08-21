extends Node
class_name ChatControlled

@export var owner_id: String = "" # tie to a chat user if desired

func _ready() -> void:
	GameBus.connect("chat_command", _on_chat_command)

func _on_chat_command(user: String, command: String, args: Array) -> void:
	# TODO: Filter by owner_id or target, then apply control (e.g., move, buff)
	pass


