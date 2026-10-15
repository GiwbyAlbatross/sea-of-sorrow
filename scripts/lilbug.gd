extends CharacterBody2D

const SPEED = 188.1
const JUMP_VELOCITY = -400.0

var hp := 10.0

var direction = 0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

signal dmg(amount: float)

func _ready() -> void:
	$Timer.wait_time = randf() + 0.3
	$Timer.connect("timeout", _gen_direction)
	anim.connect("animation_finished", _pick_next_animation)
	anim.play('spawn')
	dmg.connect(_on_dmg)

func _gen_direction():
	if hp < 0.1: return
	var olddir = direction
	direction = clamp(sin(randf() * 1000000.0) * 1000000.0, -1.0, 1.0)
	if direction != olddir:
		anim.flip_h = direction < 0.0
		anim.play("turn")
	velocity.x = lerpf(velocity.x, direction * SPEED, 0.8)
	$Timer.start(randf() + 0.3)

func _pick_next_animation():
	anim.play('walk')

func _on_dmg(amt: float):
	hp -= amt
	modulate = Color(100.1, 10.1, 10.1)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# THESE GUYS NO JUMP
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	move_and_slide()
	
	if hp < 0.0:
		anim.play("die")

func _process(delta: float) -> void:
	modulate = lerp(self_modulate, Color('fff'), delta)
