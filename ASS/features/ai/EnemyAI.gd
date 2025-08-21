extends Node
class_name EnemyAI

@export var state_machine_path: NodePath
@export var target_group: StringName = "player"

func decide(delta: float) -> void:
	# TODO: Evaluate target proximity and set states
	pass


