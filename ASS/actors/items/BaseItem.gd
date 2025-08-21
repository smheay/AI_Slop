extends Node2D
class_name BaseItem

signal picked_up(by: Node)
signal equipped(by: Node)
signal unequipped(by: Node)

@export var display_name: String = "Item"
@export var auto_pickup: bool = true

func on_pickup(by: Node) -> void:
	emit_signal("picked_up", by)

func on_equip(by: Node) -> void:
	emit_signal("equipped", by)

func on_unequip(by: Node) -> void:
	emit_signal("unequipped", by)


