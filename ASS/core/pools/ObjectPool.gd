extends Node
class_name ObjectPool

@export var scene: PackedScene
@export var initial_size: int = 64

var _pool: Array[Node] = []
var _in_use: Array[Node] = []

func _ready() -> void:
	# Prewarm
	for i in initial_size:
		var inst := scene.instantiate()
		if inst is Node2D:
			(inst as Node2D).visible = false
		add_child(inst)
		_pool.append(inst)

func acquire() -> Node:
	var inst: Node = _pool.pop_back() if _pool.size() > 0 else scene.instantiate()
	_in_use.append(inst)
	if inst is Node2D:
		(inst as Node2D).visible = true
	return inst

func release(inst: Node) -> void:
	if inst is Node2D:
		(inst as Node2D).visible = false
	(inst as Node).set_process(false)
	_in_use.erase(inst)
	_pool.append(inst)


