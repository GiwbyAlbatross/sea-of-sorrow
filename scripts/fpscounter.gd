extends Label

@onready var ogtext: String = text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if delta == 0.0:
		text = ogtext
	else:
		text = ogtext % [1.0 / delta]
