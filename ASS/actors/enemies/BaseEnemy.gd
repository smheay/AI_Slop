extends CharacterBody2D
class_name BaseEnemy

@export var move_speed: float = 120.0
@export var damageable_path: NodePath
@export var separation_radius: float = 24.0
@export var separation_strength: float = 80.0
@export var separation_max_neighbors: int = 6
@export var separation_padding: float = 2.0

var _damageable: Node
var _target: Node2D
var _sh: SpatialHash2D
var _self_hit_radius: float = 12.0

func _ready() -> void:
    _damageable = get_node_or_null(damageable_path)
    if _damageable and _damageable is Damageable:
        (_damageable as Damageable).died.connect(_on_died)
        _self_hit_radius = (_damageable as Damageable).hit_radius
    _sh = get_tree().current_scene.get_node_or_null("SystemsRunner/AgentSim/SpatialHash2D") as SpatialHash2D
    if _sh:
        _sh.insert(self)
        # Force initial separation if spawning on top of others
        call_deferred("_force_initial_separation")

func _on_died(source: Node) -> void:
    if _sh:
        _sh.remove(self)
    queue_free()

func _physics_process(delta: float) -> void:
    if _target == null:
        var players := get_tree().get_nodes_in_group("player")
        if players.size() > 0:
            _target = players[0] as Node2D
    var desired := _compute_desired_velocity(delta)
    # Separation using spatial hash neighbors (prevents stacking even with physics)
    if _sh and separation_radius > 0.0:
        var query_radius: float = separation_radius + (_self_hit_radius * 2.0)
        var neighbors := _sh.query_radius(global_position, query_radius)
        var push := Vector2.ZERO
        var counted := 0
        for n in neighbors:
            var other := n as Node2D
            if other == null or other == self:
                continue
            var away := global_position - other.global_position
            var distance: float = away.length()
            if distance == 0.0:
                continue
            var other_hr: float = _get_hit_radius_for(other)
            var min_separation: float = _self_hit_radius + other_hr + separation_padding
            if distance < min_separation:
                # Much stronger push for overlapping enemies
                var penetration: float = (min_separation - distance) / max(min_separation, 0.001)
                push += away.normalized() * (penetration * separation_strength * 2.0)
                counted += 1
            elif distance < query_radius:
                # Stronger falloff push within neighborhood
                var falloff: float = (query_radius - distance) / query_radius
                push += away.normalized() * (falloff * separation_strength * 0.5)
                counted += 1
            if counted >= separation_max_neighbors:
                break
        if counted > 0 and push != Vector2.ZERO:
            # Prioritize separation over movement when overlapping
            if push.length() > desired.length() * 2.0:
                desired = push.normalized() * move_speed * 0.5
            else:
                desired = (desired * 0.6) + (push.normalized() * separation_strength * 0.4)
    velocity = desired.limit_length(move_speed)
    move_and_slide()
    if _sh:
        _sh.move(self)


func _get_hit_radius_for(node: Node2D) -> float:
    var dmg := node.get_node_or_null("Damageable")
    if dmg and dmg is Damageable:
        return (dmg as Damageable).hit_radius
    return 12.0

func _force_initial_separation() -> void:
    if not _sh:
        return
    var query_radius: float = separation_radius * 2.0
    var neighbors := _sh.query_radius(global_position, query_radius)
    var total_push := Vector2.ZERO
    var count := 0
    
    for n in neighbors:
        var other := n as Node2D
        if other == null or other == self:
            continue
        var away := global_position - other.global_position
        var distance := away.length()
        if distance < 1.0:  # Very close overlap
            var push_strength := separation_strength * 2.0  # Double strength for initial separation
            total_push += away.normalized() * push_strength
            count += 1
        elif distance < query_radius:
            var falloff := (query_radius - distance) / query_radius
            total_push += away.normalized() * (separation_strength * falloff)
            count += 1
    
    if count > 0:
        global_position += total_push.normalized() * 32.0  # Move away from cluster

func _compute_desired_velocity(delta: float) -> Vector2:
    if _target:
        return (_target.global_position - global_position).normalized() * move_speed
    return Vector2.ZERO



