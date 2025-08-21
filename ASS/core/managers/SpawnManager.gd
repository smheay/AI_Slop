extends ManagerBase
class_name SpawnManager

signal spawn_requested(scene: PackedScene, position: Vector2, context: Dictionary)

@export var enemy_scenes: Array[PackedScene] = []
@export var player_scene: PackedScene
@export var item_scenes: Array[PackedScene] = []

func request_spawn(scene: PackedScene, position: Vector2, context: Dictionary = {}) -> void:
	emit_signal("spawn_requested", scene, position, context)

func spawn_instance(scene: PackedScene, parent: Node, position: Vector2, context: Dictionary = {}) -> Node:
	var inst := scene.instantiate()
	if inst is Node2D:
		inst.global_position = position
	parent.add_child(inst)
	if context.has("on_spawn"):
		(context["on_spawn"] as Callable).call(inst)
	return inst


