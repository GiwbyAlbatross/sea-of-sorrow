class_name FuzzyStalkerEnemy
extends CharacterBody2D

# silly character, idk what its name was originally but doesn't matter
# his filename had 'stalk' in it and he's a fuzzy boi so i called it FuzzyStalker

@export var UNDERGROUND_SPEED = 100.0 # pixels/s
@export var OVERGROUND_SPEED = 140.0
@export var LEAP_SPEED = 450.0
@export var JUMP_VELOCITY = -180.0
@export var GRAVITY = 100.1
@export var JUMP_LENGTH = 0.4 # seconds

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

signal dmg(amount: float)

var isHiding := true # should start as true in production
var collided := false # to run away from stuff and damage ppl
var mustThinkNextTick := true
var wasOnGround := false # is_on_floor() for last tick
var airTimer := -6.6
var direction := 0.0

@export var maxhp = 29
var hp: float # six hits to kill with base needle
var dmg_cooldown = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.animation_looped.connect(_on_anim_end)
	anim.animation_finished.connect(_on_anim_end)
	dmg.connect(_on_dmg)
	wasOnGround = is_on_floor()
	hp = maxhp
	$CollisionShape2D.shape.size.y = 18.1

func _on_anim_end():
	mustThinkNextTick = true

func _on_dmg(amt: float) -> void:
	print("fuzzystalker '", self.name, "' taking ", amt, " damage.")
	if dmg_cooldown <= 0.0:
		hp -= amt
		dmg_cooldown = sqrt(amt)
	anim.self_modulate = Color(100.1, 100.1, 100.1, 2.0)


func _process(delta: float) -> void:
	anim.self_modulate = lerp(anim.self_modulate, Color('ffff'), clampf(delta*10.1, 0.0, 1.0))
	
	anim.flip_h = velocity.x < 0.0

func _physics_process(delta: float) -> void:
	var hornetRawDirection = (GameplayGlobals.hornet_pos - global_position)
	var hornetDistance  = hornetRawDirection.length()
	var hornetDirection = hornetRawDirection.normalized()
	
	dmg_cooldown -= delta
	
	#velocity = hornetDirection.normalized() * 100.0 # testing only; very silly behaviour
	
	if !is_on_floor(): # literally gravity
		velocity.y += GRAVITY
	
	if airTimer > 0.0:
		velocity.y = JUMP_VELOCITY
		velocity.x = direction * LEAP_SPEED
		if !anim.is_playing():
			anim.play('jump_loop')
	elif airTimer > -2.3:
		velocity.x = lerpf( # momentum
					clampf(-hornetDirection.x * 1000.1, -1.0, 1.0) * OVERGROUND_SPEED,
					velocity.x, clampf(delta*25.2, 0.0, 1.0))
	else:
		velocity.x = lerpf( # momentum
					clampf(hornetDirection.x * 1000.1, -1.0, 1.0) * OVERGROUND_SPEED,
					velocity.x, clampf(delta*25.2, 0.0, 1.0))
	
	#if isHiding: # made it kinda unfair bc fuzzystalker could damage hornet but not vice versa
	#	collision_layer = 0b00 # kinda doesn't exist
	#else:
	#	collision_layer = 0b10 # layer 2
	airTimer -= delta
	
	if collided: # copy-pasted from conchfly
		var collision: KinematicCollision2D = get_last_slide_collision()
		var collider = collision.get_collider()
		if 'dmg' in collider:
			collider.dmg.emit(1.0)
			#print("fuzzystalker ", self.name, " damaging ", collider)
			if 'velocity' in collider: # knockback
				collider.velocity += velocity * 0.05
				collider.velocity += collision.get_normal() * 10.1
	
	if randf() > 0.1 or !mustThinkNextTick: # 90% of the time skip everything lol
		collided = move_and_slide()
		return
	
	mustThinkNextTick = false
	
	if isHiding: # when underground he does this
		if hornetDistance > 300.0: # when far-ish away
			velocity.x = lerpf( # momentum
				clampf(hornetDirection.x * 1000.1, -1.0, 1.0) * UNDERGROUND_SPEED * 0.80,
				velocity.x, clampf(delta*25.2, 0.0, 1.0))
			#velocity.y = 0.0
			#print_debug("moving toward hornet")
		else: # when closeish
			velocity.x = lerpf( # momentum
				clampf(hornetDirection.x * 1000.1, -1.0, 1.0) * UNDERGROUND_SPEED * -1.0,
				velocity.x, clampf(delta*20.0, 0.0, 1.0))
			#velocity.y = 0.0
			#print_debug("moving away from hornet")
		if randf() > 0.98: # pop out of ground and attack
			isHiding = false
			anim.play('appear')
			mustThinkNextTick = true
			$CollisionShape2D.shape.size.y = 140.0
		elif !anim.is_playing():
			anim.play('default')
	else: # attacking etc
		
		if !wasOnGround and is_on_floor(): # ie landed
			anim.play('jump_end')
			print("fuzzystalker landing")
		elif airTimer > 0.0:
			velocity.y = JUMP_VELOCITY
			if !anim.is_playing():
				anim.play('jump_loop')
		elif airTimer < -0.1 and randf() > pow(hornetDistance/151.5, 2.0) and is_on_floor(): # start jump
			direction = clampf(hornetDirection.x * 100000.0, -1.0, 1.0)
			print("fuzzystalker jumping")
			anim.play('jump_begin')
			airTimer = JUMP_LENGTH
		elif randf() > pow(hp/maxhp, 0.1) and airTimer < 5.6:
			anim.play('dive')
			isHiding = true
			mustThinkNextTick = true
			$CollisionShape2D.shape.size.y = 20.0
		elif !anim.is_playing():
			anim.play('hoprun')
	
	#if Input.is_action_pressed("debug_crash"): # doesn't even work lol
	#	get_node('/nonexistent').get_groups()
	
	collided = move_and_slide()
	wasOnGround = is_on_floor()
