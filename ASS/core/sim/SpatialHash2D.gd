extends Node
class_name SpatialHash2D

@export var cell_size: float = 64.0
var _cells: Dictionary = {}
var _index: Dictionary = {}

static func _key(pos: Vector2, cell_size: float) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size), floor(pos.y / cell_size))

func insert(node: Node2D) -> void:
	var k := _key(node.global_position, cell_size)
	_index[node] = k
	if not _cells.has(k):
		_cells[k] = []
	_cells[k].append(node)

func remove(node: Node2D) -> void:
	if not _index.has(node):
		return
	var k: Vector2i = _index[node]
	_index.erase(node)
	if _cells.has(k):
		(_cells[k] as Array).erase(node)
		if (_cells[k] as Array).is_empty():
			_cells.erase(k)

func move(node: Node2D) -> void:
	var new_k := _key(node.global_position, cell_size)
	var old_k = _index.get(node, new_k)
	if new_k == old_k:
		return
	if _cells.has(old_k):
		(_cells[old_k] as Array).erase(node)
		if (_cells[old_k] as Array).is_empty():
			_cells.erase(old_k)
	if not _cells.has(new_k):
		_cells[new_k] = []
	_cells[new_k].append(node)
	_index[node] = new_k

func query_radius(center: Vector2, radius: float) -> Array:
	var results: Array = []
	var r: float = max(radius, 0.0)
	var min_cell := _key(center - Vector2(r, r), cell_size)
	var max_cell := _key(center + Vector2(r, r), cell_size)
	var r2 := r * r
	for cy in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			var k := Vector2i(cx, cy)
			if not _cells.has(k):
				continue
			for node in _cells[k]:
				var n2d := node as Node2D
				if n2d and (n2d.global_position - center).length_squared() <= r2:
					results.append(n2d)
	return results
