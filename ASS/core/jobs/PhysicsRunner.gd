extends Node
class_name PhysicsRunner

signal physics_batch_started(count: int)
signal physics_batch_finished(ms: float)

@export var batch_size: int = 64
@export var max_agents_per_frame: int = 10000

func integrate(agents: Array, delta: float) -> void:
	if agents.is_empty():
		return
		
	emit_signal("physics_batch_started", agents.size())
	var start_time := Time.get_ticks_msec()
	
	# Process agents in batches to avoid frame stalls
	var processed := 0
	var total_agents := agents.size()
	
	while processed < total_agents and processed < max_agents_per_frame:
		var batch_end = min(processed + batch_size, total_agents)
		
		for i in range(processed, batch_end):
			var agent := agents[i] as Node2D
			if agent and agent.has_method("_physics_step"):
				agent.call("_physics_step", delta)
		
		processed = batch_end
		
		# Process all agents without yielding to avoid async issues
		if processed >= max_agents_per_frame:
			break
	
	var end_time := Time.get_ticks_msec()
	emit_signal("physics_batch_finished", end_time - start_time)
