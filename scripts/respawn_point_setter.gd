extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_exited.connect(_on_body_entered)

func _on_body_entered(body: CollisionObject2D):
	if 'respawn_point' in body:
		body.respawn_point = body.global_position
		body.dmg_cooldown = 0.2 # free iframes :)
		print("setting respawn point for ", body, " to ", body.global_position)
