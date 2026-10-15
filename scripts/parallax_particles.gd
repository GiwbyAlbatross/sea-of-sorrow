#@tool
extends GPUParticles2D

var lastcampos: Vector2 = Vector2.ZERO

func getcam() -> Camera2D:
	return get_viewport().get_camera_2d()
	#return %camera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emitting = true
	lastcampos = getcam().global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var diff = lastcampos - getcam().global_position
	process_material.set_shader_parameter('camera_diff', diff)
	#process_material.set_shader_parameter('node_delta', delta)
	lastcampos = getcam().global_position
