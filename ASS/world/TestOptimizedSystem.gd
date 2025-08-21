extends Node2D
class_name TestOptimizedSystem

@export var systems_runner: OptimizedSystemsRunner

var status_label: Label
var frame_count: int = 0

func _ready() -> void:
	# Get references
	systems_runner = get_node_or_null("OptimizedSystemsRunner")
	status_label = get_node_or_null("UI/StatusLabel")
	
	if systems_runner:
		systems_runner.systems_ready.connect(_on_systems_ready)
		systems_runner.performance_updated.connect(_on_performance_updated)
	
	Log.info("TestOptimizedSystem: Ready")

func _on_systems_ready() -> void:
	Log.info("TestOptimizedSystem: Systems are ready")
	if status_label:
		status_label.text = "Optimized System Test\nStatus: Ready\nEntities: 0\nFPS: 0"

func _on_performance_updated(stats: Dictionary) -> void:
	if status_label:
		status_label.text = "Optimized System Test\nStatus: Running\nEntities: %d\nFPS: %d" % [
			stats.get("entity_count", 0),
			stats.get("fps", 0)
		]

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_1:
			_spawn_entities(100)
		KEY_2:
			_spawn_entities(500)
		KEY_3:
			_spawn_entities(1000)
		KEY_C:
			_clear_entities()
		KEY_P:
			_print_status()

func _spawn_entities(count: int) -> void:
	if not systems_runner:
		Log.error("TestOptimizedSystem: Systems runner not found")
		return
	
	Log.info("TestOptimizedSystem: Spawning %d entities" % count)
	systems_runner.spawn_entities(count)

func _clear_entities() -> void:
	if not systems_runner:
		Log.error("TestOptimizedSystem: Systems runner not found")
		return
	
	Log.info("TestOptimizedSystem: Clearing all entities")
	systems_runner.clear_all_entities()

func _print_status() -> void:
	if not systems_runner:
		Log.error("TestOptimizedSystem: Systems runner not found")
		return
	
	var status = systems_runner.get_system_status()
	Log.info("TestOptimizedSystem: System status: %s" % str(status))
	
	var perf_stats = systems_runner.get_performance_stats()
	Log.info("TestOptimizedSystem: Performance stats: %s" % str(perf_stats))

func _process(delta: float) -> void:
	frame_count += 1
	
	# Update FPS display every 60 frames
	if frame_count % 60 == 0 and status_label:
		var fps = Engine.get_frames_per_second()
		var current_text = status_label.text
		var lines = current_text.split("\n")
		if lines.size() >= 4:
			lines[3] = "FPS: %d" % fps
			status_label.text = "\n".join(lines)
