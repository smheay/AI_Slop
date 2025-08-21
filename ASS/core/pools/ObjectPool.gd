extends Node
class_name ObjectPool

@export var scene: PackedScene
@export var initial_size: int = 64
@export var autogrow: bool = true        # if false, returns null when empty
@export var park_in_tree: bool = false   # if true, pooled nodes are reparented under this pool when idle

var _pool: Array[Node] = []
var _in_use := {}        # Dictionary used as a set: inst -> true

func _ready() -> void:
	assert(scene != null, "ObjectPool.scene must be set")
	_prewarm()

# --- Public API -------------------------------------------------------------

func acquire() -> Node:
	var inst: Node = null

	if _pool.size() > 0:
		inst = _pool.pop_back()
	elif autogrow:
		inst = _instantiate()
	else:
		return null

	_in_use[inst] = true

	# Activation hook for poolable scenes (optional)
	if inst.has_method("_on_pool_acquire"):
		inst._on_pool_acquire()

	# Generic baseline reset for Node2D (visibility/processing)
	if inst is Node2D:
		var n := inst as Node2D
		n.visible = true
		n.set_process(true)
		n.set_physics_process(true)

	return inst

func release(inst: Node) -> void:
	if inst == null:
		return
	if not _in_use.has(inst):
		# Already released or not ours; ignore safely.
		return

	# Deactivation hook for poolable scenes (optional)
	if inst.has_method("_on_pool_release"):
		inst._on_pool_release()

	# Generic baseline deactivate
	inst.set_process(false)
	inst.set_physics_process(false)
	if inst is Node2D:
		(inst as Node2D).visible = false

	# Detach from current parent
	if is_instance_valid(inst) and inst.get_parent():
		inst.get_parent().remove_child(inst)

	# Optionally keep parked under the pool (stays inside the tree).
	if park_in_tree:
		add_child(inst)

	_pool.append(inst)
	_in_use.erase(inst)

# Optional: free all pooled instances when this pool leaves the tree
func _exit_tree() -> void:
	for inst in _pool:
		if is_instance_valid(inst):
			inst.queue_free()
	for inst in _in_use.keys():
		if is_instance_valid(inst):
			inst.queue_free()
	_pool.clear()
	_in_use.clear()

# --- Internals --------------------------------------------------------------

func _prewarm() -> void:
	for i in range(max(initial_size, 0)):
		var inst := _instantiate()
		# IMPORTANT: don't add_child by default to avoid triggering _ready()
		# If you need them inside the tree while idle, set park_in_tree = true.
		if park_in_tree:
			add_child(inst)
			# Ensure they are fully deactivated
			inst.set_process(false)
			inst.set_physics_process(false)
			if inst is Node2D:
				(inst as Node2D).visible = false
		_pool.append(inst)

func _instantiate() -> Node:
	var inst := scene.instantiate()
	# Baseline inactive state
	inst.set_process(false)
	inst.set_physics_process(false)
	if inst is Node2D:
		(inst as Node2D).visible = false
	return inst
