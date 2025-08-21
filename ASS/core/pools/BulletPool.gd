extends ObjectPool
class_name BulletPool

signal bullet_fired(node: Node)

func fire(position: Vector2, direction: Vector2, speed: float, lifetime: float) -> Node:
	var bullet := acquire()
	if bullet is Node2D:
		(bullet as Node2D).global_position = position
		# TODO: Configure bullet velocity and lifetime
	emit_signal("bullet_fired", bullet)
	return bullet


