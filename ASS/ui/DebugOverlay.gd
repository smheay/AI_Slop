extends Control
class_name DebugOverlay

@export var systems_runner_path: NodePath
@export var agent_sim_path: NodePath

var _systems_runner: SystemsRunner
var _agent_sim: AgentSim
var _fps_label: Label
var _agent_count_label: Label
var _performance_label: Label
var _lod_label: Label
var _spatial_hash_label: Label

func _ready() -> void:
	# Create UI elements
	_create_ui()
	
	# Find systems
	_systems_runner = get_node_or_null(systems_runner_path) as SystemsRunner
	_agent_sim = get_node_or_null(agent_sim_path) as AgentSim
	
	# Auto-find if not set
	if not _systems_runner:
		_systems_runner = get_tree().current_scene.get_node_or_null("SystemsRunner") as SystemsRunner
	if not _agent_sim:
		_agent_sim = get_tree().current_scene.get_node_or_null("AgentSim") as AgentSim

func _create_ui() -> void:
	# FPS Label
	_fps_label = Label.new()
	_fps_label.text = "FPS: 0"
	_fps_label.position = Vector2(10, 10)
	_fps_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_fps_label)
	
	# Agent Count Label
	_agent_count_label = Label.new()
	_agent_count_label.text = "Agents: 0"
	_agent_count_label.position = Vector2(10, 30)
	_agent_count_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(_agent_count_label)
	
	# Performance Label
	_performance_label = Label.new()
	_performance_label.text = "Performance: --"
	_performance_label.position = Vector2(10, 50)
	_performance_label.add_theme_color_override("font_color", Color.CYAN)
	add_child(_performance_label)
	
	# LOD Label
	_lod_label = Label.new()
	_lod_label.text = "LOD: --"
	_lod_label.position = Vector2(10, 70)
	_lod_label.add_theme_color_override("font_color", Color.GREEN)
	add_child(_lod_label)
	
	# Spatial Hash Label
	_spatial_hash_label = Label.new()
	_spatial_hash_label.text = "Spatial Hash: --"
	_spatial_hash_label.position = Vector2(10, 90)
	_spatial_hash_label.add_theme_color_override("font_color", Color.ORANGE)
	add_child(_spatial_hash_label)

func _process(_delta: float) -> void:
	_update_fps()
	_update_agent_count()
	_update_performance()
	_update_lod_info()
	_update_spatial_hash_info()

func _update_fps() -> void:
	var fps := Engine.get_frames_per_second()
	_fps_label.text = "FPS: " + str(fps)
	
	# Color code FPS
	if fps >= 55:
		_fps_label.add_theme_color_override("font_color", Color.GREEN)
	elif fps >= 30:
		_fps_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_fps_label.add_theme_color_override("font_color", Color.RED)

func _update_agent_count() -> void:
	var count := 0
	if _agent_sim:
		count = _agent_sim.get_agent_count()
	
	_agent_count_label.text = "Agents: " + str(count)
	
	# Color code agent count
	if count < 1000:
		_agent_count_label.add_theme_color_override("font_color", Color.GREEN)
	elif count < 3000:
		_agent_count_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_agent_count_label.add_theme_color_override("font_color", Color.ORANGE)

func _update_performance() -> void:
	var memory := OS.get_static_memory_usage() / 1024 / 1024  # MB
	var cpu := OS.get_processor_count()
	
	_performance_label.text = "Memory: " + str(memory) + "MB | CPU: " + str(cpu) + " cores"

func _update_lod_info() -> void:
	if not _agent_sim:
		_lod_label.text = "LOD: Not Available"
		return
	
	var agents := _agent_sim.get_agents()
	var lod_counts := {0: 0, 1: 0, 2: 0}
	
	# Count agents by LOD level (simplified - would need camera reference for real LOD)
	var near_count := 0
	var far_count := 0
	
	for agent in agents:
		if agent is BaseEnemy:
			var enemy := agent as BaseEnemy
			if enemy._current_lod == 0:
				near_count += 1
			elif enemy._current_lod == 2:
				far_count += 1
			else:
				lod_counts[1] += 1
	
	lod_counts[0] = near_count
	lod_counts[2] = far_count
	
	_lod_label.text = "LOD: Near(" + str(lod_counts[0]) + ") Mid(" + str(lod_counts[1]) + ") Far(" + str(lod_counts[2]) + ")"

func _update_spatial_hash_info() -> void:
	if not _agent_sim:
		_spatial_hash_label.text = "Spatial Hash: Not Available"
		return
	
	var spatial_hash = _agent_sim.get_spatial_hash()
	if spatial_hash and spatial_hash is SpatialHash2D:
		var dirty_count := spatial_hash.get_dirty_count()
		_spatial_hash_label.text = "Spatial Hash: " + str(dirty_count) + " dirty"
		
		# Color code based on dirty count
		if dirty_count < 100:
			_spatial_hash_label.add_theme_color_override("font_color", Color.GREEN)
		elif dirty_count < 500:
			_spatial_hash_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			_spatial_hash_label.add_theme_color_override("font_color", Color.RED)
	else:
		_spatial_hash_label.text = "Spatial Hash: Not Available"


