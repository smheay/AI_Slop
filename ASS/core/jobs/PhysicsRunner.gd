extends Node
class_name PhysicsRunner

signal physics_batch_started(count: int)
signal physics_batch_finished(ms: float)

func integrate(agents: Array, delta: float) -> void:
	emit_signal("physics_batch_started", agents.size())
	# TODO: Apply velocities → positions, collisions in batches
	emit_signal("physics_batch_finished", 0.0)


