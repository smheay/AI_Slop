extends Node2D
class_name IntegrationExample

# Example of how to integrate the optimized entity system into a game
# This demonstrates the complete workflow from setup to gameplay

@export var world_size: Vector2 = Vector2(2048, 2048)
@export var max_entities: int = 5000

var entity_manager: OptimizedEntityManager
var systems_runner: OptimizedSystemsRunner
var spawner: OptimizedSpawner

# Game state
var player_position: Vector2 = Vector2.ZERO
var game_running: bool = false

# UI elements
var entity_count_label: Label
var performance_label: Label
var controls_label: Label

func _ready() -> void:
	# Initialize the optimized system
	_setup_optimized_system()
	
	# Create UI
	_create_ui()
	
	# Start the game
	_start_game()

func _setup_optimized_system() -> void:
	# Create world bounds
	var world_bounds = Rect2(-world_size * 0.5, world_size)
	
	# Create entity manager
	entity_manager = OptimizedEntityManager.new(world_bounds, max_entities)
	
	# Create systems runner
	systems_runner = OptimizedSystemsRunner.new()
	systems_runner.entity_manager = entity_manager
	systems_runner.max_entities = max_entities
	add_child(systems_runner)
	
	# Create spawner
	spawner = OptimizedSpawner.new()
	spawner.entity_manager = entity_manager
	spawner.max_alive = max_entities
	spawner.spawn_rate = 100.0  # 100 entities per second
	add_child(spawner)
	
	# Connect signals
	entity_manager.entity_count_changed.connect(_on_entity_count_changed)
	entity_manager.performance_stats_updated.connect(_on_performance_updated)
	
	Log.info("IntegrationExample: Optimized system initialized")

func _create_ui() -> void:
	# Create UI layer
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Entity count label
	entity_count_label = Label.new()
	entity_count_label.text = "Entities: 0"
	entity_count_label.position = Vector2(10, 10)
	entity_count_label.add_theme_color_override("font_color", Color.WHITE)
	entity_count_label.add_theme_font_size_override("font_size", 24)
	ui_layer.add_child(entity_count_label)
	
	# Performance label
	performance_label = Label.new()
	performance_label.text = "Performance: Initializing..."
	performance_label.position = Vector2(10, 50)
	performance_label.add_theme_color_override("font_color", Color.YELLOW)
	performance_label.add_theme_font_size_override("font_size", 18)
	ui_layer.add_child(performance_label)
	
	# Controls label
	controls_label = Label.new()
	controls_label.text = "Controls:\nSPACE - Toggle spawning\nR - Reset\nC - Clear all\n1-5 - Spawn batches"
	controls_label.position = Vector2(10, 100)
	controls_label.add_theme_color_override("font_color", Color.CYAN)
	controls_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(controls_label)

func _start_game() -> void:
	game_running = true
	
	# Start spawning entities
	spawner.set_physics_process(true)
	
	Log.info("IntegrationExample: Game started")

func _on_entity_count_changed(count: int) -> void:
	if entity_count_label:
		entity_count_label.text = "Entities: %d / %d" % [count, max_entities]

func _on_performance_updated(stats: Dictionary) -> void:
	if performance_label:
		var fps = stats.get("fps", 0)
		var memory_mb = stats.get("memory_usage", 0) / 1024 / 1024
		
		var text = "Performance:\n"
		text += "FPS: %d\n" % fps
		text += "Memory: %d MB\n" % memory_mb
		
		# Add LOD info
		var lod_stats = stats.get("lod_stats", {})
		text += "LOD: H:%d M:%d L:%d Min:%d" % [
			lod_stats.get("high_detail", 0),
			lod_stats.get("medium_detail", 0),
			lod_stats.get("low_detail", 0),
			lod_stats.get("minimal_detail", 0)
		]
		
		performance_label.text = text
		
		# Color code based on performance
		if fps < 30:
			performance_label.add_theme_color_override("font_color", Color.RED)
		elif fps < 50:
			performance_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			performance_label.add_theme_color_override("font_color", Color.GREEN)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_toggle_spawning()
			KEY_R:
				_reset_game()
			KEY_C:
				_clear_all_entities()
			KEY_1:
				_spawn_batch(100)
			KEY_2:
				_spawn_batch(500)
			KEY_3:
				_spawn_batch(1000)
			KEY_4:
				_spawn_batch(2000)
			KEY_5:
				_spawn_batch(5000)

func _toggle_spawning() -> void:
	if spawner:
		var current_rate = spawner.spawn_rate
		if current_rate > 0:
			spawner.spawn_rate = 0
			Log.info("IntegrationExample: Spawning paused")
		else:
			spawner.spawn_rate = 100.0
			Log.info("IntegrationExample: Spawning resumed")

func _reset_game() -> void:
	Log.info("IntegrationExample: Resetting game...")
	
	# Clear all entities
	_clear_all_entities()
	
	# Reset spawner
	if spawner:
		spawner.spawn_rate = 100.0
	
	Log.info("IntegrationExample: Game reset complete")

func _clear_all_entities() -> void:
	if entity_manager:
		entity_manager.clear_all_entities()
		Log.info("IntegrationExample: All entities cleared")

func _spawn_batch(count: int) -> void:
	if entity_manager:
		var current_count = entity_manager.get_entity_count()
		var target_count = min(current_count + count, max_entities)
		var to_spawn = target_count - current_count
		
		# Temporarily increase spawn rate
		var original_rate = spawner.spawn_rate
		spawner.spawn_rate = to_spawn * 2.0
		
		Log.info("IntegrationExample: Spawning %d entities" % to_spawn)
		
		# Reset spawn rate after a delay
		await get_tree().create_timer(2.0).timeout
		spawner.spawn_rate = original_rate

func _physics_process(delta: float) -> void:
	# Update player position for AI and LOD
	# In a real game, this would come from the player character
	player_position = Vector2(512, 512)  # Center of world for demo
	
	# Update entity manager with player position
	if entity_manager and entity_manager.ai_runner:
		entity_manager.ai_runner.set_player_position(player_position)

func get_game_stats() -> Dictionary:
	return {
		"entity_count": entity_manager.get_entity_count() if entity_manager else 0,
		"max_entities": max_entities,
		"game_running": game_running,
		"spawn_rate": spawner.spawn_rate if spawner else 0
	}

func _exit_tree() -> void:
	# Cleanup
	if entity_manager:
		entity_manager.clear_all_entities()