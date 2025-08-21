extends RefCounted
class_name EntityData

# Data-oriented design: all entity data stored in contiguous arrays
# This eliminates node traversal and enables SIMD-friendly operations

# Entity identifiers
var entity_ids: Array[int] = []
var active_mask: Array[bool] = []
var entity_count: int = 0
var max_entities: int = 10000

# Transform data (contiguous for cache efficiency)
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var desired_velocities: Array[Vector2] = []

# Movement properties
var move_speeds: Array[float] = []
var separation_radii: Array[float] = []
var separation_strengths: Array[float] = []
var hit_radii: Array[float] = []

# AI state
var ai_states: Array[int] = []
var target_positions: Array[Vector2] = []
var last_ai_update: Array[float] = []

# LOD and culling
var lod_levels: Array[int] = []
var cull_distances: Array[float] = []
var is_visible: Array[bool] = []

# Spatial hash data
var spatial_cells: Array[Vector2i] = []
var spatial_indices: Array[int] = []

func _init(max_entities_count: int = 10000) -> void:
	max_entities = max_entities_count
	_resize_arrays()

func _resize_arrays() -> void:
	entity_ids.resize(max_entities)
	active_mask.resize(max_entities)
	positions.resize(max_entities)
	velocities.resize(max_entities)
	desired_velocities.resize(max_entities)
	move_speeds.resize(max_entities)
	separation_radii.resize(max_entities)
	separation_strengths.resize(max_entities)
	hit_radii.resize(max_entities)
	ai_states.resize(max_entities)
	target_positions.resize(max_entities)
	last_ai_update.resize(max_entities)
	lod_levels.resize(max_entities)
	cull_distances.resize(max_entities)
	is_visible.resize(max_entities)
	spatial_cells.resize(max_entities)
	spatial_indices.resize(max_entities)

func create_entity() -> int:
	if entity_count >= max_entities:
		# Expand arrays if needed
		max_entities = max_entities * 2
		_resize_arrays()
	
	var id = entity_count
	entity_count += 1
	
	# Initialize with default values
	active_mask[id] = true
	positions[id] = Vector2.ZERO
	velocities[id] = Vector2.ZERO
	desired_velocities[id] = Vector2.ZERO
	move_speeds[id] = 120.0
	separation_radii[id] = 24.0
	separation_strengths[id] = 80.0
	hit_radii[id] = 12.0
	ai_states[id] = 0
	target_positions[id] = Vector2.ZERO
	last_ai_update[id] = 0.0
	lod_levels[id] = 0
	cull_distances[id] = 1000.0
	is_visible[id] = true
	spatial_cells[id] = Vector2i.ZERO
	spatial_indices[id] = id
	
	entity_ids.append(id)
	return id

func destroy_entity(id: int) -> void:
	if not is_valid_entity(id):
		return
	
	# Mark as inactive
	active_mask[id] = false
	
	# Move last active entity to this slot to maintain contiguity
	if id < entity_count - 1:
		_copy_entity_data(entity_count - 1, id)
		# Update the moved entity's index
		spatial_indices[entity_count - 1] = id
	
	entity_count -= 1

func is_valid_entity(id: int) -> bool:
	return id >= 0 and id < entity_count and active_mask[id]

func _copy_entity_data(from_id: int, to_id: int) -> void:
	positions[to_id] = positions[from_id]
	velocities[to_id] = velocities[from_id]
	desired_velocities[to_id] = desired_velocities[from_id]
	move_speeds[to_id] = move_speeds[from_id]
	separation_radii[to_id] = separation_radii[from_id]
	separation_strengths[to_id] = separation_strengths[from_id]
	hit_radii[to_id] = hit_radii[from_id]
	ai_states[to_id] = ai_states[from_id]
	target_positions[to_id] = target_positions[from_id]
	last_ai_update[to_id] = last_ai_update[from_id]
	lod_levels[to_id] = lod_levels[from_id]
	cull_distances[to_id] = cull_distances[from_id]
	is_visible[to_id] = is_visible[from_id]
	spatial_cells[to_id] = spatial_cells[from_id]
	spatial_indices[to_id] = to_id

func get_active_entities() -> Array[int]:
	var active: Array[int] = []
	active.resize(entity_count)
	var count = 0
	
	for i in range(entity_count):
		if active_mask[i]:
			active[count] = i
			count += 1
	
	active.resize(count)
	return active

func get_entity_position(id: int) -> Vector2:
	if is_valid_entity(id):
		return positions[id]
	return Vector2.ZERO

func set_entity_position(id: int, pos: Vector2) -> void:
	if is_valid_entity(id):
		positions[id] = pos

func get_entity_velocity(id: int) -> Vector2:
	if is_valid_entity(id):
		return velocities[id]
	return Vector2.ZERO

func set_entity_velocity(id: int, vel: Vector2) -> void:
	if is_valid_entity(id):
		velocities[id] = vel

func get_entity_desired_velocity(id: int) -> Vector2:
	if is_valid_entity(id):
		return desired_velocities[id]
	return Vector2.ZERO

func set_entity_desired_velocity(id: int, vel: Vector2) -> void:
	if is_valid_entity(id):
		desired_velocities[id] = vel