extends Node2D
class_name FireNovaVFX

@export var lifetime: float = 0.35
@export var target_radius: float = 96.0
# Pixels of outer glow that should not count toward collision radius (texture mode only)
@export var glow_margin_px: float = 0.0
@export var ring_width: float = 18.0
@export var ring_color: Color = Color(1.0, 0.8, 0.2, 0.9)
@export var glow_color: Color = Color(1.0, 0.3, 0.1, 0.35)
@export var debug_draw: bool = false
@export var show_kill_boundary: bool = true
@export var assumed_enemy_hit_radius: float = 9.0

func configure(radius: float) -> void:
	target_radius = radius
	queue_redraw()

func _ready() -> void:
	# If using the old sprite, keep compatibility scaling; otherwise, rely on draw()
	var ring := get_node_or_null("Ring") as Sprite2D
	if ring and ring.texture:
		var tex_size: Vector2 = ring.texture.get_size()
		var base_diameter_px: float = min(tex_size.x, tex_size.y)
		var used_diameter_px: float = max(1.0, base_diameter_px - (2.0 * glow_margin_px))
		var scale_factor: float = (2.0 * target_radius) / used_diameter_px
		ring.scale = Vector2(scale_factor, scale_factor)
	queue_redraw()
	var timer := get_node_or_null("Lifetime") as Timer
	if timer:
		timer.wait_time = lifetime
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		timer.start()
	else:
		await get_tree().create_timer(lifetime).timeout
		queue_free()

func _draw() -> void:
	# Procedural ring: glow + main ring
	var steps := 96
	draw_arc(Vector2.ZERO, target_radius + ring_width * 0.35, 0.0, TAU, steps, glow_color, max(1.0, ring_width * 0.6))
	draw_arc(Vector2.ZERO, target_radius, 0.0, TAU, steps, ring_color, max(1.0, ring_width))
	if debug_draw:
		draw_arc(Vector2.ZERO, target_radius, 0.0, TAU, steps, Color(1, 0.2, 0.2, 0.8), 2.0)
		if show_kill_boundary:
			draw_arc(Vector2.ZERO, target_radius + assumed_enemy_hit_radius, 0.0, TAU, steps, Color(1, 0.8, 0.2, 0.8), 1.0)
