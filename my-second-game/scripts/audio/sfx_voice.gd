extends AudioStreamPlayer3D

## A one-shot procedurally synthesized sound. Spawned at runtime by Sfx.play(),
## configures itself from a preset dictionary, plays, and frees itself.

const MIX_RATE := 22050.0

var duration := 0.2
var noise_amount := 1.0
var noise_filter := "none" # "none", "lowpass", "highpass"
var filter_strength := 0.5
var tone_amount := 0.0
var tone_freq_start := 200.0
var tone_freq_end := 200.0
var pulses := 1
var pulse_gap := 0.0
var attack := 0.005
var volume := 1.0

var _playback: AudioStreamGeneratorPlayback
var _time_left := 0.0
var _drain_time := 0.0
var _elapsed := 0.0
var _last_sample := 0.0
var _lp_state := 0.0
var _tone_phase := 0.0


func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.3
	stream = generator


func play_sfx() -> void:
	play()
	_playback = get_stream_playback()
	_time_left = duration * pulses + pulse_gap * maxf(pulses - 1, 0)
	_drain_time = _time_left + 0.3
	_elapsed = 0.0
	_last_sample = 0.0
	_lp_state = 0.0
	_tone_phase = 0.0
	_fill_buffer()


func _process(delta: float) -> void:
	if _playback == null:
		return
	if _time_left > 0.0:
		_fill_buffer()
	_drain_time -= delta
	if _drain_time <= 0.0:
		queue_free()


func _fill_buffer() -> void:
	var frame_time := 1.0 / MIX_RATE
	var frames := _playback.get_frames_available()
	var unit_time := duration + pulse_gap

	for i in frames:
		if _time_left <= 0.0:
			break
		_time_left -= frame_time

		var t_in_unit := fmod(_elapsed, unit_time)
		_elapsed += frame_time

		var sample := 0.0
		if t_in_unit <= duration:
			var progress := t_in_unit / duration
			var env: float
			if t_in_unit < attack:
				env = t_in_unit / maxf(attack, 0.0001)
			else:
				env = pow(1.0 - clampf((t_in_unit - attack) / maxf(duration - attack, 0.0001), 0.0, 1.0), 1.6)

			if noise_amount > 0.0:
				var noise := randf_range(-1.0, 1.0)
				var filtered := noise
				if noise_filter == "lowpass":
					_lp_state = lerp(_lp_state, noise, 1.0 - filter_strength)
					filtered = _lp_state
				elif noise_filter == "highpass":
					filtered = noise - _last_sample
					_last_sample = noise
				sample += filtered * noise_amount * env

			if tone_amount > 0.0:
				var freq := lerp(tone_freq_start, tone_freq_end, progress)
				_tone_phase += freq * frame_time * TAU
				sample += sin(_tone_phase) * tone_amount * env

		_playback.push_frame(Vector2(sample, sample) * volume)
