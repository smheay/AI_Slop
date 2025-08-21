extends Node
class_name AgentSim

signal agents_updated(count: int)

@export var spatial_hash: NodePath
@export var batch_update_threshold: int = 10  # Only emit signals after batch operations
@export var use_fast_queries: bool = true     # Use optimized spatial hash queries

var _agents: Array[Node2D] = []
var _spatial_hash: SpatialHash2D
var _pending_updates: int = 0
var _last_emit_count: int = 0

func _ready() -> void:
	_spatial_hash = get_node_or_null(spatial_hash) as SpatialHash2D

func register_agent(agent: Node2D) -> void:
	if agent not in _agents:
		_agents.append(agent)
		if _spatial_hash:
			_spatial_hash.insert(agent)
		
		_pending_updates += 1
		_maybe_emit_update()

func unregister_agent(agent: Node2D) -> void:
	if agent in _agents:
		_agents.erase(agent)
		if _spatial_hash:
			_spatial_hash.remove(agent)
		
		_pending_updates += 1
		_maybe_emit_update()

# Batch registration for better performance
func register_agents_batch(agents: Array[Node2D]) -> void:
	var added_count = 0
	for agent in agents:
		if agent not in _agents:
			_agents.append(agent)
			if _spatial_hash:
				_spatial_hash.insert(agent)
			added_count += 1
	
	if added_count > 0:
		_pending_updates += added_count
		_maybe_emit_update()

# Batch unregistration for better performance
func unregister_agents_batch(agents: Array[Node2D]) -> void:
	var removed_count = 0
	for agent in agents:
		if agent in _agents:
			_agents.erase(agent)
			if _spatial_hash:
				_spatial_hash.remove(agent)
			removed_count += 1
	
	if removed_count > 0:
		_pending_updates += removed_count
		_maybe_emit_update()

func step_simulation(delta: float) -> void:
	# Update spatial hash positions for all agents
	if _spatial_hash:
		for agent in _agents:
			if is_instance_valid(agent):
				_spatial_hash.move(agent)
	# Do not emit agents_updated every frame; this is emitted on register/unregister.

func get_agents() -> Array:
	# Return the internal list directly to avoid per-frame allocations.
	# Treat as read-only outside of AgentSim.
	return _agents

func get_agent_count() -> int:
	return _agents.size()

func get_neighbors(agent: Node2D, radius: float) -> Array:
	if _spatial_hash == null:
		return []
	
	# Use fast queries when available
	if use_fast_queries and _spatial_hash.has_method("query_radius_fast"):
		return _spatial_hash.query_radius_fast(agent.global_position, radius)
	else:
		return _spatial_hash.query_radius(agent.global_position, radius)

func sync_from_nodes(delta: float) -> void:
	# Keep a single code path; sync is equivalent to step_simulation.
	step_simulation(delta)

# Only emit signals after batch operations to reduce overhead
func _maybe_emit_update() -> void:
	if _pending_updates >= batch_update_threshold or _agents.size() != _last_emit_count:
		emit_signal("agents_updated", _agents.size())
		_pending_updates = 0
		_last_emit_count = _agents.size()

# Force emit update signal
func force_emit_update() -> void:
	emit_signal("agents_updated", _agents.size())
	_pending_updates = 0
	_last_emit_count = _agents.size()

# Get agents in a specific area (optimized)
func get_agents_in_area(center: Vector2, radius: float) -> Array:
	if _spatial_hash == null:
		return []
	
	# Use fast queries when available
	if use_fast_queries and _spatial_hash.has_method("query_radius_fast"):
		return _spatial_hash.query_radius_fast(center, radius)
	else:
		return _spatial_hash.query_radius(center, radius)


