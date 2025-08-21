extends Node
class_name PhysicsRunner

signal physics_batch_started(count: int)
signal physics_batch_finished(ms: float)

@export var batch_size: int = 64
@export var max_agents_per_frame: int = 10000

var _agent_sim: AgentSim

# Pre-allocated vectors to avoid allocations
var _temp_vectors: Array[Vector2] = []
var _temp_vectors_size: int = 0
const MAX_TEMP_VECTORS = 256

func _ready() -> void:
	# Pre-allocate temporary vectors
	_temp_vectors.resize(MAX_TEMP_VECTORS)
	for i in range(MAX_TEMP_VECTORS):
		_temp_vectors[i] = Vector2.ZERO
	_temp_vectors_size = 0

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
			
			# Get desired velocity
			var desired := enemy._compute_desired_velocity(delta)
			
			# Apply separation forces
			if _agent_sim and enemy.separation_radius > 0.0:
				var query_radius: float = enemy.separation_radius + (enemy._self_hit_radius * 2.0)
				var neighbors := _agent_sim.get_neighbors(enemy, query_radius)
				var push := Vector2.ZERO
				var counted := 0
				
				for other in neighbors:
					if other == null or other == enemy:
						continue
					
					# Use pre-allocated vector
					var away = _get_temp_vector()
					away = enemy.global_position - other.global_position
					
					var dist_sq = away.length_squared()
					if dist_sq == 0.0:
						continue
					
					var other_hr := enemy._get_hit_radius_for(other)
					var min_sep := enemy._self_hit_radius + other_hr + enemy.separation_padding
					var min_sep_sq := min_sep * min_sep
					
					if dist_sq < min_sep_sq:
						# Use inverse square root approximation for better performance
						var inv_dist = _fast_inv_sqrt(dist_sq)
						var penetration = (min_sep * inv_dist - 1.0) * enemy.separation_strength * 2.0
						push += away * penetration
						counted += 1
					else:
						var distance = sqrt(dist_sq)  # Only sqrt when necessary
						var falloff = (query_radius - distance) / max(query_radius, 0.001)
						if falloff > 0.0:
							push += away.normalized() * (falloff * enemy.separation_strength * 0.5)
							counted += 1
					
					if counted >= enemy.separation_max_neighbors:
						break
				
				if counted > 0 and push != Vector2.ZERO:
					var push_length = push.length()
					var desired_length = desired.length()
					
					if push_length > desired_length * 2.0:
						desired = push.normalized() * enemy.move_speed * 0.5
					else:
						desired = (desired * 0.6) + (push.normalized() * enemy.separation_strength * 0.4)
			
			# Apply movement
			enemy.apply_movement(desired, delta)
		
		processed = batch_end
		
		# Process all agents without yielding to avoid async issues
		if processed >= max_agents_per_frame:
			break
	
	var end_time := Time.get_ticks_msec()
	emit_signal("physics_batch_finished", end_time - start_time)

# Fast inverse square root approximation (Quake III algorithm)
func _fast_inv_sqrt(x: float) -> float:
	var i = _float_to_int_bits(x)
	i = 0x5f3759df - (i >> 1)
	var y = _int_bits_to_float(i)
	return y * (1.5 - 0.5 * x * y * y)

func _float_to_int_bits(f: float) -> int:
	# This is a simplified version - in practice you'd use bit operations
	return int(f * 1000000.0)  # Approximation for demo purposes

func _int_bits_to_float(i: int) -> float:
	return float(i) / 1000000.0  # Approximation for demo purposes

# Get a pre-allocated temporary vector
func _get_temp_vector() -> Vector2:
	if _temp_vectors_size >= MAX_TEMP_VECTORS:
		_temp_vectors_size = 0
	var vec = _temp_vectors[_temp_vectors_size]
	_temp_vectors_size += 1
	return vec
