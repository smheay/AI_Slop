extends RefCounted
class_name OptimizedAIRunner

# Optimized AI runner for 5000+ entities
# Uses data-oriented design and LOD-based processing

signal ai_batch_started(count: int)
signal ai_batch_finished(ms: float)

var entity_data: EntityData
var lod_system: LODSystem
var player_position: Vector2 = Vector2.ZERO

# Pre-allocated arrays to avoid allocations
var _temp_targets: Array[Vector2] = []
var _temp_ai_states: Array[int] = []

# Performance settings
var batch_size: int = 64  # Reduced from 128 to 64
var max_entities_per_frame: int = 1000  # Reduced from 2000 to 1000
var ai_update_interval: float = 0.016  # 60 FPS default

func _init(entity_data_ref: EntityData, lod_system_ref: LODSystem) -> void:
	entity_data = entity_data_ref
	lod_system = lod_system_ref
	
	# Pre-allocate arrays
	_temp_targets.resize(1000)
	_temp_ai_states.resize(1000)

func run_batch(entities: Array[int], delta: float) -> void:
	if entities.is_empty():
		return
	
	emit_signal("ai_batch_started", entities.size())
	var start_time := Time.get_ticks_msec()
	
	# Process entities in optimized batches
	var processed := 0
	var total_entities := entities.size()
	
	while processed < total_entities and processed < max_entities_per_frame:
		var batch_end = min(processed + batch_size, total_entities)
		
		# Process batch
		_process_ai_batch(entities, processed, batch_end, delta)
		
		processed = batch_end
	
	var end_time := Time.get_ticks_msec()
	emit_signal("ai_batch_finished", end_time - start_time)

func _process_ai_batch(entities: Array[int], start_idx: int, end_idx: int, delta: float) -> void:
	for i in range(start_idx, end_idx):
		var entity_id = entities[i]
		
		# Check if entity should update AI this frame
		if not lod_system.should_update_ai(entity_id):
			# Debug: Log why entities are being skipped
			if entity_id < 5:
				Log.info("Entity %d AI SKIPPED: LOD says no update" % entity_id)
			continue
		
		# Get entity data
		var position = entity_data.get_entity_position(entity_id)
		var ai_state = entity_data.ai_states[entity_id]
		var move_speed = entity_data.move_speeds[entity_id]
		
		# Update AI based on LOD level
		var lod_level = lod_system.entity_lod_levels[entity_id]
		
			# Debug: Log LOD levels for first few entities
	if entity_id < 5:
		print("Entity %d: pos=%s, LOD=%d, should_update=%s" % [
			entity_id, 
			str(position), 
			lod_level, 
			str(lod_system.should_update_ai(entity_id))
		])
		
		_update_entity_ai(entity_id, position, ai_state, move_speed, lod_level, delta)

func _update_entity_ai(entity_id: int, position: Vector2, ai_state: int, move_speed: float, lod_level: int, delta: float) -> void:
	# Simple AI: move towards player
	var desired_velocity = Vector2.ZERO
	
	if lod_level <= LODSystem.LODLevel.MEDIUM:
		# High/Medium LOD: Full AI behavior
		desired_velocity = _compute_ai_velocity(position, ai_state, move_speed)
	elif lod_level == LODSystem.LODLevel.LOW:
		# Low LOD: Simplified AI (less frequent updates)
		if randf() < 0.1:  # 10% chance to update
			desired_velocity = _compute_simple_ai_velocity(position, move_speed)
	else:
		# Minimal LOD: No AI updates
		return
	
	# Ensure we have a non-zero velocity if player is reachable
	if desired_velocity.length_squared() < 0.1 and player_position.distance_squared_to(position) > 100.0:
		# Fallback: basic movement toward player
		var to_player = player_position - position
		if to_player.length_squared() > 0.1:
			desired_velocity = to_player.normalized() * move_speed * 0.5
	
	# Update entity data
	entity_data.set_entity_desired_velocity(entity_id, desired_velocity)
	
	# Debug log first entity occasionally
	if entity_id == 0 and randf() < 0.01:  # 1% chance for entity 0
		print("Entity 0 AI: pos=%s, player=%s, desired_vel=%s, LOD=%d" % [str(position), str(player_position), str(desired_velocity), lod_level])

func _compute_ai_velocity(position: Vector2, ai_state: int, move_speed: float) -> Vector2:
	# Basic AI: move towards player
	var to_player = player_position - position
	var distance = to_player.length()
	
	if distance > 0.1:
		var direction = to_player.normalized()
		
		# Add some randomness for more natural movement (reduced randomness)
		var random_offset = Vector2(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		direction += random_offset
		direction = direction.normalized()
		
		# Ensure minimum movement speed
		var final_speed = max(move_speed * 0.8, 50.0)  # At least 50 pixels/second
		
		return direction * final_speed
	
	return Vector2.ZERO

func _compute_simple_ai_velocity(position: Vector2, move_speed: float) -> Vector2:
	# Simplified AI for low LOD entities
	var to_player = player_position - position
	var distance = to_player.length()
	
	if distance > 50.0:  # Only move if far from player
		var direction = to_player.normalized()
		# Ensure minimum movement speed even for low LOD
		var final_speed = max(move_speed * 0.6, 40.0)  # At least 40 pixels/second
		return direction * final_speed
	
	return Vector2.ZERO

func set_player_position(pos: Vector2) -> void:
	player_position = pos
	lod_system.set_player_position(pos)

func get_performance_stats() -> Dictionary:
	return {
		"batch_size": batch_size,
		"max_entities_per_frame": max_entities_per_frame,
		"ai_update_interval": ai_update_interval
	}

func set_batch_size(size: int) -> void:
	batch_size = size

func set_max_entities_per_frame(max_entities: int) -> void:
	max_entities_per_frame = max_entities