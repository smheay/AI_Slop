extends Node2D
class_name Spawner

signal spawned(node: Node)

@export var spawn_scene: PackedScene
@export var group_tag: StringName = "enemies"
@export var spawn_radius: float = 1024.0
@export var spawn_rate: float = 51.0        # enemies per second (continuous, not bursty)
@export var max_alive: int = 1000
@export var spawn_burst: int = 50          # enemies per spawn tick
@export var min_spawn_gap: float = 48.0      # clearance radius between spawns
@export var max_per_tick: int = 24           # cap spawns per physics frame
@export var max_spawn_attempts: int = 10     # attempts to find a clear spot
@export var use_batch_spawning: bool = true  # Enable batch spawn operations
@export var spawn_grid_size: float = 64.0    # Grid size for spawn position optimization

var _alive: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()
var _count_label: Label
var _enemy_pool: ObjectPool
var _spatial_hash: SpatialHash2D
var _spawn_positions: Array[Vector2] = []
var _spawn_position_index: int = 0
var _agent_sim: AgentSim  # Reference to AgentSim for enemy registration

var _spawn_accum: float = 0.0
var _last_ui_count := -1

func _ready() -> void:
	_rng.randomize()
	
	# Find required systems
	var systems := get_tree().current_scene.get_node_or_null("SystemsRunner")
	if systems:
		_agent_sim = systems.get_node_or_null("AgentSim") as AgentSim
		_spatial_hash = systems.get_node_or_null("AgentSim/SpatialHash2D") as SpatialHash2D
	
	_create_enemy_pool()
	_create_count_ui()
	_precompute_spawn_positions()
	
	# We drive spawns from _physics_process deterministically.
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not spawn_scene:
		return
	
	# Accumulate continuous spawn rate
	_spawn_accum += spawn_rate * delta
	if _alive.size() >= max_alive:
		_spawn_accum = 0.0
		return
	
	var want := int(floor(_spawn_accum))
	if want <= 0:
		return
	
	var can = clamp(max_alive - _alive.size(), 0, spawn_burst)
	var to_spawn = min(want, can)
	if to_spawn <= 0:
		return
	
	var spawned_this_tick := 0
	
	# Use batch spawning when possible
	if use_batch_spawning and to_spawn > 1:
		var batch_size = min(to_spawn, max_per_tick)
		var batch_spawned = _spawn_enemy_batch(batch_size)
		spawned_this_tick = batch_spawned
	else:
		# Individual spawning
		while spawned_this_tick < to_spawn and spawned_this_tick < max_per_tick:
			if _spawn_enemy():
				spawned_this_tick += 1
			else:
				# Couldn't find a clear spot this attempt; stop early to avoid a long loop.
				break
	
	# consume the accumulator by how many we actually spawned
	_spawn_accum -= float(spawned_this_tick)
	
	_maybe_update_count_ui()

func _spawn_enemy() -> bool:
	if not _enemy_pool:
		return false
	
	var inst := _enemy_pool.acquire()
	if inst == null:
		return false
	
	if inst is Node2D:
		var node := inst as Node2D
		
		# Find a clear position
		var pos = _pick_clear_spawn_position()
		if pos == null:
			_enemy_pool.release(inst)  # give it back; try again next frame
			return false
		
		# Reset state for reuse BEFORE adding to tree
		node.visible = true
		node.set_process(true)
		node.set_physics_process(true)
		node.global_position = pos
		
		# Ensure not already parented (shouldn't happen with a well-behaved pool, but guard anyway)
		if node.get_parent():
			node.get_parent().remove_child(node)
		
		# Add to scene
		get_tree().current_scene.add_child(node)
		
		# Register with AgentSim for AI and physics processing
		if _agent_sim:
			_agent_sim.register_agent(node)
		
		# Track alive enemies
		_alive.append(node)
		
		# Connect despawn signal
		if node.has_signal("despawn_requested"):
			node.despawn_requested.connect(_on_enemy_despawn)
		
		emit_signal("spawned", node)
		return true
	
	return false

