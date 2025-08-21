extends Node
class_name SpatialHash2D

@export var cell_size: float = 64.0
@export var max_query_results: int = 128

var _cells: Dictionary = {}
var _index: Dictionary = {}
var _query_pool: Array[Node2D] = []
var _query_pool_size: int = 0

# Pre-allocate query results to avoid allocations
func _ready() -> void:
	_query_pool.resize(max_query_results)
	_query_pool_size = 0

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
		var cell_array = _cells[k] as Array
		cell_array.erase(node)
		if cell_array.is_empty():
			_cells.erase(k)

func move(node: Node2D) -> void:
	var new_k := _key(node.global_position, cell_size)
	var old_k = _index.get(node, new_k)
	if new_k == old_k:
		return
	if _cells.has(old_k):
		var cell_array = _cells[old_k] as Array
		cell_array.erase(node)
		if cell_array.is_empty():
			_cells.erase(old_k)
	if not _cells.has(new_k):
		_cells[new_k] = []
	_cells[new_k].append(node)
	_index[node] = new_k

func query_radius(center: Vector2, radius: float) -> Array:
	# Reset query pool
	_query_pool_size = 0
	
	var r: float = max(radius, 0.0)
	var min_cell := _key(center - Vector2(r, r), cell_size)
	var max_cell := _key(center + Vector2(r, r), cell_size)
	var r2 := r * r
	
	# Pre-calculate cell range to avoid repeated calculations
	var cell_range_x = max_cell.x - min_cell.x + 1
	var cell_range_y = max_cell.y - min_cell.y + 1
	
	# Use squared distance to avoid sqrt operations
	for cy in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			var k := Vector2i(cx, cy)
			if not _cells.has(k):
				continue
			
			var cell_array = _cells[k] as Array
			for node in cell_array:
				var n2d := node as Node2D
				if n2d and _query_pool_size < max_query_results:
					# Use squared distance to avoid sqrt
					var dist_sq = (n2d.global_position - center).length_squared()
					if dist_sq <= r2:
						_query_pool[_query_pool_size] = n2d
						_query_pool_size += 1
	
	# Return slice of actual results
	return _query_pool.slice(0, _query_pool_size)

# Optimized version that returns a pre-allocated array
func query_radius_fast(center: Vector2, radius: float) -> Array:
	_query_pool_size = 0
	
	var r: float = max(radius, 0.0)
	var min_cell := _key(center - Vector2(r, r), cell_size)
	var max_cell := _key(center + Vector2(r, r), cell_size)
	var r2 := r * r
	
	for cy in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			var k := Vector2i(cx, cy)
			if not _cells.has(k):
				continue
			
			var cell_array = _cells[k] as Array
			for node in cell_array:
				var n2d := node as Node2D
				if n2d and _query_pool_size < max_query_results:
					var dist_sq = (n2d.global_position - center).length_squared()
					if dist_sq <= r2:
						_query_pool[_query_pool_size] = n2d
						_query_pool_size += 1
	
	return _query_pool.slice(0, _query_pool_size)
