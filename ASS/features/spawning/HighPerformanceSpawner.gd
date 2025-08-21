extends Node
class_name HighPerformanceSpawner

signal spawn_completed(count: int)
signal spawn_batch_started(batch_size: int)

@export var enemy_scene: PackedScene
@export var max_enemies: int = 5000
@export var spawn_batch_size: int = 100
@export var spawn_interval: float = 0.1  # Spawn every 100ms
@export var use_object_pooling: bool = true
@export var enable_lod: bool = true

# Enemy size distribution for variety
@export var tiny_enemy_chance: float = 0.4    # 40% tiny enemies
@export var small_enemy_chance: float = 0.3   # 30% small enemies  
@export var medium_enemy_chance: float = 0.2  # 20% medium enemies
@export var large_enemy_chance: float = 0.08  # 8% large enemies
@export var huge_enemy_chance: float = 0.02   # 2% huge enemies

# Performance settings
@export var lod_distance_near: float = 200.0
@export var lod_distance_far: float = 800.0
@export var max_spawns_per_frame: int = 50

var _spawn_timer: float = 0.0
var _current_enemy_count: int = 0
var _spawn_queue: Array[Dictionary] = []
var _object_pool: ObjectPool
var _agent_sim: AgentSim
var _hierarchical_collision: HierarchicalCollision

# Spawn area bounds
var _spawn_bounds: Rect2 = Rect2(-1000, -1000, 2000, 2000)
var _camera: Camera2D

func _ready() -> void:
	# Find required systems
	_agent_sim = get_node_or_null("../AgentSim") as AgentSim
	_hierarchical_collision = get_node_or_null("../HierarchicalCollision") as HierarchicalCollision
	_object_pool = get_node_or_null("../ObjectPool") as ObjectPool
	
	# Find camera for LOD calculations
	_camera = get_tree().get_first_node_in_group("camera") as Camera2D
	if not _camera:
		_camera = get_tree().current_scene.get_node_or_null("Camera2D") as Camera2D
	
	# Initialize spawn queue
	_initialize_spawn_queue()

func _process(delta: float) -> void:
	_spawn_timer += delta
	
	# Spawn enemies at intervals
	if _spawn_timer >= spawn_interval and _current_enemy_count < max_enemies:
		_spawn_timer = 0.0
		_spawn_batch()

func _initialize_spawn_queue() -> void:
	# Pre-generate spawn positions and enemy types
	var spawn_count = 0
	while spawn_count < max_enemies:
		var spawn_data = _generate_spawn_data()
		_spawn_queue.append(spawn_data)
		spawn_count += 1

func _generate_spawn_data() -> Dictionary:
	# Random position within spawn bounds
	var pos = Vector2(
		randf_range(_spawn_bounds.position.x, _spawn_bounds.end.x),
		randf_range(_spawn_bounds.position.y, _spawn_bounds.end.y)
	)
	
	# Random enemy size based on distribution
	var enemy_size = _get_random_enemy_size()
	
	# Random target position (could be player position)
	var target = Vector2(
		randf_range(-500, 500),
		randf_range(-500, 500)
	)
	
	return {
		"position": pos,
		"size": enemy_size,
		"target": target,
		"spawned": false
	}

func _get_random_enemy_size() -> HierarchicalCollision.EnemySize:
	var rand_val = randf()
	var cumulative = 0.0
	
	cumulative += tiny_enemy_chance
	if rand_val < cumulative:
		return HierarchicalCollision.EnemySize.TINY
	
	cumulative += small_enemy_chance
	if rand_val < cumulative:
		return HierarchicalCollision.EnemySize.SMALL
	
	cumulative += medium_enemy_chance
	if rand_val < cumulative:
		return HierarchicalCollision.EnemySize.MEDIUM
	
	cumulative += large_enemy_chance
	if rand_val < cumulative:
		return HierarchicalCollision.EnemySize.LARGE
	
	return HierarchicalCollision.EnemySize.HUGE

