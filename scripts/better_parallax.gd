extends Node2D

@export var scroll_scale := Vector2(1.0, 1.0)
var original_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	original_position = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = original_position + (get_viewport().get_camera_2d().global_position - original_position) * (Vector2(1.0, 1.0) - scroll_scale)
