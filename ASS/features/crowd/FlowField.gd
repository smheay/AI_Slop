extends Node
class_name FlowField

@export var cell_size: int = 32

func build_from_tilemap(tilemap: TileMap) -> void:
	# TODO: Generate cost/flow vectors grid
	pass

func sample_direction(world_pos: Vector2) -> Vector2:
	# TODO: Return normalized direction from flow field
	return Vector2.ZERO


