extends CanvasItem

@export var ingame_visible: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = ingame_visible
