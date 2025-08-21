extends MultiMeshInstance2D
class_name CrowdRenderer2D

@export var texture: Texture2D
@export var capacity: int = 5000

func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.color_format = MultiMesh.COLOR_NONE
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	multimesh.instance_count = capacity
	# TODO: Assign mesh/texture via material for 2D impostors


