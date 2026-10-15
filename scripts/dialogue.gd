class_name Dialogue # base class, still usable
extends Area2D

@export var text_simple: Array[String]

var is_visible := false

signal dialogue_finish()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)

func get_text(line: int): # returns String or void
	# SHOULD BE OVERRIDDEN BY SUBCLASSES
	#if line >= len(text_simple):
	#	return null
	if line >= len(text_simple):
		print("no dialogue line for line ", line, ". Returning `null`.")
		return null
	var r = text_simple.get(line)
	print("showing dialogue line ", line, ": ", "'", r, "'")
	return r

func _on_body_enter(body: CollisionObject2D) -> void:
	$Label.visible = true
	if "dialogue" in body: # ie is player
		body.dialogue = self
func _on_body_exit(body: CollisionObject2D) -> void:
	$Label.visible = false
	if "dialogue" in body: # ie is player
		body.dialogue = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
