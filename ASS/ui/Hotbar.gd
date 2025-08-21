extends Control
class_name Hotbar

@export var ability_bar_path: NodePath

var _ability_bar: AbilityBar
var _selected_slot: int = 0

func _ready() -> void:
	_ability_bar = get_node_or_null(ability_bar_path)
	
	# Set default FireNova in slot 0 if empty
	if _ability_bar and _ability_bar.slots.size() > 0 and not _ability_bar.slots[0]:
		var fire_nova = load("res://resources/FireNova.tres")
		if fire_nova:
			_ability_bar.slots[0] = fire_nova

func _input(event: InputEvent) -> void:
	if not _ability_bar:
		return
	
	# Handle hotbar key presses for slots 1-10 (keys 1-0)
	for i in range(10):
		var action_name = "hotbar_" + str(i + 1)
		if event.is_action_pressed(action_name):
			_selected_slot = i
			_update_hotbar_display()
			
			# Cast ability if available
			if i < _ability_bar.slots.size() and _ability_bar.slots[i]:
				_ability_bar._cast_slot(i)
			break
	
	# Handle slots 11-12 (minus and equals keys)
	if event.is_action_pressed("hotbar_11"): # Minus key (-)
		_selected_slot = 10
		_update_hotbar_display()
		if 10 < _ability_bar.slots.size() and _ability_bar.slots[10]:
			_ability_bar._cast_slot(10)
	elif event.is_action_pressed("hotbar_12"): # Equals key (=)
		_selected_slot = 11
		_update_hotbar_display()
		if 11 < _ability_bar.slots.size() and _ability_bar.slots[11]:
			_ability_bar._cast_slot(11)

func _process(delta: float) -> void:
	if _ability_bar:
		_update_hotbar_display()

func _update_hotbar_display() -> void:
	if not _ability_bar:
		return

	for i in range(12):
		var slot_container := get_node_or_null("GridContainer/Slot" + str(i + 1)) as Control
		var border_node := get_node_or_null("GridContainer/Slot" + str(i + 1) + "/Border") as ColorRect
		
		if not slot_container or not border_node:
			continue

		var ability: Ability = _ability_bar.slots[i] if i < _ability_bar.slots.size() else null

		# Apply selection highlight and border
		if i == _selected_slot:
			# Show highlight border
			border_node.color = Color(1, 1, 0.8, 0.8) # Yellow border
		else:
			# Show normal border
			border_node.color = Color(0.4, 0.4, 0.4, 0.8) # Gray border
