class_name Bench
extends Area2D

@onready var label = $Label

# no bench's collision box should intersect another's

var canBeSatOn := false
var isSatOn := false

signal setSitting(sit: bool, player: Hornet)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setSitting.connect(_on_sit)
	body_entered.connect(_on_entry)
	body_exited.connect(_on_exit)

func _on_sit(sit: bool, hornet: Hornet) -> void:
	hornet.isSitting = sit
	hornet.anim.visible = !sit # should be uncommented in production
	hornet.respawn_point = global_position
	isSatOn = sit
	label.visible = !sit
	if sit:
		$AnimatedSprite2D.play("sitting")
		GameplayGlobals.hornet_hp = GameplayGlobals.hornet_max_hp
	else:
		$AnimatedSprite2D.play("default")

func _on_entry(entity: CollisionObject2D) -> void:
	if 'canSit' in entity: # ie is hornet
		label.visible = true
		canBeSatOn = true
		entity.canSit = true
		entity.bench = self
		return
func _on_exit(entity: CollisionObject2D) -> void:
	if 'canSit' in entity: # ie is hornet
		label.visible = false
		canBeSatOn = false
		entity.canSit = false
		#entity.bench = null
		return

func _do_label_stuff() -> void:
	for entity in get_overlapping_bodies():
		if 'canSit' in entity: # ie is hornet
			label.visible = true
			canBeSatOn = true
			entity.canSit = true
			entity.bench = self
			return
	label.visible = false
	canBeSatOn = false

func _physics_process(delta: float) -> void:
	#_do_label_stuff()
	pass
