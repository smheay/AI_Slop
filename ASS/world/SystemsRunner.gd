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
var _lod_controller: LODController
var _camera: Camera2D

func _ready() -> void:
	# Auto-find all systems instead of relying on NodePath exports
	_agent_sim = get_node_or_null("AgentSim") as AgentSim
	_ai_runner = get_node_or_null("AIRunner") as AIRunner
	_physics_runner = get_node_or_null("PhysicsRunner") as PhysicsRunner
	_lod_controller = get_node_or_null("LODController") as LODController
	
	# Find camera for LOD calculations
	_camera = _find_camera()
	
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
	
	# Inject dependencies
	_physics_runner.set_agent_sim(_agent_sim)
	
	# Verify we're in the scene tree
	Log.info("SystemsRunner ready. Scene tree: " + str(get_tree().current_scene.name))
	Log.info("SystemsRunner: All systems found successfully")

func _find_camera() -> Camera2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player := players[0] as Node2D
		if player:
			return player.get_node_or_null("Camera2D") as Camera2D
	return null

func _physics_process(delta: float) -> void:
	# Process all systems directly without async complexity
	var agents = _get_agents()
	
	# Log agent count every 5 seconds
	if Engine.get_process_frames() % 300 == 0:
		Log.info("SystemsRunner: Frame " + str(Engine.get_process_frames()) + ", Agents: " + str(agents.size()))
	
	if agents.is_empty():
		return
	
	# Update camera reference if needed
	if not _camera:
		_camera = _find_camera()
	
	# 1) AI decisions with LOD
	_process_ai_with_lod(agents, delta)
	
	# 2) Physics movement with LOD
	_process_physics_with_lod(agents, delta)
	
	# 3) Batch update spatial hash (only when needed)
	if _agent_sim and _agent_sim.get_spatial_hash():
		var spatial_hash = _agent_sim.get_spatial_hash() as SpatialHash2D
		if spatial_hash:
			spatial_hash.update_dirty_agents()

func _process_ai_with_lod(agents: Array, delta: float) -> void:
	if not _lod_controller or not _camera:
		_ai_runner.run_batch(agents, delta)
		return
	
	var camera_pos := _camera.global_position
	var frame_count := Engine.get_process_frames()
	
	# Separate agents by LOD level
	var agents_by_lod := {0: [], 1: [], 2: []}
	
	for agent in agents:
		if not is_instance_valid(agent):
			continue
		var lod := _lod_controller.compute_lod(camera_pos, agent.global_position)
		if _lod_controller.should_process_agent(agent, camera_pos, frame_count):
			agents_by_lod[lod].append(agent)
	
	# Process each LOD level with appropriate batch sizes
	for lod in [0, 1, 2]:
		var lod_agents: Array = agents_by_lod[lod]
		if lod_agents.is_empty():
			continue
		
		var config := _lod_controller.get_processing_level(lod)
		if config.ai_enabled:
			_ai_runner.run_batch(lod_agents, delta)

func _process_physics_with_lod(agents: Array, delta: float) -> void:
	if not _lod_controller or not _camera:
		_physics_runner.integrate(agents, delta)
		return
	
	var camera_pos := _camera.global_position
	var frame_count := Engine.get_process_frames()
	
	# Separate agents by LOD level
	var agents_by_lod := {0: [], 1: [], 2: []}
	
	for agent in agents:
		if not is_instance_valid(agent):
			continue
		var lod := _lod_controller.compute_lod(camera_pos, agent.global_position)
		if _lod_controller.should_process_agent(agent, camera_pos, frame_count):
			agents_by_lod[lod].append(agent)
	
	# Process each LOD level with appropriate batch sizes
	for lod in [0, 1, 2]:
		var lod_agents: Array = agents_by_lod[lod]
		if lod_agents.is_empty():
			continue
		
		var config := _lod_controller.get_processing_level(lod)
		if config.physics_enabled:
			_physics_runner.integrate(lod_agents, delta)

func _get_agents() -> Array:
	if _agent_sim:
		return _agent_sim.get_agents()
	return []
