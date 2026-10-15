class_name Hornet
extends CharacterBody2D

@export var SPEED = 300.0
@export var SPRINT_SPEED = 666.6
@export var POGO_SPEED = 5.0
@export var JUMP_VELOCITY = -400.4
@export var STEP_JUMP_VELOCITY = -100.1
@export var SPRINT_JUMP_VELOCITY = -600.6
@export var JUMP_BOOST_VELOCITY = -1404.1
@export var preserved_animations := PackedStringArray(['sprint-jump', 'sprint-attack', 'attack0', 'attack1', 'CREN', 'turn', 'attackup', 'attackdown', 'attackbounce', 'land-hard', 'land-soft'])
@export var big_animations := PackedStringArray(['needolin', 'needolin-upright', 'lookup'])

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var voice: SoundManager = $voice
@onready var sfx: SoundManager = $soundfx
@onready var vignette: Node2D = $Camera2D/vignette

@onready var attacks: Node2D = $attacks

@onready var dialogue_node = $Camera2D/dialogue

var __magic_no_pogo__ := true # so you can't pogo yourself. tool pogos will still exist

var facing = 1 # -1 = left, 1 = right
var direction := 0

var isSitting := false
var canSit := false
var bench #: Bench
var dialogue: Dialogue

var should_pogo := false

var was_on_ground := false
var sprint_timer: float = 0.0
var attack_cooldown: float = -0.01
var threadstorm_timer := 0.0
var afk_timer: float = 0.0
var no_input_time: float = 0.0 # has imput if this is less than 0
var dmg_cooldown: float = 0.0
var respawn_point: Vector2
var step_cooldown: float = 0.0

var collider: Area2D # used for combat 
var attackingEntites: Array[CollisionObject2D] = [] # at the end of an attack these are all tallied and the array is then cleared
var should_run_damaging_logic := false

signal dmg(amt: float)

func _ready():
	if GameplayGlobals.hornet_should_move:
		global_position = GameplayGlobals.hornet_should_move_to
		GameplayGlobals.hornet_pos = global_position
		GameplayGlobals.hornet_should_move = true
		dmg_cooldown += 1.0
	respawn_point = global_position
	anim.connect('animation_finished', _pick_next_anim)
	anim.connect('animation_looped', _pick_next_anim)
	dmg.connect(_on_dmg)
	GameplayGlobals.hornet_pos = global_position
	GameplayGlobals.hornet = self
	dmg_cooldown += 0.5

func _on_dmg(amt: float):
	if anim.animation == &'CREN': # ie is binding
		_pick_next_anim()
	if isSitting:
		bench.setSitting.emit(false, self)
	if dmg_cooldown < 0.0:
		dmg_cooldown = sqrt(amt)
		GameplayGlobals.hornet_hp -= amt
	$Camera2D.shaking = amt
	vignette.visible = true
	#voice.play_by_name(&'jump2')
	#print('hornet taking ', amt, ' damage, leaving her at ', GameplayGlobals.hornet_hp)

func _pick_next_anim():
	anim.speed_scale = 1.0
	var old = anim.animation
	if is_on_wall_only():
		anim.play('wall')
		return
	if old == &'attackdown':
		#if true:
		#if should_pogo:
		#	anim.play('attackbounce')
		#	should_pogo = false
		#	velocity.y = JUMP_VELOCITY
		#	return
		#else: # next two lines were indented
		velocity *= Vector2(0.01, 0.5)
		anim.play('default')
	elif threadstorm_timer > 0.0:
		anim.play('threadstorm')
	elif old == &'needolin' and Input.is_action_pressed("needolin"):
			anim.play('needolin')
			return
	elif direction:
		anim.play('walk')
	elif not velocity.x:
		var vertdir = Input.get_axis('ui_down', 'ui_up')
		if vertdir == 1:
			anim.play('lookup')
		elif vertdir == -1:
			anim.play('lookdown')
		elif GameplayGlobals.hornet_hp < 1.5:
			anim.play('lowhp')
		else:
			anim.play('default')
	elif is_sprinting():
		if is_on_floor():
			anim.play('sprint')
		else:
			anim.play('airdash')
	

