extends Node
class_name Stats

signal changed()

@export var base_stats: Dictionary = {
	"power": 1.0,
	"defense": 0.0,
	"move_speed": 1.0,
	"attack_speed": 1.0,
	"aoe": 1.0,
	"cooldown": 1.0
}

var modifiers: Array[Dictionary] = []

func get_stat(stat: StringName) -> float:
	var base_value: float = float(base_stats.get(stat, 0.0))
	var add_total: float = 0.0
	var mul_total: float = 1.0
	for mod in modifiers:
		var add_map := (mod.get("add", {}) as Dictionary)
		if add_map.has(stat):
			add_total += float(add_map[stat])
		var mul_map := (mod.get("mul", {}) as Dictionary)
		if mul_map.has(stat):
			mul_total *= float(mul_map[stat])
		# Back-compat: plain {"stat": factor} treated as multiplicative
		if not mod.has("mul") and mod.has(stat):
			mul_total *= float(mod[stat])
	return (base_value + add_total) * mul_total

func add_modifier(mod: Dictionary) -> void:
	var id: StringName = StringName(mod.get("id", ""))
	if id != StringName(""):
		remove_modifier_by_id(id)
	modifiers.append(mod)
	emit_signal("changed")

func remove_modifier(mod: Dictionary) -> void:
	modifiers.erase(mod)
	emit_signal("changed")

func remove_modifier_by_id(id: StringName) -> void:
	for i in range(modifiers.size() - 1, -1, -1):
		var m := modifiers[i]
		if StringName(m.get("id", "")) == id:
			modifiers.remove_at(i)
			emit_signal("changed")
			return

func clear_modifiers_by_tag(tag: StringName) -> void:
	var changed := false
	for i in range(modifiers.size() - 1, -1, -1):
		var m := modifiers[i]
		var tags := (m.get("tags", []) as Array)
		if tag in tags:
			modifiers.remove_at(i)
			changed = true
	if changed:
		emit_signal("changed")

func add_timed_modifier(mod: Dictionary, duration_sec: float) -> void:
	var id: StringName = StringName(mod.get("id", ""))
	if id == StringName(""):
		id = StringName("mod_" + str(get_instance_id()) + "_" + str(Time.get_ticks_msec()))
		mod["id"] = id
	add_modifier(mod)
	var timer := get_tree().create_timer(max(duration_sec, 0.0))
	await timer.timeout
	remove_modifier_by_id(id)

func get_multiplier_for_tags(tags: Array) -> float:
	var mul_total: float = 1.0
	for mod in modifiers:
		var tag_mul := (mod.get("tag_mul", {}) as Dictionary)
		if tag_mul.size() == 0:
			continue
		for t in tags:
			if tag_mul.has(t):
				mul_total *= float(tag_mul[t])
	return mul_total

func get_tag_damage_scalars(tags: Array) -> Dictionary:
	# Returns { "add": float, "inc": float, "more": float }
	var add_total: float = 0.0
	var inc_total: float = 0.0
	var more_total: float = 1.0
	for mod in modifiers:
		var tag_add := (mod.get("tag_add", {}) as Dictionary)
		var tag_inc := (mod.get("tag_inc", {}) as Dictionary)
		var tag_more := (mod.get("tag_more", {}) as Dictionary)
		for t in tags:
			if tag_add.has(t):
				add_total += float(tag_add[t])
			if tag_inc.has(t):
				inc_total += float(tag_inc[t])
			if tag_more.has(t):
				more_total *= float(tag_more[t])
	return {"add": add_total, "inc": inc_total, "more": more_total}
