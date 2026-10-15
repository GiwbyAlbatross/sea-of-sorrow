extends Area2D

var broken := false

signal dmg(amt: float)

func _ready():
	dmg.connect(_on_dmg)

func _on_dmg(_amt: float):
	print("breakablething: '", name, "' breaking!")
	if broken:
		return
	broken = true
	$BreakableThingTexture.visible = false
	$BreakableThingParticles.emitting = true
	$CollisionShape2D.disabled = true
