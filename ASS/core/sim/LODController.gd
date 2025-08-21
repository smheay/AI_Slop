extends Node
class_name LODController

@export var near_distance: float = 256.0
@export var far_distance: float = 1024.0
@export var adaptive_lod: bool = true
@export var target_fps: float = 60.0
@export var min_lod_level: int = 0
@export var max_lod_level: int = 3

var _frame_times: Array[float] = []
var _frame_time_index: int = 0
var _frame_time_history_size: int = 30
var _last_frame_time: float = 0.0
var _current_lod_level: int = 1

func _ready() -> void:
	_frame_times.resize(_frame_time_history_size)
	for i in range(_frame_time_history_size):
		_frame_times[i] = 16.67  # Default 60 FPS

func _process(delta: float) -> void:
	_update_frame_time(delta)
	
	if adaptive_lod:
		_adjust_lod_level()

func compute_lod(camera_pos: Vector2, target_pos: Vector2) -> int:
	var d := camera_pos.distance_to(target_pos)
	var base_lod = 0
	
	if d < near_distance:
		base_lod = 0
	elif d < far_distance:
		base_lod = 1
	else:
		base_lod = 2
	
	# Apply adaptive LOD adjustments
	if adaptive_lod:
		base_lod = clamp(base_lod + _current_lod_level, min_lod_level, max_lod_level)
	
	return base_lod

# Fast LOD computation using squared distance to avoid sqrt
func compute_lod_fast(camera_pos: Vector2, target_pos: Vector2) -> int:
	var d_sq := camera_pos.distance_squared_to(target_pos)
	var near_sq := near_distance * near_distance
	var far_sq := far_distance * far_distance
	
	var base_lod = 0
	if d_sq < near_sq:
		base_lod = 0
	elif d_sq < far_sq:
		base_lod = 1
	else:
		base_lod = 2
	
	if adaptive_lod:
		base_lod = clamp(base_lod + _current_lod_level, min_lod_level, max_lod_level)
	
	return base_lod

func _update_frame_time(delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	if _last_frame_time > 0:
		var frame_time = current_time - _last_frame_time
		_frame_times[_frame_time_index] = frame_time
		_frame_time_index = (_frame_time_index + 1) % _frame_time_history_size
	_last_frame_time = current_time

func _adjust_lod_level() -> void:
	var avg_frame_time = 0.0
	var valid_samples = 0
	
	for frame_time in _frame_times:
		if frame_time > 0:
			avg_frame_time += frame_time
			valid_samples += 1
	
	if valid_samples == 0:
		return
	
	avg_frame_time /= valid_samples
	var current_fps = 1000.0 / avg_frame_time
	
	# Adjust LOD based on performance
	if current_fps < target_fps * 0.8:
		# Performance is poor, increase LOD level (reduce quality)
		_current_lod_level = min(_current_lod_level + 1, max_lod_level)
	elif current_fps > target_fps * 1.2:
		# Performance is good, decrease LOD level (increase quality)
		_current_lod_level = max(_current_lod_level - 1, min_lod_level)

func get_performance_stats() -> Dictionary:
	var avg_frame_time = 0.0
	var valid_samples = 0
	
	for frame_time in _frame_times:
		if frame_time > 0:
			avg_frame_time += frame_time
			valid_samples += 1
	
	if valid_samples > 0:
		avg_frame_time /= valid_samples
	
	return {
		"current_fps": 1000.0 / avg_frame_time if avg_frame_time > 0 else 0,
		"avg_frame_time": avg_frame_time,
		"current_lod_level": _current_lod_level,
		"adaptive_lod": adaptive_lod
	}

func set_lod_level(level: int) -> void:
	_current_lod_level = clamp(level, min_lod_level, max_lod_level)

func reset_lod() -> void:
	_current_lod_level = 1


