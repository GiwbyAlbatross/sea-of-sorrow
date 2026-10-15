extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_enter)

func _on_body_enter(body: CollisionObject2D):
	if 'dmg' in body:
		body.dmg.emit(1.0)
		if 'respawn_point' in body: # ie is hornet
			#if body.no_input_time > 0.0:
			#	return
			body.global_position = body.respawn_point
			body.no_input_time = 1.1
			body.dmg_cooldown = 1.01
			body.velocity *= 0.0
		#else:
		#	body.queue_free() # hk behaviour 
