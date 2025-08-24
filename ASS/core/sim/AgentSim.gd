extends Node
class_name AgentSim

signal agents_updated(count: int)

@export var spatial_hash: NodePath

var _agents: Array[Node2D] = []
var _spatial_hash: SpatialHash2D

func _ready() -> void:
	_spatial_hash = get_node_or_null(spatial_hash) as SpatialHash2D
	
	# Set up periodic cleanup to handle any freed objects
	call_deferred("_setup_periodic_cleanup")

func _setup_periodic_cleanup() -> void:
	# Set up a timer to periodically clean up any invalid references
	var cleanup_timer := Timer.new()
	cleanup_timer.wait_time = 1.0  # Clean up every second
	cleanup_timer.timeout.connect(_periodic_cleanup)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _periodic_cleanup() -> void:
	# Periodic cleanup to catch any freed objects that might have been missed
	if _spatial_hash:
		_spatial_hash.force_cleanup()

func register_agent(agent: Node2D) -> void:
	if not is_instance_valid(agent):
		return
	if agent not in _agents:
		_agents.append(agent)
		if _spatial_hash:
			_spatial_hash.insert(agent)
		emit_signal("agents_updated", _agents.size())

func unregister_agent(agent) -> void:
	if not is_instance_valid(agent):
		return
	if agent in _agents:
		_agents.erase(agent)
		if _spatial_hash:
			_spatial_hash.remove(agent)
		emit_signal("agents_updated", _agents.size())

func step_simulation(delta: float) -> void:
	# Update spatial hash positions for all agents
	if _spatial_hash:
		var i := 0
		while i < _agents.size():
			var agent = _agents[i]
			if is_instance_valid(agent):
				_spatial_hash.move(agent)
				i += 1
			else:
				# Remove invalid agents from the list
				_safe_remove_from_spatial_hash(agent)
				_agents.remove_at(i)
	# Do not emit agents_updated every frame; this is emitted on register/unregister.

func get_agents() -> Array:
	# Clean up invalid agents before returning the list
	_cleanup_invalid_agents()
	# Return the internal list directly to avoid per-frame allocations.
	# Treat as read-only outside of AgentSim.
	return _agents

func _cleanup_invalid_agents() -> void:
	# Remove any invalid agents from the list
	var i := 0
	while i < _agents.size():
		var agent = _agents[i]
		if not is_instance_valid(agent):
			# Remove from spatial hash first (if it was valid before)
			if _spatial_hash:
				# Use a safe removal method that handles freed objects
				_safe_remove_from_spatial_hash(agent)
			# Then remove from agents list
			_agents.remove_at(i)
		else:
			i += 1

func _safe_remove_from_spatial_hash(agent) -> void:
	# Safely remove an agent from spatial hash, handling freed objects
	if _spatial_hash and is_instance_valid(agent):
		_spatial_hash.remove(agent)
	elif _spatial_hash:
		# If agent is freed, we need to clean up the spatial hash manually
		# This is a fallback for when objects are freed unexpectedly
		_cleanup_spatial_hash_references(agent)

func _cleanup_spatial_hash_references(freed_agent) -> void:
	# Clean up any remaining references to freed objects in the spatial hash
	# This is a safety measure for when objects are freed unexpectedly
	if not _spatial_hash:
		return
	
	# Force a cleanup of the spatial hash to remove any invalid references
	_spatial_hash.force_cleanup()

func get_agent_count() -> int:
	return _agents.size()

func get_neighbors(agent: Node2D, radius: float) -> Array:
	if _spatial_hash == null:
		return []
	return _spatial_hash.query_radius(agent.global_position, radius)

func get_spatial_hash() -> SpatialHash2D:
	return _spatial_hash

func sync_from_nodes(delta: float) -> void:
	# Keep a single code path; sync is equivalent to step_simulation.
	step_simulation(delta)
