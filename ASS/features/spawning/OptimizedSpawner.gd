extends Node2D
class_name OptimizedSpawner

# Optimized spawner for 5000+ entities
# Uses the new data-oriented entity system

signal spawned(entity_id: int)
signal despawned(entity_id: int)

var entity_manager: OptimizedEntityManager
@export var spawn_radius: float = 300.0        # Reduced spawn radius for closer spawning
@export var spawn_rate: float = 100.0        # entities per second
@export var max_alive: int = 5000
@export var spawn_burst: int = 10            # entities per spawn tick (reduced from 20 to 10)
@export var min_spawn_gap: float = 32.0     # clearance radius between spawns
@export var max_per_tick: int = 3           # cap spawns per physics frame (reduced from 5 to 3)

var _spawn_accum: float = 0.0
var _rng := RandomNumberGenerator.new()
var _count_label: Label
var _last_ui_count := -1

# Spawn patterns for variety
var _spawn_patterns: Array[Dictionary] = []
var _current_pattern_index: int = 0

func _ready() -> void:
	_rng.randomize()
	
	# Initialize spawn patterns
	_init_spawn_patterns()
	
	# Create UI
	_create_count_ui()
	
	# Start spawning
	set_physics_process(true)

func _init_spawn_patterns() -> void:
	# Circle spawn pattern
	_spawn_patterns.append({
		"type": "circle",
		"radius": spawn_radius * 0.8,
		"density": 0.8
	})
	
	# Grid spawn pattern
	_spawn_patterns.append({
		"type": "grid",
		"spacing": 64.0,
		"density": 0.6
	})
	
	# Random spawn pattern
	_spawn_patterns.append({
		"type": "random",
		"density": 0.4
	})

func _physics_process(delta: float) -> void:
	if not entity_manager:
		return
	
	# Accumulate continuous spawn rate
	_spawn_accum += spawn_rate * delta
	if entity_manager.get_entity_count() >= max_alive:
		_spawn_accum = 0.0
		return
	
	var want := int(floor(_spawn_accum))
	if want <= 0:
		return
	
	var can = clamp(max_alive - entity_manager.get_entity_count(), 0, spawn_burst)
	var to_spawn = min(want, can)
	if to_spawn <= 0:
		return
	
	var spawned_this_tick := 0
	while spawned_this_tick < to_spawn and spawned_this_tick < max_per_tick:
		if _spawn_entity():
			spawned_this_tick += 1
		else:
			# Couldn't find a clear spot; stop early
			break
	
	# Consume the accumulator by how many we actually spawned
	_spawn_accum -= float(spawned_this_tick)
	
	# Update UI
	_maybe_update_count_ui()

func _spawn_entity() -> bool:
	if not entity_manager:
		return false
	
	# Get spawn position
	var pos = _pick_clear_spawn_position()
	if pos == null:
		return false
	
	# Create entity with properties
	var properties = _get_random_entity_properties()
	var entity_id = entity_manager.create_entity(pos, properties)
	
	if entity_id >= 0:
		spawned.emit(entity_id)
		return true
	
	return false

func _pick_clear_spawn_position() -> Variant:
	var attempts := 0
	var pos := Vector2.ZERO
	var gap2 := min_spawn_gap * min_spawn_gap
	
	while attempts < 20:  # Limit attempts to avoid infinite loops
		attempts += 1
		
		# Use current spawn pattern
		var pattern = _spawn_patterns[_current_pattern_index]
		pos = _get_position_from_pattern(pattern)
		
		if _is_position_clear(pos, gap2):
			return pos
	
	# Try next pattern if current one failed
	_current_pattern_index = (_current_pattern_index + 1) % _spawn_patterns.size()
	
	# Fallback to random position
	pos = _get_random_position()
	if _is_position_clear(pos, gap2):
		return pos
	
	return null

func _get_position_from_pattern(pattern: Dictionary) -> Vector2:
	var spawn_center = _get_spawn_center()
	
	match pattern.type:
		"circle":
			var angle = _rng.randf_range(0.0, TAU)
			var radius = _rng.randf_range(pattern.radius * 0.3, pattern.radius)
			return spawn_center + Vector2(cos(angle), sin(angle)) * radius
		
		"grid":
			var spacing = pattern.spacing
			var grid_radius = int(spawn_radius / spacing)
			var x = _rng.randi_range(-grid_radius, grid_radius)
			var y = _rng.randi_range(-grid_radius, grid_radius)
			return spawn_center + Vector2(x * spacing, y * spacing)
		
		"random":
			return _get_random_position()
	
	return _get_random_position()

func _get_random_position() -> Vector2:
	var spawn_center = _get_spawn_center()
	var angle = _rng.randf_range(0.0, TAU)
	var radius = _rng.randf_range(spawn_radius * 0.3, spawn_radius)
	return spawn_center + Vector2(cos(angle), sin(angle)) * radius

func _get_spawn_center() -> Vector2:
	# Get player position as spawn center
	var player = get_tree().get_first_node_in_group("player")
	if player and player is Node2D:
		return player.global_position
	# Fallback to spawner position
	return global_position

func _is_position_clear(pos: Vector2, gap2: float) -> bool:
	if not entity_manager:
		return true
	
	# Use spatial hash to check for nearby entities
	var nearby = entity_manager.get_entities_near_position(pos, min_spawn_gap)
	for entity_id in nearby:
		var entity_pos = entity_manager.get_entity_position(entity_id)
		if (entity_pos - pos).length_squared() < gap2:
			return false
	
	return true

func _get_random_entity_properties() -> Dictionary:
	# Randomize entity properties for variety
	var properties = {}
	
	# Movement properties
	properties.move_speed = _rng.randf_range(80.0, 160.0)
	properties.separation_radius = _rng.randf_range(20.0, 32.0)
	properties.separation_strength = _rng.randf_range(60.0, 100.0)
	properties.hit_radius = _rng.randf_range(8.0, 16.0)
	
	return properties

func _create_count_ui() -> void:
	_count_label = Label.new()
	_count_label.text = "Entities: 0"
	_count_label.position = Vector2(10, 10)
	_count_label.add_theme_color_override("font_color", Color.WHITE)
	_count_label.add_theme_font_size_override("font_size", 24)
	add_child(_count_label)
	_last_ui_count = 0

func _maybe_update_count_ui() -> void:
	if not _count_label or not entity_manager:
		return
	
	var n := entity_manager.get_entity_count()
	if n != _last_ui_count:
		_last_ui_count = n
		_count_label.text = "Entities: %d / %d" % [n, max_alive]

func set_entity_manager(manager: OptimizedEntityManager) -> void:
	entity_manager = manager
	
	# Connect to entity manager signals
	if entity_manager:
		entity_manager.entity_count_changed.connect(_on_entity_count_changed)

func _on_entity_count_changed(count: int) -> void:
	_maybe_update_count_ui()

func get_spawn_stats() -> Dictionary:
	return {
		"spawn_rate": spawn_rate,
		"max_alive": max_alive,
		"current_count": entity_manager.get_entity_count() if entity_manager else 0,
		"spawn_accum": _spawn_accum
	}