extends Node
class_name TwitchClient

signal connected()
signal disconnected()
signal message_received(user: String, message: String)

@export var channel: String = ""
@export var oauth_token: String = ""
@export var username: String = ""

var _connected: bool = false

func connect_async() -> void:
	# TODO: Implement Twitch IRC client; on success:
	_connected = true
	emit_signal("connected")

func disconnect_async() -> void:
	# TODO: Close connection
	_connected = false
	emit_signal("disconnected")


