extends Node
class_name PerformanceMonitor

signal performance_warning(metric: String, value: float, threshold: float)

@export var monitor_enabled: bool = true
@export var update_interval: float = 1.0  # Update every second
@export var warning_thresholds: Dictionary = {
	"fps": 30.0,           # Warn if FPS drops below 30
	"frame_time": 33.0,    # Warn if frame time exceeds 33ms
	"memory_mb": 512.0,    # Warn if memory exceeds 512MB
	"enemy_count": 4000.0  # Warn if enemy count approaches limit
}

var _update_timer: float = 0.0
var _frame_times: Array[float] = []
var _frame_time_index: int = 0
var _frame_time_history_size: int = 60  # Track 1 second of frame times
var _last_frame_time: float = 0.0

# Performance metrics
var current_fps: float = 60.0
var avg_frame_time: float = 16.67
var memory_usage_mb: float = 0.0
var enemy_count: int = 0
var spatial_hash_cells: int = 0
var ai_processing_time: float = 0.0
var physics_processing_time: float = 0.0

# Systems to monitor
var _agent_sim: AgentSim
var _spatial_hash: SpatialHash2D
var _ai_runner: AIRunner
var _physics_runner: PhysicsRunner

func _ready() -> void:
	# Initialize frame time history
	_frame_times.resize(_frame_time_history_size)
	for i in range(_frame_time_history_size):
		_frame_times[i] = 16.67
	
	# Find systems to monitor
	_agent_sim = get_node_or_null("../AgentSim") as AgentSim
	_spatial_hash = get_node_or_null("../SpatialHash2D") as SpatialHash2D
	_ai_runner = get_node_or_null("../AIRunner") as AIRunner
	_physics_runner = get_node_or_null("../PhysicsRunner") as PhysicsRunner

func _process(delta: float) -> void:
	if not monitor_enabled:
		return
	
	# Update frame time tracking
	_update_frame_time(delta)
	
	# Update metrics at intervals
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_performance_metrics()
		_check_warnings()

func _update_frame_time(delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	if _last_frame_time > 0:
		var frame_time = current_time - _last_frame_time
		_frame_times[_frame_time_index] = frame_time
		_frame_time_index = (_frame_time_index + 1) % _frame_time_history_size
	_last_frame_time = current_time

func _update_performance_metrics() -> void:
	# Calculate FPS and frame time
	var total_frame_time = 0.0
	var valid_samples = 0
	
	for frame_time in _frame_times:
		if frame_time > 0:
			total_frame_time += frame_time
			valid_samples += 1
	
	if valid_samples > 0:
		avg_frame_time = total_frame_time / valid_samples
		current_fps = 1000.0 / avg_frame_time
	
	# Get memory usage
	memory_usage_mb = OS.get_static_memory_usage() / (1024.0 * 1024.0)
	
	# Get enemy count
	if _agent_sim:
		enemy_count = _agent_sim.get_agent_count()
	
	# Get spatial hash info
	if _spatial_hash:
		spatial_hash_cells = _spatial_hash._cells.size()
	
	# Get processing times from signals (if connected)
	# These would be updated by connecting to the runner signals

func _check_warnings() -> void:
	# Check FPS
	if current_fps < warning_thresholds.fps:
		emit_signal("performance_warning", "fps", current_fps, warning_thresholds.fps)
	
	# Check frame time
	if avg_frame_time > warning_thresholds.frame_time:
		emit_signal("performance_warning", "frame_time", avg_frame_time, warning_thresholds.frame_time)
	
	# Check memory
	if memory_usage_mb > warning_thresholds.memory_mb:
		emit_signal("performance_warning", "memory_mb", memory_usage_mb, warning_thresholds.memory_mb)
	
	# Check enemy count
	if enemy_count > warning_thresholds.enemy_count:
		emit_signal("performance_warning", "enemy_count", enemy_count, warning_thresholds.enemy_count)

# Get comprehensive performance report
func get_performance_report() -> Dictionary:
	return {
		"fps": current_fps,
		"avg_frame_time_ms": avg_frame_time,
		"memory_usage_mb": memory_usage_mb,
		"enemy_count": enemy_count,
		"spatial_hash_cells": spatial_hash_cells,
		"ai_processing_time_ms": ai_processing_time,
		"physics_processing_time_ms": physics_processing_time,
		"performance_score": _calculate_performance_score()
	}

# Calculate overall performance score (0-100)
func _calculate_performance_score() -> float:
	var score = 100.0
	
	# FPS penalty
	if current_fps < 60.0:
		score -= (60.0 - current_fps) * 2.0
	
	# Frame time penalty
	if avg_frame_time > 16.67:
		score -= (avg_frame_time - 16.67) * 2.0
	
	# Memory penalty
	if memory_usage_mb > 256.0:
		score -= (memory_usage_mb - 256.0) * 0.1
	
	# Enemy count bonus (efficiency)
	if enemy_count > 1000:
		score += min(20.0, (enemy_count - 1000) * 0.01)
	
	return max(0.0, min(100.0, score))

# Get performance recommendations
func get_performance_recommendations() -> Array[String]:
	var recommendations: Array[String] = []
	
	if current_fps < 45.0:
		recommendations.append("Consider reducing enemy count or increasing LOD levels")
	
	if avg_frame_time > 25.0:
		recommendations.append("Physics processing is slow - check collision complexity")
	
	if memory_usage_mb > 400.0:
		recommendations.append("Memory usage is high - consider object pooling")
	
	if enemy_count > 4000:
		recommendations.append("Enemy count is very high - monitor performance closely")
	
	if spatial_hash_cells > 1000:
		recommendations.append("Spatial hash has many cells - consider adjusting cell size")
	
	return recommendations

# Connect to runner signals for detailed timing
func connect_to_runners() -> void:
	if _ai_runner:
		_ai_runner.ai_batch_finished.connect(_on_ai_batch_finished)
	
	if _physics_runner:
		_physics_runner.physics_batch_finished.connect(_on_physics_batch_finished)

func _on_ai_batch_finished(ms: float) -> void:
	ai_processing_time = ms

func _on_physics_batch_finished(ms: float) -> void:
	physics_processing_time = ms

# Print performance summary to console
func print_performance_summary() -> void:
	var report = get_performance_report()
	var recommendations = get_performance_recommendations()
	
	print("=== PERFORMANCE MONITOR ===")
	print("FPS: %.1f" % report.fps)
	print("Frame Time: %.2f ms" % report.avg_frame_time_ms)
	print("Memory: %.1f MB" % report.memory_usage_mb)
	print("Enemies: %d" % report.enemy_count)
	print("Spatial Hash Cells: %d" % report.spatial_hash_cells)
	print("AI Time: %.2f ms" % report.ai_processing_time_ms)
	print("Physics Time: %.2f ms" % report.physics_processing_time_ms)
	print("Performance Score: %.1f/100" % report.performance_score)
	
	if recommendations.size() > 0:
		print("\nRecommendations:")
		for rec in recommendations:
			print("- " + rec)
	
	print("==========================")