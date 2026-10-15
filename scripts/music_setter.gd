extends Node

@export var enabled := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not enabled: return
	MusicManager.schedule_song(preload("res://assets/Sounds/SeaOfSorrow-OST/iASection-intro.wav"))
	MusicManager.schedule_song(preload("res://assets/Sounds/SeaOfSorrow-OST/iASection-loop-evenlessguitar.wav"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
