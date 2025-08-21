extends BaseItem
class_name Armor

@export var armor_value: float = 10.0
@export var slot: StringName = &"body"

func on_equip(by: Node) -> void:
	super.on_equip(by)
	# TODO: Increase defense on Stats
	GameBus.emit_signal("stats_modified", by, self)

func on_unequip(by: Node) -> void:
	super.on_unequip(by)
	# TODO: Revert defense
	GameBus.emit_signal("stats_modified", by, self)