func is_sprinting() -> bool:
	return Input.is_action_pressed('sprint')

func is_interacting() -> bool:
	if dialogue != null:
		if dialogue.is_visible:
			return true
	#if isSitting: return true
	return false

func has_input():
	return no_input_time <= 0.0

func _setanim(animation: StringName):
	if !preserved_animations.has(anim.animation) or preserved_animations.has(animation):
		anim.play(animation)
		anim.speed_scale = 1.0

func _fixdirection():
	if direction != facing and direction != 0.0: # and abs(direction) > 0.9:
		_setanim('turn')
	if direction != 0.0:
		facing = direction
	anim.flip_h = facing < 0

func _move(delta: float) -> void:
	if isSitting:
		velocity *= 0.0
		return # no moving while sitting
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 2.0
	elif not was_on_ground and anim.animation != &'attackdown':
		sfx.play_by_name(&'land')
		_setanim("land-soft")
		no_input_time = 0.05 # tiny no-input time from falling, hk style
	if anim.animation == &'attackdown':
		velocity.y += 500.0 * delta
	elif anim.animation == &'attackbounce':
		velocity.y -= 100.0 * delta

	if has_input():
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * (lerpf(SPEED, SPRINT_SPEED, clampf(sprint_timer, 0.6, 0.1)+0.4) if is_sprinting() else SPEED)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if Input.is_action_pressed('needolin') and is_on_floor():
				velocity *= 0.0
				anim.play('needolin')

		if direction:
			#anim.play('walk')
			if is_on_floor():
				sfx.play_by_name(&'run', -5, 0.1, 1.1 if is_sprinting() else 0.8)
			if Input.is_action_just_pressed("sprint"):
				if is_on_floor():
					sfx.play_by_name(&'run', -5, 0.1, 1.1, true)
					_setanim('dash')
				else:
					_setanim('airdash')
			if Input.is_action_just_released("sprint"):
				if is_on_floor():
					sfx.play_by_name(&'run', -5, 0.1, 0.8, true)
				sprint_timer = 0.0
			
			if is_sprinting():
				if !is_on_floor() and anim.animation == &'dash':
					anim.play('airdash')
				if sprint_timer > 0.6:
					_setanim('sprint')

		if is_sprinting():
			sprint_timer += delta
			if !is_on_floor() and sprint_timer < 0.67: # not some brainrot, this is just how long the animation is
				velocity.y = 0.0

		if Input.is_action_just_pressed('ui_left') or Input.is_action_just_pressed('ui_right'):
			_setanim('walkbegin')
			#_fixdirection()
		if Input.is_action_just_released('ui_left') or Input.is_action_just_released('ui_right'):
			_setanim('walkend')
			#_fixdirection()
			if sfx.get_current() == &'run':
				sfx.playing = false
		if Input.is_action_pressed('ui_left') or Input.is_action_pressed('ui_right'):
			_fixdirection()
		#print(sfx.get_current())
		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			sfx.play_by_name(&'land', 0.0, 0.1, 1.1, true)
			if randf() > 0.6:
				voice.play_by_name(&'jump2')
			else:
				voice.play_by_name(&'jump0')
			if !is_sprinting():
				_setanim('jump')
				velocity.y = JUMP_VELOCITY
			else:
				_setanim('sprint-jump')
				velocity.y = SPRINT_JUMP_VELOCITY
		if Input.is_action_pressed('ui_accept') and velocity.y < -100.1:
			velocity.y += JUMP_BOOST_VELOCITY * delta
	
	#if $attacks/stepdetector.has_overlapping_bodies() and step_cooldown <= 0.0:
	#	velocity.y = min(JUMP_VELOCITY / 10.1, velocity.y)
	#	#print("step jump")
	#	step_cooldown = 0.5
	
	if is_on_wall_only():
		_setanim("wall")
		if velocity.y > 0.1:
			velocity *= 0.01
		if Input.is_action_just_pressed("ui_accept") and has_input():
			if randf() > 0.5:
				voice.play_by_name(&'jump1')
			else:
				voice.play_by_name(&'jump0')
			facing = clampf(get_wall_normal().x * 1000000, -1.0, 1.0)
			#anim.flip_h = facing < 0 # fixes bug with walljump anim only
			velocity.y = SPRINT_JUMP_VELOCITY
			velocity.x = SPEED * facing / 2 
			no_input_time = 0.2 # gets 0.2 seconds of no input time from walljump, also physics don't really apply in that time
	elif is_on_wall() and !($attacks/stepdetector.has_overlapping_bodies()) and step_cooldown < 0.0:
		velocity.y = min(STEP_JUMP_VELOCITY, velocity.y)
		print("step jump")
		step_cooldown = 0.5
	
	if Input.is_action_just_pressed("cren") and has_input():
		_setanim("CREN") # uhh so "CREN" is probably not what hornet says, it sounds more like 'vren' but the 'r' is rolled or smth idk it's not really important
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
	

