extends CharacterBody2D
class_name BaseEnemy

# Movement properties
@export var move_speed: float = 100.0
@export var max_speed: float = 150.0
@export var acceleration: float = 200.0
@export var friction: float = 0.9

# Collision properties
@export var _self_hit_radius: float = 50.0
@export var separation_radius: float = 80.0
@export var separation_strength: float = 100.0
@export var separation_padding: float = 10.0
@export var separation_max_neighbors: int = 6

# Performance optimization
@export var update_frequency: int = 1  # Only update every N frames
@export var lod_level: int = 0  # Level of detail for rendering

# Internal state
var velocity: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var is_active: bool = true
var _frame_counter: int = 0

# LOD and performance
var _last_update_frame: int = 0
var _cached_desired_velocity: Vector2 = Vector2.ZERO
var _velocity_cache_valid: bool = false

# Collision system reference
var _hierarchical_collision: HierarchicalCollision

func _ready() -> void:
	# Randomize starting frame to distribute updates
	_frame_counter = randi() % update_frequency
	
	# Get reference to collision system
	_hierarchical_collision = get_node_or_null("../HierarchicalCollision") as HierarchicalCollision

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	# Only update every N frames for performance
	_frame_counter += 1
	if _frame_counter % update_frequency != 0:
		return
	
	# Update AI and movement
	_ai_step(delta)

# Main AI step - called by AI runner
func _ai_step(delta: float) -> void:
	if not is_active:
		return
	
	# Compute desired velocity (cached for performance)
	var desired = _compute_desired_velocity(delta)
	
	# Apply hierarchical collision response if available
	if _hierarchical_collision:
		desired = _hierarchical_collision.compute_hierarchical_collision_response(self, desired, delta)
	
	# Apply movement
	apply_movement(desired, delta)

# Compute desired velocity (can be overridden by subclasses)
func _compute_desired_velocity(delta: float) -> Vector2:
	# Simple movement toward target
	var direction = (target_position - global_position).normalized()
	return direction * move_speed

# Apply movement with physics
func apply_movement(desired_velocity: Vector2, delta: float) -> void:
	# Apply acceleration toward desired velocity
	var acceleration_vector = (desired_velocity - velocity) * acceleration * delta
	velocity += acceleration_vector
	
	# Apply friction
	velocity *= friction
	
	# Clamp to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
	# Use CharacterBody2D's move_and_slide for proper collision handling
	velocity = move_and_slide(velocity)

# Get hit radius for this enemy
func _get_self_hit_radius() -> float:
	return _self_hit_radius

# Get hit radius for another enemy (can be overridden for different enemy types)
func _get_hit_radius_for(other: Node2D) -> float:
	if other.has_method("_get_self_hit_radius"):
		return other._get_self_hit_radius()
	return 50.0  # Default

# Set target position
func set_target(pos: Vector2) -> void:
	target_position = pos

# Get current velocity
func get_velocity() -> Vector2:
	return velocity

# Set velocity directly (for external control)
func set_velocity(vel: Vector2) -> void:
	velocity = vel

# Activate/deactivate enemy
func set_active(active: bool) -> void:
	is_active = active
	if not active:
		velocity = Vector2.ZERO

# Set LOD level for performance
func set_lod_level(level: int) -> void:
	lod_level = level
	# Adjust update frequency based on LOD
	update_frequency = max(1, level + 1)

# Get performance stats
func get_performance_stats() -> Dictionary:
	return {
		"update_frequency": update_frequency,
		"lod_level": lod_level,
		"is_active": is_active,
		"velocity": velocity,
		"hit_radius": _self_hit_radius
	}

# Cleanup when removed
func _exit_tree() -> void:
	# Notify systems that this enemy is being removed
	if _hierarchical_collision:
		_hierarchical_collision.clear_enemy_cache(self)
