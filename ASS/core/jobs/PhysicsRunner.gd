extends Node
class_name PhysicsRunner

signal physics_batch_started(count: int)
signal physics_batch_finished(ms: float)

@export var batch_size: int = 128  # Increased for better performance
@export var max_agents_per_frame: int = 15000  # Increased for 5000 enemies

var _agent_sim: AgentSim
var _hierarchical_collision: HierarchicalCollision

# Pre-allocated vectors to avoid allocations
var _temp_vectors: Array[Vector2] = []
var _temp_vectors_size: int = 0
const MAX_TEMP_VECTORS = 512  # Increased for more enemies

func _ready() -> void:
	# Pre-allocate temporary vectors
	_temp_vectors.resize(MAX_TEMP_VECTORS)
	for i in range(MAX_TEMP_VECTORS):
		_temp_vectors[i] = Vector2.ZERO
	_temp_vectors_size = 0
	
	# Get the hierarchical collision system
	_hierarchical_collision = get_node_or_null("../HierarchicalCollision") as HierarchicalCollision

func set_agent_sim(sim: AgentSim) -> void:
	_agent_sim = sim

func integrate(agents: Array, delta: float) -> void:
	if agents.is_empty():
		return
		
	emit_signal("physics_batch_started", agents.size())
	var start_time := Time.get_ticks_msec()
	
	# Process agents in larger batches for better performance
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
			
			# Apply hierarchical collision response instead of old separation system
			if _hierarchical_collision:
				desired = _hierarchical_collision.compute_hierarchical_collision_response(enemy, desired, delta)
			else:
				# Fallback to old system if hierarchical collision not available
				desired = _apply_legacy_separation(enemy, desired)
			
			# Apply movement
			enemy.apply_movement(desired, delta)
		
		processed = batch_end
		
		# Process all agents without yielding to avoid async issues
		if processed >= max_agents_per_frame:
			break
	
	var end_time := Time.get_ticks_msec()
	emit_signal("physics_batch_finished", end_time - start_time)

# Legacy separation system as fallback (simplified for performance)
func _apply_legacy_separation(enemy: BaseEnemy, desired: Vector2) -> Vector2:
	if not _agent_sim or enemy.separation_radius <= 0.0:
		return desired
	
	var query_radius: float = enemy.separation_radius + (enemy._self_hit_radius * 1.5)
	var neighbors := _agent_sim.get_neighbors(enemy, query_radius)
	var push := Vector2.ZERO
	var counted := 0
	const MAX_LEGACY_NEIGHBORS = 4  # Reduced for performance
	
	for other in neighbors:
		if other == null or other == enemy or counted >= MAX_LEGACY_NEIGHBORS:
			continue
		
		var away = enemy.global_position - other.global_position
		var dist_sq = away.length_squared()
		if dist_sq == 0.0:
			continue
		
		var other_hr := enemy._get_hit_radius_for(other)
		var min_sep := enemy._self_hit_radius + other_hr + enemy.separation_padding
		var min_sep_sq := min_sep * min_sep
		
		if dist_sq < min_sep_sq:
			var inv_dist = 1.0 / sqrt(dist_sq)
			var penetration = (min_sep * inv_dist - 1.0) * enemy.separation_strength
			push += away * penetration
			counted += 1
	
	if counted > 0 and push != Vector2.ZERO:
		desired = (desired * 0.7) + (push.normalized() * enemy.separation_strength * 0.3)
	
	return desired

# Get a pre-allocated temporary vector
func _get_temp_vector() -> Vector2:
	if _temp_vectors_size >= MAX_TEMP_VECTORS:
		_temp_vectors_size = 0
	var vec = _temp_vectors[_temp_vectors_size]
	_temp_vectors_size += 1
	return vec
