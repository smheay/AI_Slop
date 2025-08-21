extends Resource
class_name Ability

signal cast_started(caster: Node)
signal cast_finished(caster: Node)

@export var name: StringName
@export var cooldown: float = 1.0
@export var base_power: float = 1.0
@export var scale_with_stat: StringName = "power"
@export var vfx_scene: PackedScene
@export var category: StringName = &"attack"
@export var tags: Array[StringName] = []
@export var icon: Texture2D

var _cooldown_timer := 0.0

func can_cast() -> bool:
	return _cooldown_timer <= 0.0

func cast(caster: Node, context: Dictionary = {}) -> void:
	# TODO: Implement effect in subclass or by strategy
	_cooldown_timer = cooldown
	emit_signal("cast_started", caster)
	emit_signal("cast_finished", caster)

func tick(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func _get_stat(caster: Node, stat: StringName, fallback: float = 1.0) -> float:
	var s := caster.get_node_or_null("Stats") as Stats
	return s.get_stat(stat) if s else fallback

func _get_tag_power_multiplier(caster: Node) -> float:
	var s := caster.get_node_or_null("Stats") as Stats
	if not s:
		return 1.0
	var all_tags: Array[StringName] = []
	all_tags.append(category)
	for t in tags:
		all_tags.append(t)
	return s.get_multiplier_for_tags(all_tags)

func get_cooldown_remaining() -> float:
	return max(_cooldown_timer, 0.0)

func get_cooldown_ratio() -> float:
	if cooldown <= 0.0:
		return 0.0
	return clamp(_cooldown_timer / cooldown, 0.0, 1.0)


func _get_tag_damage_scalars(caster: Node) -> Dictionary:
	var s := caster.get_node_or_null("Stats") as Stats
	if not s:
		return {"add": 0.0, "inc": 0.0, "more": 1.0}
	var all_tags: Array[StringName] = []
	all_tags.append(category)
	for t in tags:
		all_tags.append(t)
	return s.get_tag_damage_scalars(all_tags)

