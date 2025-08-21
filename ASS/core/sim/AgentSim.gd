extends Node
class_name AgentSim

signal agents_updated(count: int)

@export var spatial_hash: NodePath
@export var lod_controller: NodePath

var _agents: Array[Node2D] = []

func register_agent(agent: Node2D) -> void:
	_agents.append(agent)

func unregister_agent(agent: Node2D) -> void:
	_agents.erase(agent)

func step_simulation(delta: float) -> void:
	# TODO: Batch update movement/AI (no per-agent _process)
	emit_signal("agents_updated", _agents.size())


