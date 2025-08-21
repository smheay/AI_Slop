extends Node
class_name LevelRuntime

@export var systems_runner_path: NodePath
@export var dungeon_tilemap_path: NodePath
@export var command_parser_path: NodePath
@export var command_bindings_path: NodePath

var systems_runner: SystemsRunner
var dungeon_tilemap: DungeonTileMap
var command_parser: CommandParser
var command_bindings: CommandBindings

func _ready() -> void:
	systems_runner = get_node_or_null(systems_runner_path)
	dungeon_tilemap = get_node_or_null(dungeon_tilemap_path)
	command_parser = get_node_or_null(command_parser_path)
	command_bindings = get_node_or_null(command_bindings_path)
	if Twitch and command_parser:
		Twitch.message_received.connect(_on_twitch_message_received)
	if command_parser and command_bindings:
		command_parser.command_parsed.connect(_on_command_parsed)

func _on_twitch_message_received(user: String, message: String) -> void:
	if command_parser:
		command_parser.parse(user, message)

func _on_command_parsed(user: String, cmd: String, args: Array) -> void:
	GameBus.emit_signal("chat_command", user, cmd, args)
