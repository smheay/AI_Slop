extends Node
class_name PerformanceProfiler

signal performance_warning(component: String, metric: String, value: float, threshold: float)

@export var enabled: bool = true
@export var warning_threshold_fps: float = 30.0
@export var warning_threshold_memory_mb: float = 512.0
@export var warning_threshold_frame_time_ms: float = 33.33
@export var auto_optimize: bool = true

var _frame_times: Array[float] = []
var _frame_time_index: int = 0
var _frame_time_history_size: int = 60
var _last_frame_time: float = 0.0
var _performance_metrics: Dictionary = {}
var _optimization_suggestions: Array[String] = []

func _ready() -> void:
	if not enabled:
		return
	
	_frame_times.resize(_frame_time_history_size)
	for i in range(_frame_time_history_size):
		_frame_times[i] = 16.67  # Default 60 FPS
	
	# Initialize performance metrics
	_performance_metrics = {
		"fps": 60.0,
		"frame_time_ms": 16.67,
		"memory_usage_mb": 0.0,
		"active_agents": 0,
		"spatial_hash_queries": 0,
		"physics_collisions": 0
	}

func _process(delta: float) -> void:
	if not enabled:
		return
	
	_update_frame_time(delta)
	_update_performance_metrics()
	_check_performance_warnings()
	
	if auto_optimize:
		_apply_auto_optimizations()

func _update_frame_time(delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	if _last_frame_time > 0:
		var frame_time = current_time - _last_frame_time
		_frame_times[_frame_time_index] = frame_time
		_frame_time_index = (_frame_time_index + 1) % _frame_time_history_size
	_last_frame_time = current_time

func _update_performance_metrics() -> void:
	# Calculate FPS and frame time
	var avg_frame_time = 0.0
	var valid_samples = 0
	
	for frame_time in _frame_times:
		if frame_time > 0:
			avg_frame_time += frame_time
			valid_samples += 1
	
	if valid_samples > 0:
		avg_frame_time /= valid_samples
		_performance_metrics["fps"] = 1000.0 / avg_frame_time
		_performance_metrics["frame_time_ms"] = avg_frame_time
	
	# Update memory usage
	_performance_metrics["memory_usage_mb"] = OS.get_static_memory_usage() / (1024.0 * 1024.0)

func _check_performance_warnings() -> void:
	var warnings = []
	
	# Check FPS
	if _performance_metrics["fps"] < warning_threshold_fps:
		emit_signal("performance_warning", "Rendering", "FPS", _performance_metrics["fps"], warning_threshold_fps)
		warnings.append("Low FPS detected: " + str(_performance_metrics["fps"]))
	
	# Check frame time
	if _performance_metrics["frame_time_ms"] > warning_threshold_frame_time_ms:
		emit_signal("performance_warning", "Rendering", "Frame Time", _performance_metrics["frame_time_ms"], warning_threshold_frame_time_ms)
		warnings.append("High frame time: " + str(_performance_metrics["frame_time_ms"]) + "ms")
	
	# Check memory usage
	if _performance_metrics["memory_usage_mb"] > warning_threshold_memory_mb:
		emit_signal("performance_warning", "Memory", "Usage", _performance_metrics["memory_usage_mb"], warning_threshold_memory_mb)
		warnings.append("High memory usage: " + str(_performance_metrics["memory_usage_mb"]) + "MB")
	
	_optimization_suggestions = warnings

func _apply_auto_optimizations() -> void:
	var fps = _performance_metrics["fps"]
	
	if fps < 30.0:
		_apply_aggressive_optimizations()
	elif fps < 45.0:
		_apply_moderate_optimizations()
	elif fps > 55.0:
		_apply_quality_improvements()

func _apply_aggressive_optimizations() -> void:
	# Reduce LOD levels
	var lod_controllers = get_tree().get_nodes_in_group("lod_controller")
	for controller in lod_controllers:
		if controller.has_method("set_lod_level"):
			controller.set_lod_level(3)  # Maximum LOD level
	
	# Reduce batch sizes
	var ai_runners = get_tree().get_nodes_in_group("ai_runner")
	for runner in ai_runners:
		if runner.has_method("set_batch_size"):
			runner.set_batch_size(32)
	
	var physics_runners = get_tree().get_nodes_in_group("physics_runner")
	for runner in physics_runners:
		if runner.has_method("set_batch_size"):
			runner.set_batch_size(32)

func _apply_moderate_optimizations() -> void:
	# Moderate LOD reduction
	var lod_controllers = get_tree().get_nodes_in_group("lod_controller")
	for controller in lod_controllers:
		if controller.has_method("set_lod_level"):
			controller.set_lod_level(2)
	
	# Moderate batch size reduction
	var ai_runners = get_tree().get_nodes_in_group("ai_runner")
	for runner in ai_runners:
		if runner.has_method("set_batch_size"):
			runner.set_batch_size(48)
	
	var physics_runners = get_tree().get_nodes_in_group("physics_runner")
	for runner in physics_runners:
		if runner.has_method("set_batch_size"):
			runner.set_batch_size(48)

func _apply_quality_improvements() -> void:
	# Increase LOD levels for better quality
	var lod_controllers = get_tree().get_nodes_in_group("lod_controller")
	for controller in lod_controllers:
		if controller.has_method("set_lod_level"):
			controller.set_lod_level(1)
	
	# Increase batch sizes for better performance
	var ai_runners = get_tree().get_nodes_in_group("ai_runner")
	for runner in ai_runners:
		if runner.has_method("set_batch_size"):
			runner.set_batch_size(96)
	
	var physics_runners = get_tree().get_nodes_in_group("physics_runner")
	for runner in physics_runners:
		if runner.has_method("set_batch_size"):
			runner.set_batch_size(96)

func get_performance_report() -> Dictionary:
	return {
		"metrics": _performance_metrics,
		"warnings": _optimization_suggestions,
		"auto_optimize": auto_optimize,
		"enabled": enabled
	}

func set_metric(metric_name: String, value: float) -> void:
	if _performance_metrics.has(metric_name):
		_performance_metrics[metric_name] = value

func get_metric(metric_name: String) -> float:
	return _performance_metrics.get(metric_name, 0.0)

func add_performance_marker(name: String) -> void:
	if not enabled:
		return
	
	var current_time = Time.get_ticks_msec()
	_performance_metrics[name + "_start"] = current_time

func end_performance_marker(name: String) -> float:
	if not enabled:
		return 0.0
	
	var current_time = Time.get_ticks_msec()
	var start_time = _performance_metrics.get(name + "_start", current_time)
	var duration = current_time - start_time
	
	_performance_metrics[name + "_duration"] = duration
	_performance_metrics.erase(name + "_start")
	
	return duration