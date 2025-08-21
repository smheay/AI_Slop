extends BaseEnemy
class_name BossGolem

@export var slam_cooldown: float = 3.0
var _cd := 0.0

func _compute_desired_velocity(delta: float) -> Vector2:
	_cd = max(0.0, _cd - delta)
	if _cd == 0.0:
		_cd = slam_cooldown
	if target_position != Vector2.ZERO:
		return (target_position - global_position).normalized() * (move_speed * 0.75)
	return Vector2.ZERO


