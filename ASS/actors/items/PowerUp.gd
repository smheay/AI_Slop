extends BaseItem
class_name PowerUp

@export var duration: float = 10.0
@export var stat_modifiers: Dictionary = {"move_speed": 1.25}

func on_pickup(by: Node) -> void:
	super.on_pickup(by)
	# TODO: Apply temporary modifiers and schedule removal
	GameBus.emit_signal("stats_modified", by, self)


