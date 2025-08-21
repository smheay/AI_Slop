extends Node
class_name GlobalsSingleton

@export var target_fps: int = 60
@export var max_enemies: int = 3000
@export var tile_size: int = 32

var rng := RandomNumberGenerator.new()

func get_rng() -> RandomNumberGenerator:
	return rng
