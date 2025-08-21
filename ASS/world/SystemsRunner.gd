extends Node
class_name SystemsRunner

@export var agent_sim_path: NodePath
@export var ai_runner_path: NodePath
@export var physics_runner_path: NodePath

var _agent_sim: AgentSim
var _ai_runner: AIRunner
var _physics_runner: PhysicsRunner

func _ready() -> void:
	_agent_sim = get_node(agent_sim_path)
	_ai_runner = get_node(ai_runner_path)
	_physics_runner = get_node(physics_runner_path)

func step_frame(delta: float) -> void:
	# 1) AI
	_ai_runner.run_batch(_get_agents(), delta)
	# 2) Simulation
	_agent_sim.step_simulation(delta)
	# 3) Physics
	_physics_runner.integrate(_get_agents(), delta)

func _get_agents() -> Array:
	# TODO: Return array of agents from AgentSim
	return []


