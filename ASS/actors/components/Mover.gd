extends Node
class_name Mover

@export var max_speed: float = 200.0
@export var acceleration: float = 1400.0

func steer(body: CharacterBody2D, desired_velocity: Vector2, delta: float) -> void:
	var v: Vector2 = body.velocity
	var dv: Vector2 = desired_velocity.limit_length(max_speed) - v
	var impulse: Vector2 = dv.limit_length(acceleration * delta)
	body.velocity = v + impulse
