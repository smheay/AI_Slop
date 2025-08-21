extends Node
class_name NodeUtil

static func get_or_null(root: Node, path: NodePath) -> Node:
	return root.get_node_or_null(path)

static func safe_free(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


