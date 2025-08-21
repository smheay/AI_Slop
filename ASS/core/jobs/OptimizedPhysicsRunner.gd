extends RefCounted
class_name OptimizedPhysicsRunner

# Optimized physics runner for 5000+ entities
# Uses data-oriented design and efficient batch processing

signal physics_batch_started(count: int)
signal physics_batch_finished(ms: float)

var entity_data: EntityData
var spatial_hash: OptimizedSpatialHash
var lod_system: LODSystem

# Pre-allocated arrays to avoid allocations
var _temp_neighbors: Array[int] = []
var _temp_separation_forces: Array[Vector2] = []
var _temp_velocities: Array[Vector2] = []

# Performance settings
var batch_size: int = 64  # Reduced from 128 to 64
var max_entities_per_frame: int = 1000  # Reduced from 2000 to 1000
var separation_radius_multiplier: float = 1.5

func _init(entity_data_ref: EntityData, spatial_hash_ref: OptimizedSpatialHash, lod_system_ref: LODSystem) -> void:
	entity_data = entity_data_ref
	spatial_hash = spatial_hash_ref
	lod_system = lod_system_ref
	
	# Pre-allocate arrays
	_temp_neighbors.resize(32)  # Max neighbors per entity
	_temp_separation_forces.resize(32)
	_temp_velocities.resize(1000)

func integrate(entities: Array[int], delta: float) -> void:
	if entities.is_empty():
		return
	
	emit_signal("physics_batch_started", entities.size())
	var start_time := Time.get_ticks_msec()
	
	# Process entities in optimized batches
	var processed := 0
	var total_entities := entities.size()
	
	while processed < total_entities and processed < max_entities_per_frame:
		var batch_end = min(processed + batch_size, total_entities)
		
		# Process batch
		_process_physics_batch(entities, processed, batch_end, delta)
		
		processed = batch_end
	
	var end_time := Time.get_ticks_msec()
	emit_signal("physics_batch_finished", end_time - start_time)

func _process_physics_batch(entities: Array[int], start_idx: int, end_idx: int, delta: float) -> void:
	for i in range(start_idx, end_idx):
		var entity_id = entities[i]
		
		# Check if entity should be processed this frame
		if not lod_system.should_update_physics(entity_id):
					# Debug: Log why entities are being skipped
		if entity_id < 5:
			print("Entity %d PHYSICS SKIPPED: LOD says no update" % entity_id)
			continue
		
		# Get entity data
		var position = entity_data.get_entity_position(entity_id)
		var desired_velocity = entity_data.get_entity_desired_velocity(entity_id)
		var separation_radius = entity_data.separation_radii[entity_id]
		var separation_strength = entity_data.separation_strengths[entity_id]
		var hit_radius = entity_data.hit_radii[entity_id]
		var move_speed = entity_data.move_speeds[entity_id]
		
		# Compute separation forces
		var separation_force = _compute_separation_force(entity_id, position, separation_radius, hit_radius, separation_strength)
		
		# Combine desired velocity with separation
		var final_velocity = _combine_velocities(desired_velocity, separation_force, move_speed)
		
		# Apply movement
		var new_position = position + final_velocity * delta
		
		# Update entity data
		entity_data.set_entity_position(entity_id, new_position)
		entity_data.set_entity_velocity(entity_id, final_velocity)
		
		# Debug: Log position updates for first few entities
		if entity_id < 5:
			print("Entity %d PHYSICS: pos=%s, vel=%s, desired=%s" % [
				entity_id, str(new_position), str(final_velocity), str(desired_velocity)
			])
		
		# Update spatial hash
		spatial_hash.move_entity(entity_id, new_position)

func _compute_separation_force(entity_id: int, position: Vector2, separation_radius: float, hit_radius: float, separation_strength: float) -> Vector2:
	var total_force = Vector2.ZERO
	var neighbor_count = 0
	
	# Query nearby entities
	var query_radius = separation_radius * separation_radius_multiplier
	var neighbors = spatial_hash.query_radius(position, query_radius)
	
	# Process neighbors (limited to avoid excessive computation)
	var max_neighbors = 8
	for neighbor_id in neighbors:
		if neighbor_id == entity_id or neighbor_count >= max_neighbors:
			continue
		
		var neighbor_pos = entity_data.get_entity_position(neighbor_id)
		var neighbor_hit_radius = entity_data.hit_radii[neighbor_id]
		
		var to_entity = position - neighbor_pos
		var distance_sq = to_entity.length_squared()
		
		if distance_sq < 0.001:  # Avoid division by zero
			continue
		
		var min_separation = hit_radius + neighbor_hit_radius + 2.0
		var min_separation_sq = min_separation * min_separation
		
		if distance_sq < min_separation_sq:
			# Collision - strong repulsion
			var distance = sqrt(distance_sq)
			var penetration = (min_separation - distance) / max(min_separation, 0.001)
			var force = to_entity.normalized() * penetration * separation_strength * 2.0
			total_force += force
		elif distance_sq < query_radius * query_radius:
			# Near - gentle repulsion
			var distance = sqrt(distance_sq)
			var falloff = (query_radius - distance) / query_radius
			var force = to_entity.normalized() * falloff * separation_strength * 0.5
			total_force += force
		
		neighbor_count += 1
	
	return total_force

func _combine_velocities(desired: Vector2, separation: Vector2, max_speed: float) -> Vector2:
	var combined = desired + separation
	
	# Limit total velocity
	if combined.length_squared() > max_speed * max_speed:
		combined = combined.normalized() * max_speed
	
	return combined

func get_performance_stats() -> Dictionary:
	return {
		"batch_size": batch_size,
		"max_entities_per_frame": max_entities_per_frame,
		"separation_radius_multiplier": separation_radius_multiplier
	}

func set_batch_size(size: int) -> void:
	batch_size = size

func set_max_entities_per_frame(max_entities: int) -> void:
	max_entities_per_frame = max_entities