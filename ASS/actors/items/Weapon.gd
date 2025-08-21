extends BaseItem
class_name Weapon

@export var power: float = 15.0
@export var attack_speed_mod: float = -0.1

func on_equip(by: Node) -> void:
	super.on_equip(by)
	# TODO: Modify Player attack interval/power via Stats
	GameBus.emit_signal("stats_modified", by, self)

func on_unequip(by: Node) -> void:
	super.on_unequip(by)
	# TODO: Revert modifiers
	GameBus.emit_signal("stats_modified", by, self)


