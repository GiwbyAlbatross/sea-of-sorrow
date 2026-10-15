class_name ConchflyEnemy
extends CharacterBody2D


@export var SPEED = 90.9
@export var DASH_SPEED = 500.5

@onready var anim = $AnimatedSprite2D

var pummeltimer = 0.0
var last_collider
var last_collider_reset := 0.0

var hp := 9.0

signal dmg(amt: float)

func _ready():
	dmg.connect(_on_dmg)

func _on_dmg(amt: float):
	print("conchfly taking ", amt, " damage")
	hp -= amt
	anim.self_modulate *= 100.1
	if hp <= 0.0:
		$GPUParticles2D.emitting = true
		$GPUParticles2D.reparent(get_parent())
		queue_free()

func _process(delta: float):
	anim.self_modulate = lerp(anim.self_modulate, Color('ffff'), clampf(delta*10.1, 0.0, 1.0))

func _physics_process(delta: float) -> void:
	if anim.animation == &'default':
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var hornetdiff = (GameplayGlobals.hornet_pos - global_position)
		var direction = hornetdiff.normalized()
		anim.flip_h = direction.x > 0.0
		#print("conchfly: hornet distance is ", hornetdiff.length_squared())

		velocity = lerp(velocity, direction * SPEED, delta*2.2)
		if randf() < (hornetdiff.length_squared() / 32768.1)*0.0005:
			# pummel attack
			anim.play(&"pummel")
			pummeltimer = 1.0 + randf()
			direction = ((GameplayGlobals.hornet_pos + GameplayGlobals.hornet.velocity*randf()*0.1) - global_position).normalized() # random amount of aimbot on this
			velocity = direction * DASH_SPEED
			last_collider = null
	elif anim.animation == &'pummel':
		rotation = velocity.angle() - 90
		if pummeltimer <= 0.0 or is_on_wall():
			anim.play("default")
			rotation_degrees = 0.0
		pummeltimer -= delta

	var collided: bool = move_and_slide()
	if collided:
		var collision: KinematicCollision2D = get_last_slide_collision()
		var collider = collision.get_collider()
		if ('dmg' in collider) and (collider != last_collider):
			collider.dmg.emit(1.0)
			print("conchfly ", self.name, " damaging ", collider)
			if 'velocity' in collider: # knockback, unused
				collider.velocity += velocity
				collider.velocity += collision.get_normal() * 100.1
		last_collider = collider
		last_collider_reset = 0.2
	else:
		last_collider_reset -= delta
	
	if last_collider_reset <= 0.0:
		last_collider = null
	
