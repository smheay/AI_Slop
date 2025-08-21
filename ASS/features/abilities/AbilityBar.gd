extends Node
class_name AbilityBar

@export var caster_path: NodePath = NodePath("..")
@export var slots: Array[Ability] = [] # Index 0 -> hotbar_1, ..., 9 -> hotbar_0

var _caster: Node

func _ready() -> void:
	_caster = get_node_or_null(caster_path)

func _physics_process(delta: float) -> void:
	# Tick cooldowns for all equipped abilities
	for ability in slots:
		if ability:
			ability.tick(delta)

func _unhandled_input(event: InputEvent) -> void:
	# Check hotbar 1..9,0
	for i in range(10):
		var action := "hotbar_0" if i == 9 else "hotbar_" + str(i + 1)
		if Input.is_action_just_pressed(action):
			_cast_slot(i)

func _cast_slot(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	var ability := slots[index]
	if ability and ability.can_cast():
		ability.cast(_caster)
