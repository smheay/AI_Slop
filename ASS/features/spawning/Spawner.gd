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

var _alive: Array[Node2D] = []
var _rng := RandomNumberGenerator.new()
var _count_label: Label
var _enemy_pool: ObjectPool
var _spatial_hash: SpatialHash2D

var _spawn_accum: float = 0.0
var _last_ui_count := -1

func _ready() -> void:
	_rng.randomize()
	
	# Optional spatial hash (for spawn clearance)
	var systems := get_tree().current_scene.get_node_or_null("SystemsRunner/AgentSim")
	if systems:
		_spatial_hash = systems.get_node_or_null("SpatialHash2D") as SpatialHash2D
	
	_create_enemy_pool()
	_create_count_ui()
	
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
	while spawned_this_tick < to_spawn:
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
	
	var inst = _enemy_pool.get_instance(spawn_scene)
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
		
		# Group bookkeeping
		if not node.is_in_group(group_tag):
			node.add_to_group(group_tag)
		
		# Connect despawn once per lifecycle; we disconnect on despawn (important for pooling)
		if inst is BaseEnemy:
			var enemy := inst as BaseEnemy
			# Avoid duplicate connects across reuse
			if not enemy.despawn_requested.is_connected(_on_enemy_despawn):
				enemy.despawn_requested.connect(_on_enemy_despawn)
		
		_alive.append(node)
		spawned.emit(node)
		GameBus.emit_signal("enemy_spawned", node)
		return true
	
	# If the scene isn't Node2D, just release it; we only handle 2D here.
	_enemy_pool.release(inst)
	return false

func _pick_clear_spawn_position() -> Variant:
	var attempts := 0
	var pos := Vector2.ZERO
	var gap2 := min_spawn_gap * min_spawn_gap
	
	while attempts < max_spawn_attempts:
		attempts += 1
		var ang := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(spawn_radius * 0.3, spawn_radius)
		pos = global_position + Vector2(cos(ang), sin(ang)) * dist
		
		if _is_position_clear(pos, gap2):
			return pos
	
	# None found
	return null

func _is_position_clear(pos: Vector2, gap2: float) -> bool:
	# Prefer spatial hash if available
	if _spatial_hash:
		var nearby := _spatial_hash.query_radius(pos, min_spawn_gap)
		# If your hash returns agent records, you may need to map to positions here.
		return nearby.size() == 0
	
	# Fallback: scan current alive list (O(n)), squared distance to avoid sqrt
	for enemy in _alive:
		if is_instance_valid(enemy) and (enemy.global_position - pos).length_squared() < gap2:
			return false
	return true

func _on_enemy_despawn(enemy: Node2D) -> void:
	# Safety check: ensure enemy is still valid
	if not is_instance_valid(enemy):
		# If enemy is already freed, just clean up our tracking
		_alive.erase(enemy)
		_maybe_update_count_ui()
		return
	
	# Disconnect so pooled nodes don't stack multiple connections
	if enemy is BaseEnemy:
		var be := enemy as BaseEnemy
		if be.despawn_requested.is_connected(_on_enemy_despawn):
			be.despawn_requested.disconnect(_on_enemy_despawn)
	
	# Remove from our tracking
	_alive.erase(enemy)
	
	# Group bookkeeping: pooled nodes retain groups unless removed
	if enemy.is_in_group(group_tag):
		enemy.remove_from_group(group_tag)
	
	GameBus.emit_signal("enemy_despawned", enemy)
	
	# Detach from scene tree and return to pool
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)
	if _enemy_pool:
		_enemy_pool.release(enemy)
	
	_maybe_update_count_ui()

func _create_enemy_pool() -> void:
	_enemy_pool = ObjectPool.new()
	# ObjectPool will create instances on-demand when get_instance is called
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
	# Clean up invalid enemies first
	_cleanup_invalid_enemies()
	
	if not _count_label:
		return
	var n := _alive.size()
	if n != _last_ui_count:
		_last_ui_count = n
		_count_label.text = "Enemies: %d / %d" % [n, max_alive]

func _cleanup_invalid_enemies() -> void:
	# Remove any invalid enemies from the alive list
	var i := 0
	while i < _alive.size():
		if not is_instance_valid(_alive[i]):
			_alive.remove_at(i)
		else:
			i += 1
