extends CharacterBody2D
class_name BaseEnemy
signal despawn_requested(enemy: Node2D)

@export var move_speed: float = 120.0
@export var damageable_path: NodePath
@export var separation_radius: float = 24.0
@export var separation_strength: float = 80.0
@export var separation_max_neighbors: int = 6
@export var separation_padding: float = 2.0

var _damageable: Node
var _target: Node2D
var _self_hit_radius: float = 12.0
var _agent_sim: AgentSim

func _ready() -> void:
	_damageable = get_node_or_null(damageable_path)
	if _damageable and _damageable is Damageable:
		(_damageable as Damageable).died.connect(_on_died)
		_self_hit_radius = (_damageable as Damageable).hit_radius
	
	# Register with the batch system - try multiple paths
	_agent_sim = get_tree().current_scene.get_node_or_null("SystemsRunner/AgentSim") as AgentSim
	if not _agent_sim:
		_agent_sim = get_tree().current_scene.get_node_or_null("AgentSim") as AgentSim
	if not _agent_sim:
		_agent_sim = _find_agent_sim_in_tree(get_tree().current_scene)
	
	if _agent_sim:
		_agent_sim.register_agent(self)
		Log.info("BaseEnemy: Successfully registered with AgentSim")
	else:
		Log.error("BaseEnemy: Could not find AgentSim anywhere in scene tree")
	
	# Force initial separation if spawning on top of others
	call_deferred("_force_initial_separation")

func _on_died(source: Node) -> void:
	# Delegate despawn lifecycle to spawner/pool
	emit_signal("despawn_requested", self)

# Called by the batch system (PhysicsRunner owns movement)
func _physics_step(delta: float) -> void:
	if _target == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_target = players[0] as Node2D
	# Movement is applied by PhysicsRunner.apply_movement

# Called by the batch system for AI decisions
func _ai_step(delta: float) -> void:
	if _target == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_target = players[0] as Node2D

func get_separation_radius() -> float:
	return separation_radius

func _get_hit_radius_for(node: Node2D) -> float:
	var dmg := node.get_node_or_null("Damageable")
	if dmg and dmg is Damageable:
		return (dmg as Damageable).hit_radius
	return 12.0

func _force_initial_separation() -> void:
	if not _agent_sim:
		return
	var query_radius: float = separation_radius * 2.0
	var neighbors := _agent_sim.get_neighbors(self, query_radius)
	var total_push := Vector2.ZERO
	var count := 0
	for other in neighbors:
		if other == null or other == self:
			continue
		var away = global_position - other.global_position
		var distance = away.length()
		if distance < 1.0:
			var push_strength := separation_strength * 2.0
			total_push += away.normalized() * push_strength
			count += 1
		elif distance < query_radius:
			var falloff = (query_radius - distance) / query_radius
			total_push += away.normalized() * (falloff * separation_strength)
			count += 1
	if count > 0:
		global_position += total_push.normalized() * 32.0

func _find_agent_sim_in_tree(node: Node) -> AgentSim:
	if node is AgentSim:
		return node as AgentSim
	for child in node.get_children():
		var result = _find_agent_sim_in_tree(child)
		if result:
			return result
	return null

func _compute_desired_velocity(delta: float) -> Vector2:
	if _target:
		return (_target.global_position - global_position).normalized() * move_speed
	return Vector2.ZERO

func apply_movement(proposed_velocity: Vector2, delta: float) -> void:
	velocity = proposed_velocity.limit_length(move_speed)
	move_and_slide()