# Batch spawning for better performance
func _spawn_enemy_batch(count: int) -> int:
	if not _enemy_pool or not _enemy_pool.has_method("acquire_batch"):
		return 0
	
	var instances = _enemy_pool.acquire_batch(count)
	if instances.is_empty():
		return 0
	
	var spawned_count = 0
	var clear_positions: Array[Vector2] = []
	
	# Find clear positions for all instances
	for i in range(instances.size()):
		var pos = _pick_clear_spawn_position()
		if pos != null:
			clear_positions.append(pos)
		else:
			break
	
	# Spawn instances with clear positions
	for i in range(clear_positions.size()):
		var inst = instances[i] as Node2D
		var pos = clear_positions[i]
		
		if inst and pos != null:
			# Reset state for reuse
			inst.visible = true
			inst.set_process(true)
			inst.set_physics_process(true)
			inst.global_position = pos
			
			# Ensure not already parented
			if inst.get_parent():
				inst.get_parent().remove_child(inst)
			
			# Add to scene
			get_tree().current_scene.add_child(inst)
			
			# Register with AgentSim for AI and physics processing
			if _agent_sim:
				_agent_sim.register_agent(inst)
			
			# Track alive enemies
			_alive.append(inst)
			
			# Connect despawn signal
			if inst.has_signal("despawn_requested"):
				inst.despawn_requested.connect(_on_enemy_despawn)
			
			emit_signal("spawned", inst)
			spawned_count += 1
	
	# Release unused instances back to pool
	for i in range(spawned_count, instances.size()):
		_enemy_pool.release(instances[i])
	
	return spawned_count

# Pre-compute spawn positions in a grid pattern for better performance
func _precompute_spawn_positions() -> void:
	var center = global_position
	var grid_radius = int(spawn_radius / spawn_grid_size)
	
	for y in range(-grid_radius, grid_radius + 1):
		for x in range(-grid_radius, grid_radius + 1):
			var pos = center + Vector2(x * spawn_grid_size, y * spawn_grid_size)
			if pos.distance_to(center) <= spawn_radius:
				_spawn_positions.append(pos)
	
	# Shuffle positions for randomness
	_spawn_positions.shuffle()

func _pick_clear_spawn_position() -> Vector2:
	if _spawn_positions.is_empty():
		return _pick_random_spawn_position()
	
	# Try pre-computed positions first
	for attempt in range(max_spawn_attempts):
		var pos = _spawn_positions[_spawn_position_index]
		_spawn_position_index = (_spawn_position_index + 1) % _spawn_positions.size()
		
		if _is_position_clear(pos):
			return pos
	
	# Fallback to random positions
	return _pick_random_spawn_position()

func _pick_random_spawn_position() -> Vector2:
	for attempt in range(max_spawn_attempts):
		var angle = _rng.randf() * TAU
		var distance = _rng.randf_range(min_spawn_gap, spawn_radius)
		var pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		if _is_position_clear(pos):
			return pos
	
	return null

func _is_position_clear(pos: Vector2) -> bool:
	if _spatial_hash == null:
		return true
	
	# Check if position is clear using spatial hash
	var nearby = _spatial_hash.query_radius(pos, min_spawn_gap)
	return nearby.is_empty()

func _on_enemy_despawn(enemy: Node2D) -> void:
	# Disconnect so pooled nodes don't stack multiple connections
	if enemy is BaseEnemy:
		var be := enemy as BaseEnemy
		if be.despawn_requested.is_connected(_on_enemy_despawn):
			be.despawn_requested.disconnect(_on_enemy_despawn)
	
	# Unregister from AgentSim
	if _agent_sim:
		_agent_sim.unregister_agent(enemy)
	
	# Remove from our tracking
	_alive.erase(enemy)
	
	# Group bookkeeping: pooled nodes retain groups unless removed
	if enemy.is_in_group(group_tag):
		enemy.remove_from_group(group_tag)
	
	GameBus.emit_signal("enemy_despawned", enemy)
	
	# Detach from scene tree and return to pool
	if is_instance_valid(enemy):
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		if _enemy_pool:
			_enemy_pool.release(enemy)
	
	_maybe_update_count_ui()

func _create_enemy_pool() -> void:
	_enemy_pool = ObjectPool.new()
	_enemy_pool.scene = spawn_scene
	_enemy_pool.initial_size = 200
	add_child(_enemy_pool)

func _create_count_ui() -> void:
	_count_label = Label.new()
	_count_label.text = "Enemies: 0"
	_count_label.position = Vector2(10, 10)
	_count_label.add_theme_color_override("font_color", Color.WHITE)
	_count_label.add_theme_font_size_override("font_size", 24)
	add_child(_count_label)
	_last_ui_count = 0

func _maybe_update_count_ui() -> void:
	if not _count_label:
		return
	var n := _alive.size()
	if n != _last_ui_count:
		_last_ui_count = n
		_count_label.text = "Enemies: %d / %d" % [n, max_alive]
