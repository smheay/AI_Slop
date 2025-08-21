extends Node
class_name SystemsRunner

# Auto-attach script if not already attached
func _enter_tree() -> void:
	if get_script() == null:
		var script_path = "res://world/SystemsRunner.gd"
		var script = load(script_path)
		if script:
			set_script(script)
			Log.info("SystemsRunner: Auto-attached script from " + script_path)
		else:
			Log.error("SystemsRunner: Could not load script from " + script_path)

var _agent_sim: AgentSim
var _ai_runner: AIRunner
var _physics_runner: PhysicsRunner

func _ready() -> void:
	# Auto-find all systems instead of relying on NodePath exports
	_agent_sim = get_node_or_null("AgentSim") as AgentSim
	_ai_runner = get_node_or_null("AIRunner") as AIRunner
	_physics_runner = get_node_or_null("PhysicsRunner") as PhysicsRunner
	
	# Verify all systems are found
	if not _agent_sim:
		Log.error("SystemsRunner: AgentSim not found")
		return
	if not _ai_runner:
		Log.error("SystemsRunner: AIRunner not found")
		return
	if not _physics_runner:
		Log.error("SystemsRunner: PhysicsRunner not found")
		return
	
	# Verify we're in the scene tree
	Log.info("SystemsRunner ready. Scene tree: " + str(get_tree().current_scene.name))
	Log.info("SystemsRunner: All systems found successfully")

func _physics_process(delta: float) -> void:
	# Process all systems directly without async complexity
	var agents = _get_agents()
	
	# Log agent count every 5 seconds
	if Engine.get_process_frames() % 300 == 0:
		Log.info("SystemsRunner: Frame " + str(Engine.get_process_frames()) + ", Agents: " + str(agents.size()))
	
	if agents.is_empty():
		return
	
	# 1) AI decisions
	_ai_runner.run_batch(agents, delta)
	
	# 2) Update spatial hash positions
	_agent_sim.step_simulation(delta)
	
	# 3) Physics movement
	_physics_runner.integrate(agents, delta)

func _get_agents() -> Array:
	if _agent_sim:
		return _agent_sim.get_agents()
	return []
