extends Node
class_name OptimizedSystemsRunner

# Optimized systems runner for 5000+ entities
# Coordinates all optimized systems with minimal overhead

signal systems_ready
signal performance_updated(stats: Dictionary)

var entity_manager: OptimizedEntityManager
var spawner: OptimizedSpawner
var entity_renderer: EntityRenderer
var world_bounds: Rect2

# Performance monitoring
var frame_count: int = 0
var last_performance_update: float = 0.0
var performance_history: Array[Dictionary] = []

# Configuration
var target_fps: int = 60
var max_entities: int = 10000
var world_size: Vector2 = Vector2(2048, 2048)

func _ready() -> void:
	# Initialize world bounds
	world_bounds = Rect2(-world_size * 0.5, world_size)
	
	# Create entity manager
	entity_manager = OptimizedEntityManager.new(world_bounds, max_entities)
	
	# Create spawner
	_create_spawner()
	
	# Create entity renderer
	_create_entity_renderer()
	
	# Connect signals
	entity_manager.performance_stats_updated.connect(_on_performance_updated)
	
	# Start systems
	set_physics_process(true)
	
	emit_signal("systems_ready")
	print("OptimizedSystemsRunner: Ready with capacity for %d entities" % max_entities)

func _create_spawner() -> void:
	# Create spawner as child node
	spawner = OptimizedSpawner.new()
	spawner.name = "OptimizedSpawner"
	spawner.entity_manager = entity_manager
	spawner.max_alive = max_entities
	spawner.spawn_rate = 10.0   # Reasonable spawn rate for testing
	add_child(spawner)

func _create_entity_renderer() -> void:
	# Create entity renderer as child node
	entity_renderer = EntityRenderer.new()
	entity_renderer.name = "EntityRenderer"
	entity_renderer.set_entity_manager(entity_manager)
	add_child(entity_renderer)

func _physics_process(delta: float) -> void:
	frame_count += 1
	
	# Update entity simulation
	if entity_manager:
		# Update player position
		var player_pos = _get_player_position()
		entity_manager.set_player_position(player_pos)
		
		# Debug log player position occasionally
		if frame_count % 300 == 0:
			print("Player position: %s, Entities: %d" % [str(player_pos), entity_manager.get_entity_count()])
		
		# Update simulation
		entity_manager.update_simulation(delta)
	
	# Update performance monitoring
	if frame_count % 60 == 0:  # Every 60 frames
		_update_performance_monitoring()

func _get_player_position() -> Vector2:
	# Get the actual player position from the scene tree
	var player = get_tree().get_first_node_in_group("player")
	if player and player is Node2D:
		return player.global_position
	# Fallback to default position if no player found
	return Vector2(512, 512)

func _update_performance_monitoring() -> void:
	var current_time = Time.get_unix_time_from_system()
	
	# Get current performance stats
	var stats = entity_manager.get_performance_stats()
	stats.frame_count = frame_count
	stats.fps = Engine.get_frames_per_second()
	stats.memory_usage = OS.get_static_memory_usage()
	
	# Store in history (keep last 100 entries)
	performance_history.append(stats)
	if performance_history.size() > 100:
		performance_history.pop_front()
	
	# Emit performance update
	emit_signal("performance_updated", stats)
	
			# Log performance every 5 seconds
		if frame_count % 300 == 0:
			print("Performance: %d entities, %d FPS, %d MB memory" % [
				stats.entity_count,
				stats.fps,
				stats.memory_usage / 1024 / 1024
			])
			
			# Also log spawner info
			if spawner:
				print("Spawner: Rate %.1f, Max Alive %d, Current %d" % [
					spawner.spawn_rate,
					spawner.max_alive,
					entity_manager.get_entity_count() if entity_manager else 0
				])
			
			# Log LOD stats
			if entity_manager and stats.has("lod_stats"):
				var lod_stats = stats.lod_stats
				print("LOD: High=%d, Med=%d, Low=%d, Min=%d" % [
					lod_stats.get("high_detail", 0),
					lod_stats.get("medium_detail", 0),
					lod_stats.get("low_detail", 0),
					lod_stats.get("minimal_detail", 0)
				])

func _on_performance_updated(stats: Dictionary) -> void:
	# Handle performance updates
	pass

func get_entity_count() -> int:
	if entity_manager:
		return entity_manager.get_entity_count()
	return 0

func get_performance_stats() -> Dictionary:
	if entity_manager:
		return entity_manager.get_performance_stats()
	return {}

func get_entity_positions() -> Array[Vector2]:
	if not entity_manager:
		return []
	
	var positions: Array[Vector2] = []
	var entities = entity_manager.get_active_entities()
	
	for entity_id in entities:
		var pos = entity_manager.get_entity_position(entity_id)
		positions.append(pos)
	
	return positions

func spawn_entities(count: int) -> void:
	if not spawner:
		return
	
	# Temporarily increase spawn rate for burst spawning
	var original_rate = spawner.spawn_rate
	spawner.spawn_rate = count * 5.0  # Spawn quickly but not too fast
	
	# Let the spawner handle it naturally
	# The spawner will respect max_alive limit
	
	print("OptimizedSystemsRunner: Requested spawn of %d entities" % count)

func clear_all_entities() -> void:
	if entity_manager:
		entity_manager.clear_all_entities()
	if entity_renderer:
		entity_renderer.clear_all_sprites()

func set_spawn_rate(rate: float) -> void:
	if spawner:
		spawner.spawn_rate = rate

func set_max_entities(max_count: int) -> void:
	max_entities = max_count
	if entity_manager:
		# Note: This would require reinitializing the entity manager
		# For now, just update the spawner
		if spawner:
			spawner.max_alive = max_count

func get_system_status() -> Dictionary:
	return {
		"entity_manager_ready": entity_manager != null,
		"spawner_ready": spawner != null,
		"entity_renderer_ready": entity_renderer != null,
		"max_entities": max_entities,
		"current_entities": entity_manager.get_entity_count() if entity_manager else 0,
		"spawn_rate": spawner.spawn_rate if spawner else 0.0,
		"world_bounds": world_bounds,
		"frame_count": frame_count
	}

func _exit_tree() -> void:
	# Cleanup
	if entity_manager:
		entity_manager.clear_all_entities()
