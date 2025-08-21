extends RefCounted
class_name OptimizedEntityManager

# Optimized entity manager for 5000+ entities
# Coordinates all optimized systems and provides clean interface

signal entity_count_changed(count: int)
signal performance_stats_updated(stats: Dictionary)

var entity_data: EntityData
var spatial_hash: OptimizedSpatialHash
var lod_system: LODSystem
var physics_runner: OptimizedPhysicsRunner
var ai_runner: OptimizedAIRunner

# Entity lifecycle
var active_entities: Array[int] = []
var entity_pool: Array[int] = []
var next_entity_id: int = 0
var max_entities: int = 10000

# Performance tracking
var frame_count: int = 0
var last_stats_update: float = 0.0
var performance_stats: Dictionary = {}

func _init(world_bounds: Rect2, max_entities_count: int = 10000) -> void:
	max_entities = max_entities_count
	
	# Initialize systems
	entity_data = EntityData.new(max_entities)
	spatial_hash = OptimizedSpatialHash.new(world_bounds, 64.0)
	lod_system = LODSystem.new()
	physics_runner = OptimizedPhysicsRunner.new(entity_data, spatial_hash, lod_system)
	ai_runner = OptimizedAIRunner.new(entity_data, lod_system)
	
	# Pre-allocate entity pool
	entity_pool.resize(max_entities)
	for i in range(max_entities):
		entity_pool[i] = i

func create_entity(position: Vector2, properties: Dictionary = {}) -> int:
	if entity_pool.is_empty():
		# Expand capacity
		max_entities *= 2
		_expand_capacity()
	
	var entity_id = entity_pool.pop_back()
	
	# Initialize entity data
	entity_data.set_entity_position(entity_id, position)
	entity_data.set_entity_velocity(entity_id, Vector2.ZERO)
	entity_data.set_entity_desired_velocity(entity_id, Vector2.ZERO)
	
	# Set custom properties
	if properties.has("move_speed"):
		entity_data.move_speeds[entity_id] = properties.move_speed
	if properties.has("separation_radius"):
		entity_data.separation_radii[entity_id] = properties.separation_radius
	if properties.has("separation_strength"):
		entity_data.separation_strengths[entity_id] = properties.separation_strength
	if properties.has("hit_radius"):
		entity_data.hit_radii[entity_id] = properties.hit_radius
	
	# Debug: Log entity creation for first few entities
	if entity_id < 5:
		print("Entity %d CREATED: pos=%s, props=%s" % [entity_id, str(position), str(properties)])
	
	# Add to spatial hash
	spatial_hash.insert_entity(entity_id, position)
	
	# Add to active entities
	active_entities.append(entity_id)
	
	# Update LOD
	lod_system.update_entity_lod(entity_id, position, Time.get_unix_time_from_system())
	
	emit_signal("entity_count_changed", active_entities.size())
	return entity_id

func destroy_entity(entity_id: int) -> void:
	if not is_valid_entity(entity_id):
		return
	
	# Remove from spatial hash
	spatial_hash.remove_entity(entity_id)
	
	# Remove from active entities
	active_entities.erase(entity_id)
	
	# Return to pool
	entity_pool.append(entity_id)
	
	emit_signal("entity_count_changed", active_entities.size())

func is_valid_entity(entity_id: int) -> bool:
	return entity_id >= 0 and entity_id < max_entities and active_entities.has(entity_id)

func update_simulation(delta: float) -> void:
	frame_count += 1
	
	# Update LOD for all entities
	_update_entity_lods()
	
	# Run AI updates
	ai_runner.run_batch(active_entities, delta)
	
	# Run physics updates
	physics_runner.integrate(active_entities, delta)
	
	# Update performance stats periodically
	if frame_count % 60 == 0:  # Every 60 frames
		_update_performance_stats()

func _update_entity_lods() -> void:
	var current_time = Time.get_unix_time_from_system()
	
	for entity_id in active_entities:
		var position = entity_data.get_entity_position(entity_id)
		lod_system.update_entity_lod(entity_id, position, current_time)

func set_player_position(position: Vector2) -> void:
	# Update player position for AI and LOD systems
	lod_system.set_player_position(position)
	ai_runner.set_player_position(position)

func _get_player_position() -> Vector2:
	# Player position is set by the OptimizedSystemsRunner
	# This is a fallback that should be updated by set_player_position()
	return lod_system.player_position

func _expand_capacity() -> void:
	# Expand entity data arrays
	entity_data.max_entities = max_entities
	entity_data._resize_arrays()
	
	# Expand LOD system arrays
	lod_system._expand_arrays(max_entities)
	
	# Expand spatial hash if needed
	# Note: Spatial hash doesn't need expansion as it's dynamic

func get_entity_position(entity_id: int) -> Vector2:
	if is_valid_entity(entity_id):
		return entity_data.get_entity_position(entity_id)
	return Vector2.ZERO

func set_entity_position(entity_id: int, position: Vector2) -> void:
	if is_valid_entity(entity_id):
		entity_data.set_entity_position(entity_id, position)
		spatial_hash.move_entity(entity_id, position)

func get_entity_velocity(entity_id: int) -> Vector2:
	if is_valid_entity(entity_id):
		return entity_data.get_entity_velocity(entity_id)
	return Vector2.ZERO

func get_active_entities() -> Array[int]:
	return active_entities.duplicate()

func get_entity_count() -> int:
	return active_entities.size()

func get_neighbors(entity_id: int, radius: float) -> Array[int]:
	if not is_valid_entity(entity_id):
		return []
	
	var position = entity_data.get_entity_position(entity_id)
	return spatial_hash.query_radius(position, radius)

func get_entities_near_position(position: Vector2, radius: float) -> Array[int]:
	# Query spatial hash directly by position (useful for spawn position checking)
	return spatial_hash.query_radius(position, radius)

func _update_performance_stats() -> void:
	var stats = {
		"entity_count": active_entities.size(),
		"max_entities": max_entities,
		"frame_count": frame_count,
		"lod_stats": lod_system.get_lod_stats(),
		"spatial_hash_stats": spatial_hash.get_stats(),
		"physics_stats": physics_runner.get_performance_stats(),
		"ai_stats": ai_runner.get_performance_stats()
	}
	
	performance_stats = stats
	emit_signal("performance_stats_updated", stats)

func get_performance_stats() -> Dictionary:
	return performance_stats

func clear_all_entities() -> void:
	for entity_id in active_entities.duplicate():
		destroy_entity(entity_id)
	
	active_entities.clear()
	spatial_hash.clear()
	lod_system.reset_stats()
	
	emit_signal("entity_count_changed", 0)
