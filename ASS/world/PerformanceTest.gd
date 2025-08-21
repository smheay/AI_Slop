extends Node2D
class_name PerformanceTest

# Performance test for the optimized entity system
# Demonstrates handling 5000+ entities efficiently

@export var systems_runner: OptimizedSystemsRunner
@export var performance_label: Label

# Test configuration
var target_entity_count: int = 5000
var current_entity_count: int = 0
var test_started: bool = false
var test_start_time: float = 0.0

# Performance tracking
var fps_history: Array[float] = []
var entity_history: Array[int] = []
var memory_history: Array[int] = []

func _ready() -> void:
	# Wait for systems to be ready
	if systems_runner:
		systems_runner.systems_ready.connect(_on_systems_ready)
		systems_runner.performance_updated.connect(_on_performance_updated)
	
	# Start test after a short delay
	await get_tree().create_timer(1.0).timeout
	_start_performance_test()

func _on_systems_ready() -> void:
	Log.info("PerformanceTest: Systems ready, starting test...")
	_start_performance_test()

func _start_performance_test() -> void:
	if test_started:
		return
	
	test_started = true
	test_start_time = Time.get_time_dict_from_system()["unix"]
	
	Log.info("PerformanceTest: Starting performance test with target of %d entities" % target_entity_count)
	
	# Set spawner to high rate to quickly reach target
	if systems_runner:
		systems_runner.set_spawn_rate(500.0)  # 500 entities per second

func _on_performance_updated(stats: Dictionary) -> void:
	current_entity_count = stats.get("entity_count", 0)
	
	# Update performance label
	if performance_label:
		_update_performance_display(stats)
	
	# Track performance history
	_track_performance(stats)
	
	# Check if we've reached target
	if current_entity_count >= target_entity_count and not _has_reached_target:
		_on_target_reached()

var _has_reached_target: bool = false

func _on_target_reached() -> void:
	_has_reached_target = true
	var elapsed = Time.get_time_dict_from_system()["unix"] - test_start_time
	
	Log.info("PerformanceTest: Target of %d entities reached in %.2f seconds!" % [target_entity_count, elapsed])
	
	# Reduce spawn rate to maintain target
	if systems_runner:
		systems_runner.set_spawn_rate(50.0)  # Maintain with lower rate

func _update_performance_display(stats: Dictionary) -> void:
	var fps = stats.get("fps", 0)
	var memory_mb = stats.get("memory_usage", 0) / 1024 / 1024
	var lod_stats = stats.get("lod_stats", {})
	
	var text = "Performance Monitor\n"
	text += "Entities: %d / %d\n" % [current_entity_count, target_entity_count]
	text += "FPS: %d\n" % fps
	text += "Memory: %d MB\n" % memory_mb
	text += "LOD Stats:\n"
	text += "- High: %d\n" % lod_stats.get("high_detail", 0)
	text += "- Medium: %d\n" % lod_stats.get("medium_detail", 0)
	text += "- Low: %d\n" % lod_stats.get("low_detail", 0)
	text += "- Minimal: %d\n" % lod_stats.get("minimal_detail", 0)
	
	# Add performance analysis
	if fps < 30:
		text += "\n⚠️ Performance Warning: Low FPS"
	elif fps < 50:
		text += "\n⚠️ Performance Notice: Moderate FPS"
	else:
		text += "\n✅ Performance: Good"
	
	performance_label.text = text

func _track_performance(stats: Dictionary) -> void:
	var fps = stats.get("fps", 0)
	var memory = stats.get("memory_usage", 0)
	
	fps_history.append(fps)
	entity_history.append(current_entity_count)
	memory_history.append(memory)
	
	# Keep only last 100 entries
	if fps_history.size() > 100:
		fps_history.pop_front()
		entity_history.pop_front()
		memory_history.pop_front()

func get_performance_summary() -> Dictionary:
	if fps_history.is_empty():
		return {}
	
	var avg_fps = 0.0
	var min_fps = 999.0
	var max_fps = 0.0
	
	for fps in fps_history:
		avg_fps += fps
		min_fps = min(min_fps, fps)
		max_fps = max(max_fps, fps)
	
	avg_fps /= fps_history.size()
	
	var avg_memory = 0.0
	for memory in memory_history:
		avg_memory += memory
	avg_memory /= memory_history.size()
	
	return {
		"average_fps": avg_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"average_memory_mb": avg_memory / 1024 / 1024,
		"peak_entities": entity_history.max() if entity_history.size() > 0 else 0,
		"test_duration_seconds": Time.get_time_dict_from_system()["unix"] - test_start_time
	}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				# Spawn 1000 entities
				if systems_runner:
					systems_runner.spawn_entities(1000)
			KEY_2:
				# Spawn 2000 entities
				if systems_runner:
					systems_runner.spawn_entities(2000)
			KEY_3:
				# Spawn 5000 entities
				if systems_runner:
					systems_runner.spawn_entities(5000)
			KEY_C:
				# Clear all entities
				if systems_runner:
					systems_runner.clear_all_entities()
			KEY_P:
				# Print performance summary
				var summary = get_performance_summary()
				Log.info("Performance Summary: %s" % summary)
			KEY_R:
				# Reset test
				_reset_test()

func _reset_test() -> void:
	if systems_runner:
		systems_runner.clear_all_entities()
	
	test_started = false
	_has_reached_target = false
	test_start_time = 0.0
	current_entity_count = 0
	
	fps_history.clear()
	entity_history.clear()
	memory_history.clear()
	
	Log.info("PerformanceTest: Test reset")
	
	# Restart after delay
	await get_tree().create_timer(1.0).timeout
	_start_performance_test()