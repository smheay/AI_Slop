extends Node
class_name Health

signal healed(amount: float)
signal damaged(amount: float)
signal died()

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health

func apply_heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	emit_signal("healed", amount)

func apply_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	emit_signal("damaged", amount)
	if current_health <= 0.0:
		emit_signal("died")


