extends Node
class_name CommandBindings

signal command_invoked(command: String, target: Node, args: Array)

@export var bindings: Dictionary = {
	"spawn": {"target_group": "spawners"},
	"buff": {"target_group": "enemies"},
	"debuff": {"target_group": "enemies"}
}

func invoke(command: String, args: Array) -> void:
# inside invoke(command: String, args: Array)
	var binding: Dictionary
	if bindings.has(command):
		binding = bindings[command]
	else:
		return
	var group: StringName = StringName(String(binding["target_group"])) if binding.has("target_group") else StringName("")
	for node in get_tree().get_nodes_in_group(group):
		emit_signal("command_invoked", command, node, args)
