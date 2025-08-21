extends RefCounted
class_name LODSystem

# Level of Detail system for managing 5000+ entities efficiently
# Processes entities at different detail levels based on distance and importance

enum LODLevel {
	HIGH = 0,      # Full AI + physics + rendering (close entities)
	MEDIUM = 1,    # Simplified AI + physics + rendering (medium distance)
	LOW = 2,       # Basic physics only + minimal rendering (far entities)
	MINIMAL = 3    # Position update only + culled rendering (very far)
}

# LOD configuration
var lod_distances: Array[float] = [200.0, 400.0, 800.0, 1600.0]
var lod_update_intervals: Array[float] = [0.016, 0.032, 0.064, 0.128]  # seconds
var player_position: Vector2 = Vector2.ZERO

# Entity LOD data
var entity_lod_levels: Array[int] = []
var entity_last_updates: Array[float] = []
var entity_distances: Array[float] = []

# Performance tracking
var entities_per_lod: Array[int] = [0, 0, 0, 0]
var last_stats_update: float = 0.0

func _init() -> void:
	# Initialize LOD arrays
	entity_lod_levels.resize(10000)
	entity_last_updates.resize(10000)
	entity_distances.resize(10000)
	
	# Set default values
	for i in range(10000):
		entity_lod_levels[i] = LODLevel.HIGH
		entity_last_updates[i] = 0.0
		entity_distances[i] = 0.0

func update_entity_lod(entity_id: int, position: Vector2, current_time: float) -> int:
	if entity_id >= entity_distances.size():
		# Expand arrays if needed
		_expand_arrays(entity_id + 1)
	
	# Calculate distance to player
	var distance = position.distance_to(player_position)
	entity_distances[entity_id] = distance
	
	# Determine LOD level based on distance
	var new_lod = LODLevel.HIGH
	for i in range(lod_distances.size()):
		if distance > lod_distances[i]:
			new_lod = i + 1
	
	# Update LOD level if changed
	if entity_lod_levels[entity_id] != new_lod:
		entities_per_lod[entity_lod_levels[entity_id]] = max(0, entities_per_lod[entity_lod_levels[entity_id]] - 1)
		entity_lod_levels[entity_id] = new_lod
		entities_per_lod[new_lod] += 1
	
	# Check if entity should be updated this frame
	var update_interval = lod_update_intervals[new_lod]
	if current_time - entity_last_updates[entity_id] >= update_interval:
		entity_last_updates[entity_id] = current_time
		return new_lod
	
	return -1  # No update needed

func should_update_ai(entity_id: int) -> bool:
	if entity_id >= entity_lod_levels.size():
		return false
	return entity_lod_levels[entity_id] <= LODLevel.MEDIUM

func should_update_physics(entity_id: int) -> bool:
	if entity_id >= entity_lod_levels.size():
		return false
	return entity_lod_levels[entity_id] <= LODLevel.LOW

func should_update_rendering(entity_id: int) -> bool:
	if entity_id >= entity_lod_levels.size():
		return false
	return entity_lod_levels[entity_id] <= LODLevel.MEDIUM

func get_ai_update_interval(entity_id: int) -> float:
	if entity_id >= entity_lod_levels.size():
		return 0.016
	return lod_update_intervals[entity_lod_levels[entity_id]]

func get_physics_update_interval(entity_id: int) -> float:
	if entity_id >= entity_lod_levels.size():
		return 0.016
	return lod_update_intervals[entity_lod_levels[entity_id]]

func set_player_position(pos: Vector2) -> void:
	player_position = pos

func get_entities_for_lod(lod_level: int) -> Array[int]:
	var entities: Array[int] = []
	entities.resize(entities_per_lod[lod_level])
	var count = 0
	
	# This would need to be called with the actual entity data
	# For now, return empty array
	return entities

func get_lod_stats() -> Dictionary:
	return {
		"high_detail": entities_per_lod[LODLevel.HIGH],
		"medium_detail": entities_per_lod[LODLevel.MEDIUM],
		"low_detail": entities_per_lod[LODLevel.LOW],
		"minimal_detail": entities_per_lod[LODLevel.MINIMAL],
		"total_entities": entities_per_lod[LODLevel.HIGH] + entities_per_lod[LODLevel.MEDIUM] + entities_per_lod[LODLevel.LOW] + entities_per_lod[LODLevel.MINIMAL]
	}

func _expand_arrays(new_size: int) -> void:
	var old_size = entity_lod_levels.size()
	entity_lod_levels.resize(new_size)
	entity_last_updates.resize(new_size)
	entity_distances.resize(new_size)
	
	# Initialize new elements
	for i in range(old_size, new_size):
		entity_lod_levels[i] = LODLevel.HIGH
		entity_last_updates[i] = 0.0
		entity_distances[i] = 0.0

func reset_stats() -> void:
	for i in range(entities_per_lod.size()):
		entities_per_lod[i] = 0