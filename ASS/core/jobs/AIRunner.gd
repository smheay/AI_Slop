extends Node
class_name AIRunner

signal ai_batch_started(count: int)
signal ai_batch_finished(ms: float)

@export var batch_size: int = 256

func run_batch(agents: Array, delta: float) -> void:
	emit_signal("ai_batch_started", agents.size())
	# TODO: Step AI for a subset per frame using batch_size
	emit_signal("ai_batch_finished", 0.0)


