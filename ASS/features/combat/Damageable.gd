extends Node
class_name Damageable

signal damaged(amount: float, source: Node)
signal died(source: Node)

@export var max_health: float = 100.0
@export var hit_radius: float = 12.0
var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, source: Node) -> void:
	current_health = max(0.0, current_health - amount)
	emit_signal("damaged", amount, source)
	if current_health <= 0.0:
		emit_signal("died", source)


