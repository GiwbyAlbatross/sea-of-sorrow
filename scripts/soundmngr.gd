class_name SoundManager
extends AudioStreamPlayer2D

@export var sounds: Dictionary[StringName, AudioStream] = {}

var _current: StringName

func play_by_name(name: StringName, gain_db := 0.0, pitch_stddev := 0.001, pitch_mean := 1.0, overwrite := false):
	if name == &'':
		playing = false
		return
	if playing and not overwrite:
		return
	
	var stream_ = sounds.get(name)
	if stream_ != null:
		_current = name
		pitch_scale = randfn(pitch_mean, pitch_stddev)
		volume_db = gain_db
		stream = stream_
		playing = true
	else:
		push_warning("No such key '" + str(name) + "' in soundmanager '" + str(get_path()) + "'.")

func get_current() -> StringName:
	if !playing:
		return &''
	if volume_linear < 0.01:
		return &''
	return _current
