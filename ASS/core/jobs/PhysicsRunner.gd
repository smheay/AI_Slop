extends Node
class_name PhysicsRunner

signal physics_batch_started(count: int)
signal physics_batch_finished(ms: float)

@export var batch_size: int = 64
@export var max_agents_per_frame: int = 10000

var _agent_sim: AgentSim

func set_agent_sim(sim: AgentSim) -> void:
	_agent_sim = sim

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
			var enemy := agents[i] as BaseEnemy
			if enemy == null:
				continue
			# Desired
			var desired := enemy._compute_desired_velocity(delta)
			# Separation via AgentSim neighbors
			if _agent_sim and enemy.separation_radius > 0.0:
				var query_radius: float = enemy.separation_radius + (enemy._self_hit_radius * 2.0)
				var neighbors := _agent_sim.get_neighbors(enemy, query_radius)
				var push := Vector2.ZERO
				var counted := 0
				for other in neighbors:
					if other == null or other == enemy:
						continue
					var away = enemy.global_position - other.global_position
					var dist_sq = away.length_squared()
					if dist_sq == 0.0:
						continue
					var other_hr := enemy._get_hit_radius_for(other)
					var min_sep := enemy._self_hit_radius + other_hr + enemy.separation_padding
					var min_sep_sq := min_sep * min_sep
					if dist_sq < min_sep_sq:
						var distance := sqrt(dist_sq)
						var penetration = (min_sep - distance) / max(min_sep, 0.001)
						push += away.normalized() * (penetration * enemy.separation_strength * 2.0)
						counted += 1
					else:
						var distance := sqrt(dist_sq)
						var falloff = (query_radius - distance) / max(query_radius, 0.001)
						if falloff > 0.0:
							push += away.normalized() * (falloff * enemy.separation_strength * 0.5)
							counted += 1
					if counted >= enemy.separation_max_neighbors:
						break
				if counted > 0 and push != Vector2.ZERO:
					if push.length() > desired.length() * 2.0:
						desired = push.normalized() * enemy.move_speed * 0.5
					else:
						desired = (desired * 0.6) + (push.normalized() * enemy.separation_strength * 0.4)
			# Apply
			enemy.apply_movement(desired, delta)
		
		processed = batch_end
		
		# Process all agents without yielding to avoid async issues
		if processed >= max_agents_per_frame:
			break
	
	var end_time := Time.get_ticks_msec()
	emit_signal("physics_batch_finished", end_time - start_time)
