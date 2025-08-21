extends CharacterBody2D
class_name Player

signal equipped(item: Node)
signal unequipped(item: Node)

@export var move_speed: float = 220.0
@export var auto_attack: Resource # Ability
@export var auto_cast: bool = false
@export var stats_path: NodePath
@export var attack_interval: float = 0.5

var _attack_timer := 0.0
var _stats: Node

func _ready() -> void:
	_stats = get_node(stats_path)
	GameBus.emit_signal("player_spawned", self)
	add_to_group("player")

func handle_input(dir: Vector2) -> void:
	velocity = dir * move_speed

func _physics_process(delta: float) -> void:
	# TODO: Replace with input system; temporary WASD
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	handle_input(dir.normalized())
	move_and_slide()
	# Tick ability cooldown if present
	if auto_attack and auto_attack is Ability:
		(auto_attack as Ability).tick(delta)
	# Drive auto-attack cadence
	if auto_cast:
		tick_combat(delta)

func tick_combat(delta: float) -> void:
	if auto_attack == null:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0 and (auto_attack as Ability).can_cast():
		(auto_attack as Ability).cast(self)
		_attack_timer = attack_interval

func equip(item: Node) -> void:
	# TODO: Apply item modifiers to _stats
	emit_signal("equipped", item)
	GameBus.emit_signal("stats_modified", self, item)

func unequip(item: Node) -> void:
	# TODO: Remove item modifiers
	emit_signal("unequipped", item)
	GameBus.emit_signal("stats_modified", self, item)


