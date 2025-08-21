extends Resource
class_name RNG

@export var seed_value: int = 0

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	if seed_value != 0:
		_rng.seed = seed_value

func randf_range(min_val: float, max_val: float) -> float:
	return _rng.randf_range(min_val, max_val)

func pick(array: Array) -> Variant:
	return array[_rng.randi() % max(1, array.size())]


