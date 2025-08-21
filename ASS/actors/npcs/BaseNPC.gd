extends Node2D
class_name BaseNPC

signal interacted(by: Node)

func interact(by: Node) -> void:
	emit_signal("interacted", by)


