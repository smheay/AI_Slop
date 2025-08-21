extends Node2D
class_name ItemSpawner

@export var item_scenes: Array[PackedScene] = []
@export var radius: float = 128.0

func spawn_random() -> Node:
	if item_scenes.is_empty():
		return null
	var idx := randi() % item_scenes.size()
	var scene := item_scenes[idx]
	var inst := scene.instantiate()
	if inst is Node2D:
		var angle := randf() * TAU
		(inst as Node2D).global_position = global_position + Vector2.RIGHT.rotated(angle) * randf() * radius
	get_tree().current_scene.add_child(inst)
	return inst


