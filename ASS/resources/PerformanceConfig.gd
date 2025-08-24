extends Resource
class_name PerformanceConfig

@export var max_agents: int = 10000
@export var spatial_hash_cell_size: float = 128.0
@export var spatial_hash_update_threshold: int = 200
@export var batch_size: int = 128
@export var max_agents_per_frame: int = 2000

# LOD distances
@export var near_distance: float = 512.0
@export var far_distance: float = 2048.0

# Separation optimization
@export var max_separation_neighbors: int = 8
@export var separation_skip_far_agents: bool = true

# Object pooling
@export var preload_enemy_count: int = 1000
@export var max_pool_size: int = 2000

# Performance presets
enum PerformancePreset {
	LOW = 0,      # 1000 agents
	MEDIUM = 1,   # 3000 agents  
	HIGH = 2,     # 5000 agents
	EXTREME = 3   # 10000+ agents
}

func apply_preset(preset: PerformancePreset) -> void:
	match preset:
		PerformancePreset.LOW:
			max_agents = 1000
			spatial_hash_cell_size = 64.0
			batch_size = 64
			max_agents_per_frame = 1000
			near_distance = 256.0
			far_distance = 1024.0
			preload_enemy_count = 200
			max_pool_size = 500
			
		PerformancePreset.MEDIUM:
			max_agents = 3000
			spatial_hash_cell_size = 96.0
			batch_size = 96
			max_agents_per_frame = 1500
			near_distance = 384.0
			far_distance = 1536.0
			preload_enemy_count = 500
			max_pool_size = 1000
			
		PerformancePreset.HIGH:
			max_agents = 5000
			spatial_hash_cell_size = 128.0
			batch_size = 128
			max_agents_per_frame = 2000
			near_distance = 512.0
			far_distance = 2048.0
			preload_enemy_count = 1000
			max_pool_size = 2000
			
		PerformancePreset.EXTREME:
			max_agents = 10000
			spatial_hash_cell_size = 192.0
			batch_size = 256
			max_agents_per_frame = 3000
			near_distance = 768.0
			far_distance = 3072.0
			preload_enemy_count = 2000
			max_pool_size = 5000

func get_recommended_preset_for_agent_count(agent_count: int) -> PerformancePreset:
	if agent_count <= 1000:
		return PerformancePreset.LOW
	elif agent_count <= 3000:
		return PerformancePreset.MEDIUM
	elif agent_count <= 5000:
		return PerformancePreset.HIGH
	else:
		return PerformancePreset.EXTREME

func get_performance_estimate(agent_count: int) -> Dictionary:
	var preset := get_recommended_preset_for_agent_count(agent_count)
	apply_preset(preset)
	
	var estimated_fps := 60.0
	var estimated_memory_mb := 100.0
	
	# Rough estimates based on agent count
	if agent_count > 5000:
		estimated_fps = 30.0
		estimated_memory_mb = 500.0
	elif agent_count > 3000:
		estimated_fps = 45.0
		estimated_memory_mb = 300.0
	elif agent_count > 1000:
		estimated_fps = 55.0
		estimated_memory_mb = 200.0
	
	return {
		"estimated_fps": estimated_fps,
		"estimated_memory_mb": estimated_memory_mb,
		"recommended_preset": preset,
		"spatial_hash_cell_size": spatial_hash_cell_size,
		"batch_size": batch_size
	}
