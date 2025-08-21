extends BaseEnemy
class_name Slime

@export var hop_interval: float = 1.2
var _timer := 0.0

func _compute_desired_velocity(delta: float) -> Vector2:
	_timer -= delta
	if _timer <= 0.0:
		_timer = hop_interval
		if _target:
			return (_target.global_position - global_position).normalized() * move_speed
	return Vector2.ZERO


