extends Node

var audiostreamplayer: AudioStreamPlayer
var queue: Array[AudioStream] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audiostreamplayer = AudioStreamPlayer.new()
	add_child(audiostreamplayer)
	audiostreamplayer.finished.connect(_pick_next)

# public methods
func schedule_song_path(path: String):
	queue.append(load(path))
	_on_schedule()
func schedule_song(stream: AudioStream):
	queue.append(stream)
	_on_schedule()
func playnext_path(path: String):
	queue.push_front(load(path))
	_on_schedule()
func playnext_song(stream: AudioStream):
	queue.push_front(stream)
	_on_schedule()
func clear_queue():
	# does NOT stop currently running songs
	queue.clear()

# signal handlers
func _pick_next():
	if len(queue) > 0:
		audiostreamplayer.stream = queue.pop_front()
	audiostreamplayer.play()

func _on_schedule():
	if not audiostreamplayer.playing:
		_pick_next()
