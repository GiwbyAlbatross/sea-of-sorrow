extends Camera2D

@export var smoothing: float = 40.4

var shaking: float = 0.0

var lastpos: Vector2
var has_velocity: bool

func add_shaking(amount: float) -> void:
	shaking += amount

func _ready() -> void:
	lastpos = global_position
	has_velocity = 'velocity' in get_parent()

func get_smoothing() -> float:
	return smoothing

func do_shaking() -> Vector2:
	if shaking == 0.0: return Vector2.ZERO
	return Vector2(randfn(0.0, shaking), randfn(0.0, shaking))

func _process(delta: float) -> void:
	GameplayGlobals.camera_pos = global_position
	position *= clampf(1.0 - delta*get_smoothing()/4.4, 0.0, 1.0)
	global_position = lerp(global_position, lastpos, clampf(delta*get_smoothing(), 0.0, 1.0))
	position += do_shaking()
	shaking *= clampf(1.0 - delta*8.8, 0.0, 1.0)
	lastpos = global_position
