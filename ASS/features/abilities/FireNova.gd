extends Ability
class_name FireNova

@export var radius: float = 100.0
@export var damage: float = 50.0

func cast(caster: Node, context: Dictionary = {}) -> void:
	if not can_cast():
		return
	emit_signal("cast_started", caster)
	
	# Create visual effect
	var origin: Vector2 = (caster as Node2D).global_position if caster is Node2D else Vector2.ZERO
	_create_visual_effect(origin, radius, caster.get_tree().current_scene)
	
	# Simple damage all enemies in range
	var enemies := caster.get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy is Node2D:
			var enemy_pos: Vector2 = (enemy as Node2D).global_position
			if origin.distance_to(enemy_pos) <= radius:
				var dmg_node: Node = enemy.get_node_or_null("Damageable")
				if dmg_node and dmg_node is Damageable:
					(dmg_node as Damageable).take_damage(damage, caster)
	
	_cooldown_timer = cooldown
	emit_signal("cast_finished", caster)

func _create_visual_effect(position: Vector2, target_radius: float, parent: Node) -> void:
	# Create simple filled circle with border
	var visual = Polygon2D.new()
	visual.global_position = position
	visual.color = Color(1.0, 0.5, 0.0, 0.3)  # Orange fill
	
	# Create circle points
	var points: PackedVector2Array = []
	var segments = 32
	for i in range(segments):
		var angle = (i * TAU) / segments
		points.append(Vector2(cos(angle), sin(angle)) * target_radius)
	visual.polygon = points
	
	# Add border with Line2D
	var border = Line2D.new()
	border.width = 3.0
	border.default_color = Color(1.0, 0.3, 0.0, 0.8)  # Darker orange border
	border.closed = true
	for point in points:
		border.add_point(point)
	visual.add_child(border)
	
	parent.add_child(visual)
	
	# Remove after 0.5 seconds
	await parent.get_tree().create_timer(0.5).timeout
	visual.queue_free()
