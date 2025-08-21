extends Node2D
class_name Main

@export var level_scene: PackedScene

var level_instance: Node
var systems_runner: SystemsRunner

func _ready() -> void:
	if level_scene:
		level_instance = level_scene.instantiate()
		add_child(level_instance)
		systems_runner = level_instance.get_node_or_null("SystemsRunner") as SystemsRunner

func _process(delta: float) -> void:
	if systems_runner:
		systems_runner.step_frame(delta)
