extends Node2D
class_name EntityRenderer

# Renders optimized entities as visible sprites
# This bridges the gap between data-oriented design and visual representation

var entity_manager: OptimizedEntityManager
var entity_sprites: Dictionary = {}  # entity_id -> sprite
var sprite_scene: PackedScene

func _ready() -> void:
	# Create a simple circle sprite for entities
	_create_sprite_scene()

func _create_sprite_scene() -> void:
	# Create a simple colored circle sprite
	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.color = Color.RED
	sprite.name = "EntitySprite"
	
	# Convert to scene
	var scene = PackedScene.new()
	scene.pack(sprite)
	sprite_scene = scene

func set_entity_manager(manager: OptimizedEntityManager) -> void:
	entity_manager = manager
	if entity_manager:
		entity_manager.entity_count_changed.connect(_on_entity_count_changed)

func _on_entity_count_changed(count: int) -> void:
	# Update visual representation when entity count changes
	_update_entity_visuals()

func _update_entity_visuals() -> void:
	if not entity_manager:
		return
	
	var active_entities = entity_manager.get_active_entities()
	
	# Remove sprites for entities that no longer exist
	var current_ids = entity_sprites.keys()
	for entity_id in current_ids:
		if not active_entities.has(entity_id):
			_remove_entity_sprite(entity_id)
	
	# Add sprites for new entities
	for entity_id in active_entities:
		if not entity_sprites.has(entity_id):
			_add_entity_sprite(entity_id)

func _add_entity_sprite(entity_id: int) -> void:
	if not entity_manager or not sprite_scene:
		return
	
	var sprite = sprite_scene.instantiate()
	if sprite:
		add_child(sprite)
		entity_sprites[entity_id] = sprite
		
		# Set initial position
		var pos = entity_manager.get_entity_position(entity_id)
		sprite.global_position = pos

func _remove_entity_sprite(entity_id: int) -> void:
	if entity_sprites.has(entity_id):
		var sprite = entity_sprites[entity_id]
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
		entity_sprites.erase(entity_id)

func _process(delta: float) -> void:
	if not entity_manager:
		return
	
	# Update sprite positions to match entity positions
	var active_entities = entity_manager.get_active_entities()
	for entity_id in active_entities:
		if entity_sprites.has(entity_id):
			var sprite = entity_sprites[entity_id]
			if sprite and is_instance_valid(sprite):
				var pos = entity_manager.get_entity_position(entity_id)
				sprite.global_position = pos

func clear_all_sprites() -> void:
	for sprite in entity_sprites.values():
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	entity_sprites.clear()
