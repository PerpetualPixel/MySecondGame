extends AudioStreamPlayer

const MIX_RATE := 22050.0
const DURATION := 0.35
const SCRATCH_COUNT := 5.0

var _playback: AudioStreamGeneratorPlayback
var _time_left := 0.0
var _phase := 0.0
var _last_sample := 0.0


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.2
	stream = generator


func play_scribble() -> void:
	play()
	_playback = get_stream_playback()
	_time_left = DURATION
	_phase = 0.0
	_last_sample = 0.0
	_fill_buffer()


func _process(_delta: float) -> void:
	if _playback == null or _time_left <= 0.0:
		return
	_fill_buffer()


func _fill_buffer() -> void:
	var frame_time := 1.0 / MIX_RATE
	var frames := _playback.get_frames_available()

	for i in frames:
		if _time_left <= 0.0:
			break
		_time_left -= frame_time
		_phase += frame_time

		# Rapid on/off pulses so the noise reads as short pencil strokes.
		var scratch_env := absf(sin(_phase * TAU * SCRATCH_COUNT / DURATION))
		scratch_env = pow(scratch_env, 3.0)
		var fade := clampf(_time_left / DURATION, 0.0, 1.0)

		var noise := randf_range(-1.0, 1.0)
		# 1-pole high-pass so it sounds scratchy rather than a dull rumble.
		var filtered := noise - _last_sample
		_last_sample = noise

		var sample := filtered * scratch_env * fade * 0.5
		_playback.push_frame(Vector2(sample, sample))

	if _time_left <= 0.0:
		_playback = null
