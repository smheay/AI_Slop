extends Node
class_name Balance

@export var enemy_defs: Resource
@export var npc_defs: Resource
@export var item_defs: Resource
@export var loot_tables: Resource
@export var twitch_bindings: Resource
@export var settings: Resource

func get_enemy_def(key: StringName) -> Dictionary:
	# TODO: Return dictionary from enemy_defs
	return {}

func get_item_def(key: StringName) -> Dictionary:
	# TODO: Return dictionary from item_defs
	return {}


