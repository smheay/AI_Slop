extends Area2D
class_name Pickup

signal picked(by: Node)

@export var item_path: NodePath

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var item := get_node_or_null(item_path) as BaseItem
	if item:
		item.on_pickup(body)
		emit_signal("picked", body)
	queue_free()