func _combat(delta: float) -> void:
	attacks.scale.x = facing
	if !has_input():
		return
	
	if anim.animation == &'attackdown' and is_on_floor():
		_pick_next_anim()
		velocity *= 0.01
	
	if Input.is_action_just_pressed("attack") and attack_cooldown < 0.0:
		#var collider: Area2D
		should_run_damaging_logic = true
		attack_cooldown = 0.3
		sfx.play_by_name(&'attack', 0.0, 0.1, 1.0, true)
		voice.play_by_name(&'jump1')
		var vertdir = Input.get_axis('ui_down', 'ui_up')
		if vertdir == 1:
			_setanim('attackup')
			collider = attacks.get_node("up")
			#print("attacking up")
		elif vertdir == -1 and !is_on_floor():
			collider = attacks.get_node("pogo")
			_setanim('attackdown')
			#print("attacking down")
			dmg_cooldown = 0.35
			if is_on_floor_only():
				return
		elif is_sprinting():
			#print("sprint attacking")
			collider = attacks.get_node("sprint")
			_setanim('sprint-attack')
		else:
			collider = attacks.get_node("main")
			#print("attacking the normal way")
			if randf() > 0.5:
				_setanim("attack0")
			else:
				_setanim('attack1')
			#attack_cooldown = 0.0
	if attack_cooldown > 0.0: # attack detection logic is now every tick
		for entity in collider.get_overlapping_bodies():
			if attackingEntites.has(entity):
				continue
			#print("adding ", entity, " to attackingEntities")
			if anim.animation == &'attackdown' and !('__magic_no_pogo__' in entity):
				print("bouncing because of ", entity)
				anim.play("attackbounce")
				#velocity *= 0.01
				velocity.y = SPRINT_JUMP_VELOCITY
				attack_cooldown *= 0.1
			attackingEntites.append(entity)
		for entity in collider.get_overlapping_areas(): # for breakable objects
			if attackingEntites.has(entity):
				continue
			if !('dmg' in entity): # might save time in the next block if we end up with a lot of areas
				continue
			#print("adding ", entity, " to attackingEntities")
			if anim.animation == &'attackdown' and !('__magic_no_pogo__' in entity):
				print("bouncing because of ", entity)
				anim.play("attackbounce")
				#velocity *= 0.01
				velocity.y = SPRINT_JUMP_VELOCITY
				attack_cooldown *= 0.05
			if 'dmg' in entity:
				print("breaking breakable object: ", entity)
				entity.dmg.emit(0.1)
	elif attack_cooldown <= 0.0 and should_run_damaging_logic:
		#get_node('/nonexistent').name # crashes game
		print("doing attack logic, collider=", collider)
		for entity in attackingEntites:
			print("attacking: ", entity)
			if entity == self:
				entity.velocity -= velocity * 0.1
				entity.velocity.x -= facing * SPEED / 3
				#entity.velocity.y += JUMP_VELOCITY / 3
				continue
			#if !('__magic_no_pogo__' in entity):
			#	should_pogo = true
			#	print("should pogo")
			if 'dmg' in entity:
				print(entity, " can take damage, nail-damaging it")
				entity.dmg.emit(5.0) # nail dmg
			if 'velocity' in entity:
				entity.velocity += velocity * 0.1
				entity.velocity.x += facing * SPEED / 3
				entity.velocity.y += JUMP_VELOCITY / 3
				#print_debug('doing knockback')
		attackingEntites.clear()
		should_run_damaging_logic = false
	attack_cooldown -= delta
	
	if is_on_floor() and anim.animation == &'attackdown':
		anim.speed_scale = 2.0
	
	# silk skills!
	if Input.is_action_just_pressed('silkskill'):
		voice.play_by_name(&'egale')
		anim.play('threadstorm_begin')
		threadstorm_timer = 1.0
		attacks.get_node('threadstorm/AnimatedSprite2D').play('ThreadstormEffect')
	if threadstorm_timer > 0.0:
		var dmgbox: Area2D = attacks.get_node("threadstorm")
		for entity in dmgbox.get_overlapping_bodies():
			if entity == self: continue
			if 'dmg' in entity:
				entity.dmg.emit(20.0) # arbitrary value
			if 'velocity' in entity:
				entity.velocity += Vector2(randfn(0.0, 10.1), randfn(0.0, 10.1))
		velocity *= 0.0
	elif threadstorm_timer > -1.0:
		attacks.get_node('threadstorm/AnimatedSprite2D').play('default')

