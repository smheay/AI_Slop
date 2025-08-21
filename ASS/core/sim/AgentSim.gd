extends Node
class_name AgentSim

signal agents_updated(count: int)

@export var spatial_hash: NodePath

var _agents: Array[Node2D] = []
var _spatial_hash: SpatialHash2D

func _ready() -> void:
	_spatial_hash = get_node_or_null(spatial_hash) as SpatialHash2D

func register_agent(agent: Node2D) -> void:
	if agent not in _agents:
		_agents.append(agent)
		if _spatial_hash:
			_spatial_hash.insert(agent)
		emit_signal("agents_updated", _agents.size())

func unregister_agent(agent: Node2D) -> void:
	if agent in _agents:
		_agents.erase(agent)
		if _spatial_hash:
			_spatial_hash.remove(agent)
		emit_signal("agents_updated", _agents.size())

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
	return _spatial_hash.query_radius(agent.global_position, radius)

func sync_from_nodes(delta: float) -> void:
	# Keep a single code path; sync is equivalent to step_simulation.
	step_simulation(delta)


