extends Area2D

@export var target_scene: String
@export var target_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_enter)

# disclaimer: this is janky but it works
func _on_body_enter(body: PhysicsBody2D) -> void:
	if 'respawn_point' in body: # only hornet has this property
		#var scene = target_scene.instantiate()
		print(" ")
		print("CHANGING SCENE")
		print("to: '", target_scene, "' at: ", target_position)
		GameplayGlobals.hornet_should_move = true
		GameplayGlobals.hornet_should_move_to = target_position
		get_tree().change_scene_to_file(target_scene)
		#scene.get_node("/root/Node2D/hornet").global_position = target_position
