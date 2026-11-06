class_name HornetUnderwater
extends Hornet

var dir: Vector2 = Vector2.ZERO
@export var DOWN_SPEED = 100.0

func _move(delta: float) -> void:
	direction = Input.get_axis("ui_left", "ui_right")
	
	velocity.y = lerpf(velocity.y, DOWN_SPEED, delta)
	velocity.x = direction * SPEED
	
	anim.flip_h = velocity.x > 0.0
	
	if Input.is_action_just_pressed("cren") and has_input():
		anim.play("CREN") # uhh so "CREN" is probably not what hornet says, it sounds more like 'vren' but the 'r' is rolled or smth idk it's not really important
		voice.play_by_name(&'bind')
		sfx.play_by_name(&'bind', 0.0, 0.001, 0.8, true)
	if anim.animation == &'CREN':
		velocity *= 0.05
		print("debugger crest bind!: global position: ",  global_position)
	
	#if anim.animation == &'airdash':
	#	velocity.y = 0.0 # hk/hkss behaviour
	
	if anim.animation == &'attackdown':
		velocity = Vector2(98.0, 160.0) * POGO_SPEED
		velocity.x *= facing
	