func _interact(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if dialogue != null:
			dialogue_node.get_node('Label').dialogue = dialogue
			dialogue.is_visible = true
			dialogue_node.visible = true
		if canSit:
			bench.setSitting.emit(true, self)

func _physics_process(delta: float) -> void:
	if is_sprinting():
		$CollisionShape2D.scale.y = 0.9
	else:
		$CollisionShape2D.scale.y = 1.0
	
	if Input.is_action_just_pressed("move") and isSitting:
		bench.setSitting.emit(false, self)
	
	# tick cooldowns
	dmg_cooldown -= delta
	no_input_time -= delta
	step_cooldown -= delta
	threadstorm_timer -= delta
	
	if anim.animation != &'CREN':
		_interact(delta)
		if !is_interacting():
			_move(delta)
			_combat(delta)
		
		if velocity.length() < 100.1:
			afk_timer += delta

		if !isSitting:
			was_on_ground = is_on_floor()
			move_and_slide()
		#elif direction != 0.0:
			#bench.setSitting.emit(false, self)
	
		GameplayGlobals.hornet_pos = global_position
	
		if randf() > 100.1/afk_timer:
			afk_timer = 0.0
			var randoms = [&'gole-nedosa', &'akana-segamos', &'akana-segamos', &'un-egale', &'la-fenu-feneedle']
			voice.play_by_name(randoms[randi()%len(randoms)])
	else:
		GameplayGlobals.hornet_hp = min(GameplayGlobals.hornet_hp + 3.0 * delta, GameplayGlobals.hornet_max_hp)
		#print("hornet CRENing, hp is now at ", GameplayGlobals.hornet_hp)

func _process(delta: float) -> void:
	if big_animations.has(anim.animation):
		anim.scale = Vector2(0.75, 0.75)
	else:
		anim.scale = Vector2(1.0, 1.0)
	if dmg_cooldown < (GameplayGlobals.hornet_hp - GameplayGlobals.hornet_max_hp)/20.0 or GameplayGlobals.hornet_hp < 1.6:
		vignette.visible = false
