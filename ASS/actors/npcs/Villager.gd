extends BaseNPC
class_name Villager

func interact(by: Node) -> void:
	# TODO: Display dialog
	emit_signal("interacted", by)


