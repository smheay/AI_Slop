extends RefCounted
class_name OptimizedSpatialHash

# Optimized spatial hash for 5000+ entities
# Uses grid-based partitioning with minimal allocations

var cell_size: float = 64.0
var grid_width: int = 0
var grid_height: int = 0
var world_bounds: Rect2

# Grid data structure
var grid: Array[Array] = []  # 2D array of entity ID lists
var entity_cells: Array[Vector2i] = []  # Current cell for each entity
var entity_indices: Array[int] = []  # Index within cell for each entity

# Pre-allocated arrays to avoid allocations
var _temp_entities: Array[int] = []
var _temp_cells: Array[Vector2i] = []
var _query_results: Array[int] = []

func _init(world_bounds_rect: Rect2, cell_size_pixels: float = 64.0) -> void:
	world_bounds = world_bounds_rect
	cell_size = cell_size_pixels
	
	# Calculate grid dimensions
	grid_width = int(ceil(world_bounds.size.x / cell_size)) + 2
	grid_height = int(ceil(world_bounds.size.y / cell_size)) + 2
	
	# Initialize grid
	grid.resize(grid_width)
	for x in range(grid_width):
		grid[x] = []
		grid[x].resize(grid_height)
		for y in range(grid_height):
			grid[x][y] = []

func world_to_cell(pos: Vector2) -> Vector2i:
	var x = int(floor((pos.x - world_bounds.position.x) / cell_size))
	var y = int(floor((pos.y - world_bounds.position.y) / cell_size))
	return Vector2i(clamp(x, 0, grid_width - 1), clamp(y, 0, grid_height - 1))

func insert_entity(entity_id: int, position: Vector2) -> void:
	var cell = world_to_cell(position)
	
	# Ensure entity arrays are large enough
	if entity_id >= entity_cells.size():
		entity_cells.resize(entity_id + 1)
		entity_indices.resize(entity_id + 1)
	
	# Remove from old cell if exists
	if entity_id < entity_cells.size() and entity_cells[entity_id] != Vector2i(-1, -1):
		_remove_from_cell(entity_id, entity_cells[entity_id])
	
	# Add to new cell
	entity_cells[entity_id] = cell
	entity_indices[entity_id] = grid[cell.x][cell.y].size()
	grid[cell.x][cell.y].append(entity_id)

func remove_entity(entity_id: int) -> void:
	if entity_id >= entity_cells.size():
		return
	
	var cell = entity_cells[entity_id]
	if cell == Vector2i(-1, -1):
		return
	
	_remove_from_cell(entity_id, cell)
	entity_cells[entity_id] = Vector2i(-1, -1)
	entity_indices[entity_id] = -1

func move_entity(entity_id: int, new_position: Vector2) -> void:
	var new_cell = world_to_cell(new_position)
	var old_cell = entity_cells[entity_id] if entity_id < entity_cells.size() else Vector2i(-1, -1)
	
	if new_cell == old_cell:
		return
	
	# Remove from old cell
	if old_cell != Vector2i(-1, -1):
		_remove_from_cell(entity_id, old_cell)
	
	# Add to new cell
	entity_cells[entity_id] = new_cell
	entity_indices[entity_id] = grid[new_cell.x][new_cell.y].size()
	grid[new_cell.x][new_cell.y].append(entity_id)

func _remove_from_cell(entity_id: int, cell: Vector2i) -> void:
	if cell.x < 0 or cell.x >= grid_width or cell.y < 0 or cell.y >= grid_height:
		return
	
	var cell_list = grid[cell.x][cell.y]
	var index = entity_indices[entity_id]
	
	if index >= 0 and index < cell_list.size():
		# Swap with last element and update index
		var last_id = cell_list[cell_list.size() - 1]
		cell_list[index] = last_id
		cell_list.resize(cell_list.size() - 1)
		
		# Update the swapped entity's index
		if last_id != entity_id:
			entity_indices[last_id] = index

func query_radius(center: Vector2, radius: float) -> Array[int]:
	_query_results.clear()
	
	var center_cell = world_to_cell(center)
	var radius_cells = int(ceil(radius / cell_size))
	var radius_sq = radius * radius
	
	# Pre-allocate temp array
	_temp_cells.clear()
	_temp_cells.resize((radius_cells * 2 + 1) * (radius_cells * 2 + 1))
	var cell_count = 0
	
	# Collect cells to check
	for dx in range(-radius_cells, radius_cells + 1):
		for dy in range(-radius_cells, radius_cells + 1):
			var cell_x = center_cell.x + dx
			var cell_y = center_cell.y + dy
			
			if cell_x >= 0 and cell_x < grid_width and cell_y >= 0 and cell_y < grid_height:
				_temp_cells[cell_count] = Vector2i(cell_x, cell_y)
				cell_count += 1
	
	# Query entities in collected cells
	for i in range(cell_count):
		var cell = _temp_cells[i]
		var cell_list = grid[cell.x][cell.y]
		
		for entity_id in cell_list:
			# Get entity position from external data (passed in)
			# This avoids storing positions in the spatial hash
			if _is_entity_in_radius(entity_id, center, radius_sq):
				_query_results.append(entity_id)
	
	return _query_results

func _is_entity_in_radius(entity_id: int, center: Vector2, radius_sq: float) -> bool:
	# This should be implemented by the caller with access to entity positions
	# For now, return true - the caller will filter by actual distance
	return true

func get_entity_cell(entity_id: int) -> Vector2i:
	if entity_id < entity_cells.size():
		return entity_cells[entity_id]
	return Vector2i(-1, -1)

func clear() -> void:
	for x in range(grid_width):
		for y in range(grid_height):
			grid[x][y].clear()
	
	entity_cells.clear()
	entity_indices.clear()

func get_stats() -> Dictionary:
	var total_entities = 0
	var max_cell_size = 0
	var empty_cells = 0
	
	for x in range(grid_width):
		for y in range(grid_height):
			var cell_size = grid[x][y].size()
			total_entities += cell_size
			max_cell_size = max(max_cell_size, cell_size)
			if cell_size == 0:
				empty_cells += 1
	
	return {
		"total_entities": total_entities,
		"max_cell_size": max_cell_size,
		"empty_cells": empty_cells,
		"total_cells": grid_width * grid_height,
		"cell_size_pixels": cell_size
	}