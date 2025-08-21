extends Node
class_name Attack

signal performed(caster: Node)

@export var cooldown: float = 0.5
@export var damage: float = 10.0
@export var range: float = 64.0

var _cooldown_timer := 0.0

func can_attack() -> bool:
	return _cooldown_timer <= 0.0

func perform(caster: Node, target_position: Vector2) -> void:
	# TODO: Spawn hitbox/projectiles via pool
	_cooldown_timer = cooldown
	emit_signal("performed", caster)

func tick(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta


