extends BaseNPC
class_name Shopkeeper

func interact(by: Node) -> void:
	# TODO: Open shop UI
	emit_signal("interacted", by)


