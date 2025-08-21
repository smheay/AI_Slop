extends Node
class_name MapGenerator

signal generated()

@export var preset: Resource
@export var tilemap_path: NodePath

func generate(seed: int = 0) -> void:
	# TODO: Use preset + rules to paint the tilemap
	emit_signal("generated")


