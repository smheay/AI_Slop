extends Node
class_name EntityIndex

var by_id: Dictionary = {}
var by_group: Dictionary = {}

func register_entity(entity: Node, id: String) -> void:
	by_id[id] = entity

func unregister_entity(id: String) -> void:
	by_id.erase(id)

func add_to_group_index(group: String, entity: Node) -> void:
	if not by_group.has(group):
		by_group[group] = []
	by_group[group].append(entity)

func remove_from_group_index(group: String, entity: Node) -> void:
	if by_group.has(group):
		by_group[group].erase(entity)


