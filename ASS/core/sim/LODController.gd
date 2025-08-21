extends Node
class_name LODController

@export var near_distance: float = 256.0
@export var far_distance: float = 1024.0

func compute_lod(camera_pos: Vector2, target_pos: Vector2) -> int:
	var d := camera_pos.distance_to(target_pos)
	if d < near_distance:
		return 0
	if d < far_distance:
		return 1
	return 2


