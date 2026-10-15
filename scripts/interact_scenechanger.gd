class_name InteractSceneChanger
extends Area2D

@onready var label = $Label
@export var target_scene: String
@export var target_position: Vector2

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
	print(" ")
	print("CHANGING SCENE")
	print("to: '", target_scene, "' at: ", target_position)
	GameplayGlobals.hornet_should_move = true
	GameplayGlobals.hornet_should_move_to = target_position
	get_tree().change_scene_to_file(target_scene)
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
