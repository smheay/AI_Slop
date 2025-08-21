extends Node
class_name Steering

@export var flow_field_path: NodePath

func compute_desired_velocity(from: Vector2) -> Vector2:
	# TODO: Use FlowField for large-scale movement
	return Vector2.ZERO


