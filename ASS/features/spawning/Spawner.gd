extends Node2D
class_name Spawner

signal spawned(node: Node)

@export var spawn_scene: PackedScene
@export var group_tag: StringName = "enemies"
@export var spawn_radius: float = 1024.0
@export var spawn_rate: float = 0.25
@export var max_alive: int = 1000

var _alive: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _count_label: Label
var _enemy_pool: ObjectPool
var _spatial_hash: SpatialHash2D

func _ready() -> void:
	_rng.randomize()
	
	# Optional spatial hash access (for spawn clearance)
	var systems := get_tree().current_scene.get_node_or_null("SystemsRunner/AgentSim") as AgentSim
	if systems:
		_spatial_hash = systems.get_node_or_null("SpatialHash2D") as SpatialHash2D
	
	# Create enemy pool
	_create_enemy_pool()
	
	# Create enemy count UI
	_create_count_ui()
	
	var timer = Timer.new()
	timer.name = "SpawnTimer"
	timer.wait_time = 1.0 / spawn_rate
	timer.autostart = true
	timer.timeout.connect(_on_spawn_timer)
	add_child(timer)

func _on_spawn_timer() -> void:
	if _alive.size() < max_alive and spawn_scene != null:
		var to_spawn = min(100, max_alive - _alive.size())
		for i in range(to_spawn):
			_spawn_enemy()

func _spawn_enemy() -> void:
	var inst: Node = _enemy_pool.acquire()
	if inst is Node2D:
		# Use a much larger spawn radius and ensure minimum distance between spawns
		var attempts := 0
		var pos: Vector2
		while attempts < 10:
			var ang := _rng.randf_range(0.0, TAU)
			var dist := _rng.randf_range(spawn_radius * 0.3, spawn_radius)
			pos = global_position + Vector2(cos(ang), sin(ang)) * dist
			if _is_position_clear(pos):
				break
			attempts += 1
		
		(inst as Node2D).global_position = pos
		
		# Reset enemy state for reuse
		inst.visible = true
		inst.set_process(true)
		
		# Ensure enemy is not already in scene tree
		if inst.get_parent():
			inst.get_parent().remove_child(inst)
		
		# Add to scene and tracking
		get_tree().current_scene.add_child(inst)
		inst.add_to_group(group_tag)
		
		# Connect despawn signal once
		if inst is BaseEnemy:
			var enemy := inst as BaseEnemy
			if not enemy.has_meta("despawn_connected"):
				enemy.despawn_requested.connect(_on_enemy_despawn)
				enemy.set_meta("despawn_connected", true)
		
		_alive.append(inst)
		emit_signal("spawned", inst)
		GameBus.emit_signal("enemy_spawned", inst)
		_update_count_ui()
		
		# The enemy will automatically register with AgentSim in its _ready() function

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

func _update_count_ui() -> void:
	if _count_label:
		_count_label.text = "Enemies: " + str(_alive.size()) + " / " + str(max_alive)

func _is_position_clear(pos: Vector2) -> bool:
	# Prefer spatial hash if available
	if _spatial_hash:
		var nearby := _spatial_hash.query_radius(pos, 48.0)
		if nearby.size() == 0:
			return true
		return false
	# Fallback: scan current alive list
	for enemy in _alive:
		if enemy.global_position.distance_to(pos) < 48.0:
			return false
	return true

func _on_enemy_despawn(enemy: Node2D) -> void:
	_alive.erase(enemy)
	GameBus.emit_signal("enemy_despawned", enemy)
	
	# Remove from scene tree but don't free; return to pool
	if _enemy_pool and is_instance_valid(enemy):
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		_enemy_pool.release(enemy)
	
	_update_count_ui()
