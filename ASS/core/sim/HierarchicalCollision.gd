extends Node
class_name HierarchicalCollision

# Collision hierarchy based on enemy size
enum EnemySize {
	TINY = 0,    # < 50 units - can't push through anything
	SMALL = 1,   # 50-100 units - can't push through small+
	MEDIUM = 2,  # 100-300 units - can push through tiny, limited through small
	LARGE = 3,   # 300-600 units - can push through tiny+small, limited through medium
	HUGE = 4     # >600 units - can push through everything
}

# Size thresholds
const SIZE_THRESHOLDS = {
	EnemySize.TINY: 50.0,
	EnemySize.SMALL: 100.0,
	EnemySize.MEDIUM: 300.0,
	EnemySize.LARGE: 600.0,
	EnemySize.HUGE: 1000.0
}

# Push-through rules: what each size can push through
const PUSH_THROUGH_RULES = {
	EnemySize.TINY: [],  # Can't push through anything
	EnemySize.SMALL: [EnemySize.TINY],  # Can only push through tiny
	EnemySize.MEDIUM: [EnemySize.TINY, EnemySize.SMALL],  # Can push through tiny+small
	EnemySize.LARGE: [EnemySize.TINY, EnemySize.SMALL, EnemySize.MEDIUM],  # Can push through most
	EnemySize.HUGE: [EnemySize.TINY, EnemySize.SMALL, EnemySize.MEDIUM, EnemySize.LARGE]  # Can push through everything
}

# Push strength multipliers based on size difference
const PUSH_STRENGTH_MULTIPLIERS = {
	EnemySize.TINY: 0.0,    # No push power
	EnemySize.SMALL: 0.3,   # Weak push
	EnemySize.MEDIUM: 0.6,  # Medium push
	EnemySize.LARGE: 1.0,   # Strong push
	EnemySize.HUGE: 2.0     # Bulldozer push
}

var _spatial_hash: SpatialHash2D
var _size_cache: Dictionary = {}  # Cache enemy sizes to avoid recalculation

func _ready() -> void:
	_spatial_hash = get_node_or_null("../SpatialHash2D") as SpatialHash2D

# Get enemy size category based on hit radius
func get_enemy_size(enemy: Node2D) -> EnemySize:
	if not _size_cache.has(enemy):
		var hit_radius = enemy._self_hit_radius if enemy.has_method("_get_self_hit_radius") else 50.0
		_size_cache[enemy] = _get_size_category(hit_radius)
	return _size_cache[enemy]

# Determine size category from hit radius
func _get_size_category(hit_radius: float) -> EnemySize:
	if hit_radius < SIZE_THRESHOLDS[EnemySize.TINY]:
		return EnemySize.TINY
	elif hit_radius < SIZE_THRESHOLDS[EnemySize.SMALL]:
		return EnemySize.SMALL
	elif hit_radius < SIZE_THRESHOLDS[EnemySize.MEDIUM]:
		return EnemySize.MEDIUM
	elif hit_radius < SIZE_THRESHOLDS[EnemySize.LARGE]:
		return EnemySize.LARGE
	else:
		return EnemySize.HUGE

# Check if enemy A can push through enemy B
func can_push_through(enemy_a: Node2D, enemy_b: Node2D) -> bool:
	var size_a = get_enemy_size(enemy_a)
	var size_b = get_enemy_size(enemy_b)
	
	# Check push-through rules
	return size_b in PUSH_THROUGH_RULES[size_a]

# Get push strength multiplier for size difference
func get_push_strength_multiplier(enemy: Node2D) -> float:
	var size = get_enemy_size(enemy)
	return PUSH_STRENGTH_MULTIPLIERS[size]

# Optimized collision response that respects hierarchy
func compute_hierarchical_collision_response(enemy: Node2D, desired_velocity: Vector2, delta: float) -> Vector2:
	var enemy_size = get_enemy_size(enemy)
	var push_strength = get_push_strength_multiplier(enemy)
	
	# Skip collision for tiny enemies (they just get pushed around)
	if enemy_size == EnemySize.TINY:
		return desired_velocity
	
	# Get neighbors for collision detection
	var query_radius = enemy._self_hit_radius * 2.0 if enemy.has_method("_get_self_hit_radius") else 100.0
	var neighbors = _spatial_hash.query_radius_fast(enemy.global_position, query_radius) if _spatial_hash else []
	
	var final_velocity = desired_velocity
	var collision_count = 0
	const MAX_COLLISIONS = 8  # Limit collision checks for performance
	
	for neighbor in neighbors:
		if neighbor == enemy or collision_count >= MAX_COLLISIONS:
			continue
		
		# Check if we can push through this neighbor
		if can_push_through(enemy, neighbor):
			# Apply reduced collision response (can push through)
			var collision_response = _compute_soft_collision(enemy, neighbor, push_strength)
			final_velocity += collision_response
		else:
			# Apply full collision response (can't push through)
			var collision_response = _compute_hard_collision(enemy, neighbor)
			final_velocity += collision_response
		
		collision_count += 1
	
	return final_velocity

# Soft collision for enemies that can push through
func _compute_soft_collision(enemy: Node2D, neighbor: Node2D, push_strength: float) -> Vector2:
	var away = enemy.global_position - neighbor.global_position
	var dist_sq = away.length_squared()
	
	if dist_sq == 0.0:
		return Vector2.ZERO
	
	var enemy_hr = enemy._self_hit_radius if enemy.has_method("_get_self_hit_radius") else 50.0
	var neighbor_hr = neighbor._self_hit_radius if neighbor.has_method("_get_self_hit_radius") else 50.0
	var min_sep = enemy_hr + neighbor_hr + 20.0  # Increased padding for better separation
	var min_sep_sq = min_sep * min_sep
	
	if dist_sq < min_sep_sq:
		# Soft push - increased strength for better separation
		var inv_dist = 1.0 / sqrt(dist_sq)
		var penetration = (min_sep * inv_dist - 1.0) * push_strength * 1.5  # Increased from 0.5
		return away * penetration
	
	return Vector2.ZERO

# Hard collision for enemies that can't push through
func _compute_hard_collision(enemy: Node2D, neighbor: Node2D) -> Vector2:
	var away = enemy.global_position - neighbor.global_position
	var dist_sq = away.length_squared()
	
	if dist_sq == 0.0:
		return Vector2.ZERO
	
	var enemy_hr = enemy._self_hit_radius if enemy.has_method("_get_self_hit_radius") else 50.0
	var neighbor_hr = neighbor._self_hit_radius if neighbor.has_method("_get_self_hit_radius") else 50.0
	var min_sep = enemy_hr + neighbor_hr + 30.0  # Increased padding for hard collision
	var min_sep_sq = min_sep * min_sep
	
	if dist_sq < min_sep_sq:
		# Hard push - increased strength for better separation
		var inv_dist = 1.0 / sqrt(dist_sq)
		var penetration = (min_sep * inv_dist - 1.0) * 3.0  # Increased from 2.0
		return away * penetration
	
	return Vector2.ZERO

# Clear size cache when enemies are removed
func clear_enemy_cache(enemy: Node2D) -> void:
	_size_cache.erase(enemy)

# Batch clear cache for performance
func clear_all_cache() -> void:
	_size_cache.clear()