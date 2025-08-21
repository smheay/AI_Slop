extends BaseItem
class_name HealthPotion

@export var heal_amount: float = 50.0

func on_pickup(by: Node) -> void:
	super.on_pickup(by)
	# TODO: Find Health component and heal


