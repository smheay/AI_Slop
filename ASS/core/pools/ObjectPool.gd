extends Node
class_name ObjectPool

signal pool_created(scene: PackedScene, count: int)
signal pool_depleted(scene: PackedScene)

@export var preload_scenes: Array[PackedScene] = []
@export var preload_counts: Array[int] = []
@export var max_pool_size: int = 1000

# For single-scene usage (backward compatibility)
@export var scene: PackedScene
@export var initial_size: int = 10

var _pools: Dictionary = {}
var _active_objects: Array[Node] = []
var _single_scene_pool: Array[Node] = []

func _ready() -> void:
	# Handle single scene case first
	if scene:
		_create_single_scene_pool()
	else:
		_preload_pools()

func _create_single_scene_pool() -> void:
	if not scene:
		return
	
	for i in range(initial_size):
		var instance := scene.instantiate()
		instance.set_meta("pool_owner", self)
		instance.set_meta("is_pooled", true)
		_single_scene_pool.append(instance)
		add_child(instance)
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		instance.visible = false

func _preload_pools() -> void:
	for i in range(preload_scenes.size()):
		var scene := preload_scenes[i]
		var count := preload_counts[i] if i < preload_counts.size() else 10
		_create_pool(scene, count)

func _create_pool(scene: PackedScene, count: int) -> void:
	if not _pools.has(scene):
		_pools[scene] = []
	
	var pool := _pools[scene] as Array
	for i in range(count):
		var instance := scene.instantiate()
		instance.set_meta("pool_owner", self)
		instance.set_meta("is_pooled", true)
		pool.append(instance)
		add_child(instance)
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		instance.visible = false
	
	emit_signal("pool_created", scene, count)

func get_instance(scene: PackedScene) -> Node:
	if not _pools.has(scene):
		_create_pool(scene, 10)
	
	var pool := _pools[scene] as Array
	if pool.is_empty():
		# Create more instances if pool is empty
		_create_pool(scene, 5)
		if pool.is_empty():
			emit_signal("pool_depleted", scene)
			return null
	
	var instance := pool.pop_back() as Node
	if instance and is_instance_valid(instance):
		instance.process_mode = Node.PROCESS_MODE_INHERIT
		instance.visible = true
		instance.set_meta("is_active", true)
		_active_objects.append(instance)
		
		# Call reset method if it exists
		if instance.has_method("reset_for_pool"):
			instance.reset_for_pool()
	
	return instance

func return_instance(instance: Node) -> void:
	# Safety check: ensure instance is still valid
	if not is_instance_valid(instance):
		return
	
	if not instance.has_meta("is_pooled"):
		instance.queue_free()
		return
	
	var scene := instance.scene_file_path
	if not scene or not _pools.has(scene):
		instance.queue_free()
		return
	
	# Remove from active objects
	_active_objects.erase(instance)
	
	# Reset instance
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	instance.visible = false
	instance.set_meta("is_active", false)
	
	# Return to pool
	var pool := _pools[scene] as Array
	if pool.size() < max_pool_size:
		pool.append(instance)
	else:
		instance.queue_free()

func cleanup_invalid_objects() -> void:
	# Clean up any invalid objects from active objects list
	var i := 0
	while i < _active_objects.size():
		if not is_instance_valid(_active_objects[i]):
			_active_objects.remove_at(i)
		else:
			i += 1

func get_active_count() -> int:
	return _active_objects.size()

# Single-scene pool methods for backward compatibility
func acquire() -> Node:
	if scene and not _single_scene_pool.is_empty():
		var instance := _single_scene_pool.pop_back() as Node
		if instance:
			instance.process_mode = Node.PROCESS_MODE_INHERIT
			instance.visible = true
			instance.set_meta("is_active", true)
			_active_objects.append(instance)
			
			# Call reset method if it exists
			if instance.has_method("reset_for_pool"):
				instance.reset_for_pool()
		
		return instance
	elif scene:
		# Create more instances if pool is empty
		_create_single_scene_pool()
		if not _single_scene_pool.is_empty():
			return acquire()
	
	return null

func release(instance: Node) -> void:
	if not instance.has_meta("is_pooled"):
		instance.queue_free()
		return
	
	# Remove from active objects
	_active_objects.erase(instance)
	
	# Reset instance
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	instance.visible = false
	instance.set_meta("is_active", false)
	
	# Return to single scene pool if it's the right type
	if scene and instance.scene_file_path == scene.resource_path:
		if _single_scene_pool.size() < max_pool_size:
			_single_scene_pool.append(instance)
		else:
			instance.queue_free()
	else:
		instance.queue_free()

func get_pool_info() -> Dictionary:
	var info := {}
	
	# Add single scene pool info
	if scene:
		info[scene.resource_path] = {
			"available": _single_scene_pool.size(),
			"active": _count_active_by_scene(scene)
		}
	
	# Add multi-scene pool info
	for scene in _pools:
		var pool := _pools[scene] as Array
		info[scene.resource_path] = {
			"available": pool.size(),
			"active": _count_active_by_scene(scene)
		}
	return info

func _count_active_by_scene(scene: PackedScene) -> int:
	var count := 0
	for obj in _active_objects:
		if obj.scene_file_path == scene.resource_path:
			count += 1
	return count
