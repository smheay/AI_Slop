extends Resource
class_name PerformanceConfig

@export_group("Rendering")
@export var use_vsync: bool = true
@export var max_fps: int = 60
@export var use_batching: bool = true
@export var use_occlusion_culling: bool = true

@export_group("Physics")
@export var physics_threads: int = 2
@export var physics_iterations: int = 4
@export var use_physics_batching: bool = true
@export var max_physics_objects: int = 10000

@export_group("AI & Simulation")
@export var ai_batch_size: int = 64
@export var ai_max_per_frame: int = 10000
@export var use_adaptive_batching: bool = true
@export var spatial_hash_cell_size: float = 64.0

@export_group("Memory & Pooling")
@export var object_pool_initial_size: int = 128
@export var object_pool_autogrow: bool = true
@export var use_batch_operations: bool = true
@export var max_pooled_objects: int = 10000

@export_group("LOD & Culling")
@export var use_adaptive_lod: bool = true
@export var lod_near_distance: float = 256.0
@export var lod_far_distance: float = 1024.0
@export var culling_frustum: bool = true

@export_group("Performance Monitoring")
@export var enable_profiling: bool = true
@export var auto_optimize: bool = true
@export var warning_threshold_fps: float = 30.0
@export var warning_threshold_memory_mb: float = 512.0

# Performance presets
enum PerformancePreset {
	LOW,      # 30 FPS target, aggressive optimizations
	MEDIUM,   # 45 FPS target, balanced optimizations  
	HIGH,     # 60 FPS target, quality optimizations
	ULTRA     # 60+ FPS target, minimal optimizations
}

func apply_preset(preset: PerformancePreset) -> void:
	match preset:
		PerformancePreset.LOW:
			max_fps = 30
			ai_batch_size = 32
			physics_iterations = 2
			use_adaptive_lod = true
			object_pool_initial_size = 64
			spatial_hash_cell_size = 128.0
			
		PerformancePreset.MEDIUM:
			max_fps = 45
			ai_batch_size = 48
			physics_iterations = 3
			use_adaptive_lod = true
			object_pool_initial_size = 96
			spatial_hash_cell_size = 96.0
			
		PerformancePreset.HIGH:
			max_fps = 60
			ai_batch_size = 64
			physics_iterations = 4
			use_adaptive_lod = true
			object_pool_initial_size = 128
			spatial_hash_cell_size = 64.0
			
		PerformancePreset.ULTRA:
			max_fps = 120
			ai_batch_size = 96
			physics_iterations = 6
			use_adaptive_lod = false
			object_pool_initial_size = 256
			spatial_hash_cell_size = 32.0

# Get configuration as dictionary for easy access
func to_dict() -> Dictionary:
	return {
		"rendering": {
			"use_vsync": use_vsync,
			"max_fps": max_fps,
			"use_batching": use_batching,
			"use_occlusion_culling": use_occlusion_culling
		},
		"physics": {
			"physics_threads": physics_threads,
			"physics_iterations": physics_iterations,
			"use_physics_batching": use_physics_batching,
			"max_physics_objects": max_physics_objects
		},
		"ai_simulation": {
			"ai_batch_size": ai_batch_size,
			"ai_max_per_frame": ai_max_per_frame,
			"use_adaptive_batching": use_adaptive_batching,
			"spatial_hash_cell_size": spatial_hash_cell_size
		},
		"memory_pooling": {
			"object_pool_initial_size": object_pool_initial_size,
			"object_pool_autogrow": object_pool_autogrow,
			"use_batch_operations": use_batch_operations,
			"max_pooled_objects": max_pooled_objects
		},
		"lod_culling": {
			"use_adaptive_lod": use_adaptive_lod,
			"lod_near_distance": lod_near_distance,
			"lod_far_distance": lod_far_distance,
			"culling_frustum": culling_frustum
		},
		"performance_monitoring": {
			"enable_profiling": enable_profiling,
			"auto_optimize": auto_optimize,
			"warning_threshold_fps": warning_threshold_fps,
			"warning_threshold_memory_mb": warning_threshold_memory_mb
		}
	}