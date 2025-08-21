extends Node2D
class_name PlayerVisual

@export var size: float = 32.0
@export var color: Color = Color(0.2, 0.6, 1, 1)

func _ready() -> void:
	print("PlayerVisual created!")

func _draw() -> void:
	# Draw a simple rectangle
	var rect = Rect2(-size/2, -size/2, size, size)
	draw_rect(rect, color)
	print("Drawing player rect: ", rect, " with color: ", color)
