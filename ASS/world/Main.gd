extends Node2D
class_name Main

@export var level_scene: PackedScene

var level_instance: Node
var systems_runner: OptimizedSystemsRunner

func _ready() -> void:
	if level_scene:
		level_instance = level_scene.instantiate()
		add_child(level_instance)
		systems_runner = level_instance.get_node_or_null("OptimizedSystemsRunner") as OptimizedSystemsRunner

func _process(delta: float) -> void:
	if systems_runner:
		# The optimized system handles its own updates
		pass
