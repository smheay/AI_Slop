extends Node
class_name SpatialHash2D

@export var cell_size: float = 64.0
var _cells: Dictionary = {}
var _index: Dictionary = {}
var _dirty_agents: Array[Node2D] = []
var _update_threshold: int = 100  # Only update spatial hash when this many agents are dirty

static func _key(pos: Vector2, cell_size: float) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size), floor(pos.y / cell_size))

func insert(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	var k := _key(node.global_position, cell_size)
	_index[node] = k
	if not _cells.has(k):
		_cells[k] = []
	_cells[k].append(node)

func remove(node: Node2D) -> void:
	if not is_instance_valid(node) or not _index.has(node):
		return
	var k: Vector2i = _index[node]
	_index.erase(node)
	if _cells.has(k):
		(_cells[k] as Array).erase(node)
		if (_cells[k] as Array).is_empty():
			_cells.erase(k)

func mark_dirty(node: Node2D) -> void:
	if is_instance_valid(node) and node not in _dirty_agents:
		_dirty_agents.append(node)

func update_dirty_agents() -> void:
	if _dirty_agents.size() < _update_threshold:
		return
		
	for agent in _dirty_agents:
		if is_instance_valid(agent):
			_move_internal(agent)
	_dirty_agents.clear()

func move(node: Node2D) -> void:
	# Just mark as dirty instead of immediate update
	if is_instance_valid(node):
		mark_dirty(node)

func _move_internal(node: Node2D) -> void:
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
				if n2d and is_instance_valid(n2d) and (n2d.global_position - center).length_squared() <= r2:
					results.append(n2d)
	return results

func get_dirty_count() -> int:
	return _dirty_agents.size()

func force_cleanup() -> void:
	# Force cleanup of any invalid references in the spatial hash
	# This is called when we detect freed objects that need cleanup
	
	# Clean up invalid agents from dirty list
	var i := 0
	while i < _dirty_agents.size():
		if not is_instance_valid(_dirty_agents[i]):
			_dirty_agents.remove_at(i)
		else:
			i += 1
	
	# Clean up invalid agents from all cells
	for cell_key in _cells:
		var cell := _cells[cell_key] as Array
		if cell:
			var j := 0
			while j < cell.size():
				if not is_instance_valid(cell[j]):
					cell.remove_at(j)
				else:
					j += 1
			
			# Remove empty cells
			if cell.is_empty():
				_cells.erase(cell_key)
	
	# Clean up invalid entries from index
	var keys_to_remove := []
	for agent in _index:
		if not is_instance_valid(agent):
			keys_to_remove.append(agent)
	
	for key in keys_to_remove:
		_index.erase(key)
