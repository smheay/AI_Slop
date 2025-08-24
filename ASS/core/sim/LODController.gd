extends Node
class_name LODController

@export var near_distance: float = 256.0
@export var far_distance: float = 1024.0
@export var max_agents_per_lod: Dictionary = {
	0: 100,   # Near: Full processing
	1: 500,   # Medium: Reduced processing  
	2: 1000   # Far: Minimal processing
}

func compute_lod(camera_pos: Vector2, target_pos: Vector2) -> int:
	var d := camera_pos.distance_to(target_pos)
	if d < near_distance:
		return 0
	if d < far_distance:
		return 1
	return 2

func get_processing_level(lod: int) -> Dictionary:
	match lod:
		0: # Near - Full processing
			return {
				"ai_enabled": true,
				"physics_enabled": true,
				"separation_enabled": true,
				"visual_quality": 2,
				"update_frequency": 1.0
			}
		1: # Medium - Reduced processing
			return {
				"ai_enabled": true,
				"physics_enabled": true,
				"separation_enabled": false,
				"visual_quality": 1,
				"update_frequency": 0.5
			}
		2: # Far - Minimal processing
			return {
				"ai_enabled": false,
				"physics_enabled": false,
				"separation_enabled": false,
				"visual_quality": 0,
				"update_frequency": 0.25
			}
		_:
			return {
				"ai_enabled": false,
				"physics_enabled": false,
				"separation_enabled": false,
				"visual_quality": 0,
				"update_frequency": 0.1
			}

func should_process_agent(agent: Node2D, camera_pos: Vector2, frame_count: int) -> bool:
	var lod := compute_lod(camera_pos, agent.global_position)
	var config := get_processing_level(lod)
	var update_freq = config.update_frequency
	
	# Skip processing based on frequency
	return (frame_count % int(1.0 / update_freq)) == 0
