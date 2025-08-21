extends Node
class_name MathUtil

static func clamp01(v: float) -> float:
	return clampf(v, 0.0, 1.0)

static func move_towards(a: Vector2, b: Vector2, max_delta: float) -> Vector2:
	var d := b - a
	var l := d.length()
	return b if l <= max_delta or is_zero_approx(l) else a + d / l * max_delta