func _spawn_batch() -> void:
	if _spawn_queue.is_empty() or _current_enemy_count >= max_enemies:
		return
	
	emit_signal("spawn_batch_started", min(spawn_batch_size, _spawn_queue.size()))
	
	var spawned_this_batch = 0
	var frame_spawns = 0
	
	for i in range(min(spawn_batch_size, _spawn_queue.size())):
		if _current_enemy_count >= max_enemies:
			break
		
		var spawn_data = _spawn_queue[i]
		if spawn_data.spawned:
			continue
		
		# Limit spawns per frame for performance
		if frame_spawns >= max_spawns_per_frame:
			break
		
		if _spawn_single_enemy(spawn_data):
			spawned_this_batch += 1
			frame_spawns += 1
			spawn_data.spawned = true
	
	if spawned_this_batch > 0:
		emit_signal("spawn_completed", spawned_this_batch)

func _spawn_single_enemy(spawn_data: Dictionary) -> bool:
	var enemy: BaseEnemy
	
	# Use object pooling if available
	if use_object_pooling and _object_pool:
		enemy = _object_pool.get_instance() as BaseEnemy
		if not enemy:
			return false
	else:
		# Direct instantiation
		enemy = enemy_scene.instantiate() as BaseEnemy
		if not enemy:
			return false
		add_child(enemy)
	
	# Configure enemy based on size
	_configure_enemy(enemy, spawn_data)
	
	# Register with agent simulation
	if _agent_sim:
		_agent_sim.register_agent(enemy)
	
	_current_enemy_count += 1
	return true

func _configure_enemy(enemy: BaseEnemy, spawn_data: Dictionary) -> void:
	# Set position and target
	enemy.global_position = spawn_data.position
	enemy.set_target(spawn_data.target)
	
	# Configure based on size
	var size = spawn_data.size
	match size:
		HierarchicalCollision.EnemySize.TINY:
			enemy._self_hit_radius = 25.0
			enemy.move_speed = 80.0
			enemy.set_lod_level(2)  # Lower LOD for tiny enemies
		HierarchicalCollision.EnemySize.SMALL:
			enemy._self_hit_radius = 50.0
			enemy.move_speed = 100.0
			enemy.set_lod_level(1)
		HierarchicalCollision.EnemySize.MEDIUM:
			enemy._self_hit_radius = 100.0
			enemy.move_speed = 120.0
			enemy.set_lod_level(1)
		HierarchicalCollision.EnemySize.LARGE:
			enemy._self_hit_radius = 200.0
			enemy.move_speed = 80.0  # Slower but stronger
			enemy.set_lod_level(0)   # High LOD for large enemies
		HierarchicalCollision.EnemySize.HUGE:
			enemy._self_hit_radius = 400.0
			enemy.move_speed = 60.0  # Very slow but powerful
			enemy.set_lod_level(0)   # Always high LOD

# Update LOD levels based on camera distance
func update_lod_levels() -> void:
	if not enable_lod or not _camera:
		return
	
	var camera_pos = _camera.global_position
	
	for child in get_children():
		var enemy = child as BaseEnemy
		if not enemy:
			continue
		
		var distance = camera_pos.distance_to(enemy.global_position)
		var new_lod = _calculate_lod_level(distance, enemy._self_hit_radius)
		enemy.set_lod_level(new_lod)

func _calculate_lod_level(distance: float, hit_radius: float) -> int:
	# Larger enemies get higher LOD priority
	var size_factor = hit_radius / 100.0  # Normalize to 100 units
	
	if distance < lod_distance_near:
		return 0  # High LOD
	elif distance < lod_distance_far:
		return 1  # Medium LOD
	else:
		# Far enemies get LOD based on size
		return max(1, int(3 - size_factor))

# Get current enemy count
func get_enemy_count() -> int:
	return _current_enemy_count

# Get spawn progress
func get_spawn_progress() -> float:
	return float(_current_enemy_count) / float(max_enemies)

# Clear all enemies (for testing/reset)
func clear_all_enemies() -> void:
	for child in get_children():
		if child is BaseEnemy:
			child.queue_free()
	
	_current_enemy_count = 0
	
	# Reset spawn queue
	for spawn_data in _spawn_queue:
		spawn_data.spawned = false