extends Label

var line_upto := 0
var dialogue: Dialogue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visible)
	get_parent().visible = false

func _on_visible() -> void:
	var vis = is_visible_in_tree()
	#if vis:
	line_upto = 0
	#text = dialogue.get_text(line_upto)
	if vis:
		_show_line()

func _cleanup() -> void:
	dialogue.dialogue_finish.emit()
	get_parent().visible = false
	dialogue.is_visible = false

func _show_line() -> void:
	var line = dialogue.get_text(line_upto)
	if !line:
		_cleanup()
		return
	text = line

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	if Input.is_action_just_pressed("ui_accept"):
		# next line
		line_upto += 1 # ++
		_show_line()
