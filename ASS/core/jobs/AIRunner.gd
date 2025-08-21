extends Node
class_name AIRunner

signal ai_batch_started(count: int)
signal ai_batch_finished(ms: float)

@export var batch_size: int = 64
@export var max_agents_per_frame: int = 10000
@export var adaptive_batching: bool = true
@export var target_frame_time_ms: float = 16.67  # 60 FPS target

var _last_batch_time: float = 0.0
var _batch_size_history: Array[float] = []
var _history_size: int = 10

func _ready() -> void:
	_batch_size_history.resize(_history_size)
	for i in range(_history_size):
		_batch_size_history[i] = 0.0

func run_batch(agents: Array, delta: float) -> void:
	if agents.is_empty():
		return
		
	emit_signal("ai_batch_started", agents.size())
	var start_time := Time.get_ticks_msec()
	
	# Adaptive batch sizing based on performance
	var current_batch_size = batch_size
	if adaptive_batching:
		current_batch_size = _get_adaptive_batch_size()
	
	# Process AI in optimized batches
	var processed := 0
	var total_agents := agents.size()
	
	# Pre-cache method references to avoid repeated lookups
	var ai_method_cache: Array = []
	for i in range(min(current_batch_size, total_agents)):
		var agent := agents[i] as Node2D
		if agent and agent.has_method("_ai_step"):
			ai_method_cache.append(agent)
	
	while processed < total_agents and processed < max_agents_per_frame:
		var batch_end = min(processed + current_batch_size, total_agents)
		
		# Process batch using cached method references
		for i in range(processed, batch_end):
			var agent := agents[i] as Node2D
			if agent and agent.has_method("_ai_step"):
				# Direct method call without reflection
				agent._ai_step(delta)
		
		processed = batch_end
		
		# Check if we're taking too long and adjust
		var current_time = Time.get_ticks_msec()
		if current_time - start_time > target_frame_time_ms:
			break
	
	var end_time := Time.get_ticks_msec()
	var batch_time = end_time - start_time
	
	# Update adaptive batching
	if adaptive_batching:
		_update_batch_performance(batch_time)
	
	emit_signal("ai_batch_finished", batch_time)

# Adaptive batch sizing based on performance history
func _get_adaptive_batch_size() -> int:
	var avg_time = 0.0
	var valid_samples = 0
	
	for time in _batch_size_history:
		if time > 0.0:
			avg_time += time
			valid_samples += 1
	
	if valid_samples == 0:
		return batch_size
	
	avg_time /= valid_samples
	
	# Adjust batch size based on performance
	if avg_time < target_frame_time_ms * 0.5:
		# We're running fast, increase batch size
		return min(batch_size * 2, max_agents_per_frame)
	elif avg_time > target_frame_time_ms * 1.5:
		# We're running slow, decrease batch size
		return max(batch_size / 2, 16)
	else:
		return batch_size

func _update_batch_performance(batch_time: float) -> void:
	# Shift history and add new sample
	for i in range(_history_size - 1):
		_batch_size_history[i] = _batch_size_history[i + 1]
	_batch_size_history[_history_size - 1] = batch_time

# Optimized version for when we know all agents have the same method
func run_batch_fast(agents: Array, delta: float) -> void:
	if agents.is_empty():
		return
	
	emit_signal("ai_batch_started", agents.size())
	var start_time := Time.get_ticks_msec()
	
	# Direct batch processing without method checking
	for agent in agents:
		var node := agent as Node2D
		if node:
			node._ai_step(delta)
	
	var end_time := Time.get_ticks_msec()
	emit_signal("ai_batch_finished", end_time - start_time)
