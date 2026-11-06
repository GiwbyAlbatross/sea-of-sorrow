extends Node2D

@export var WIDTH: int = 24
@export_range(0.0, 1.0, 0.0001, "higher -> more likely") var PLACE_CHANCE: float = 0.1
@export var seed: int # still TECHNICALLY determinstic which is cool for TAS runners and stuff
@export var tile_seperation = Vector2(64.0, 64.0)
@export var position_stddev := 5.0
@export var object_scale := 0.5

@export var objects: Array[PackedScene] = []

var rand: RandomNumberGenerator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rand = RandomNumberGenerator.new()
	rand.seed = seed
	_place_tiles(0, 32)

func _place_tiles(starting_at: int, how_many: int=16) -> void: 
	# lay Node2D tiles in a grid, named by their position ({x_pos}-{y_pos})
	# tiles are laid 64x64
	for y in range(how_many):
		for x in range(WIDTH):
			var child = Node2D.new()
			child.name = "%03d-%03d" % [x,y]
			child.position = Vector2(x,y) * tile_seperation
			add_child(child)
			_place_object_tile(child)

func _place_object_tile(parent: Node2D) -> bool:
	# might add an object under `parent`. returns whether or not it did
	if rand.randf() > PLACE_CHANCE:
		return false
	# otherwise place something
	var object: PackedScene = objects[randi() % len(objects)]
	var child: Node2D = object.instantiate()
	parent.add_child(child)
	child.scale *= object_scale
	child.position = Vector2(rand.randfn(0.0, position_stddev), rand.randfn(0.0, position_stddev))
	return true
