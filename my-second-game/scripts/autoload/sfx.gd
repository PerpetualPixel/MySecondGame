extends Node

## Central catalog of procedurally synthesized sound effects. No audio assets
## required - each preset configures an SfxVoice (AudioStreamPlayer3D) that
## synthesizes noise/tone bursts at runtime, plays once, and frees itself.

const SfxVoiceScript := preload("res://scripts/audio/sfx_voice.gd")

const PRESETS := {
	"footstep_concrete": {"duration": 0.06, "noise_amount": 1.0, "noise_filter": "highpass", "filter_strength": 0.2, "tone_amount": 0.15, "tone_freq_start": 180.0, "tone_freq_end": 120.0, "volume": 0.5},
	"footstep_dirt": {"duration": 0.08, "noise_amount": 1.0, "noise_filter": "lowpass", "filter_strength": 0.6, "volume": 0.45},
	"footstep_grass": {"duration": 0.09, "noise_amount": 1.0, "noise_filter": "lowpass", "filter_strength": 0.75, "volume": 0.35},

	"pickup_metal": {"duration": 0.12, "noise_amount": 0.5, "noise_filter": "highpass", "filter_strength": 0.3, "tone_amount": 0.6, "tone_freq_start": 900.0, "tone_freq_end": 500.0, "volume": 0.5},
	"drop_metal": {"duration": 0.25, "noise_amount": 0.6, "noise_filter": "highpass", "filter_strength": 0.15, "tone_amount": 0.7, "tone_freq_start": 220.0, "tone_freq_end": 90.0, "volume": 0.7},

	"pickup_rubber": {"duration": 0.1, "noise_amount": 0.7, "noise_filter": "lowpass", "filter_strength": 0.5, "tone_amount": 0.2, "tone_freq_start": 150.0, "tone_freq_end": 100.0, "volume": 0.45},
	"drop_rubber": {"duration": 0.18, "noise_amount": 0.8, "noise_filter": "lowpass", "filter_strength": 0.55, "tone_amount": 0.3, "tone_freq_start": 120.0, "tone_freq_end": 70.0, "volume": 0.6},
	"tire_bounce": {"duration": 0.14, "noise_amount": 0.6, "noise_filter": "lowpass", "filter_strength": 0.6, "tone_amount": 0.35, "tone_freq_start": 140.0, "tone_freq_end": 80.0, "volume": 0.5},

	"pickup_plastic": {"duration": 0.09, "noise_amount": 0.5, "noise_filter": "highpass", "filter_strength": 0.35, "tone_amount": 0.3, "tone_freq_start": 700.0, "tone_freq_end": 450.0, "volume": 0.4},
	"drop_plastic": {"duration": 0.15, "noise_amount": 0.6, "noise_filter": "highpass", "filter_strength": 0.25, "tone_amount": 0.35, "tone_freq_start": 300.0, "tone_freq_end": 150.0, "volume": 0.5},

	"wrench_install": {"duration": 0.05, "noise_amount": 0.4, "noise_filter": "highpass", "filter_strength": 0.2, "tone_amount": 0.7, "tone_freq_start": 1200.0, "tone_freq_end": 900.0, "pulses": 6, "pulse_gap": 0.07, "volume": 0.4},

	"hood_open": {"duration": 0.5, "noise_amount": 0.5, "noise_filter": "lowpass", "filter_strength": 0.5, "tone_amount": 0.4, "tone_freq_start": 90.0, "tone_freq_end": 140.0, "attack": 0.05, "volume": 0.5},
	"hood_close": {"duration": 0.3, "noise_amount": 0.7, "noise_filter": "highpass", "filter_strength": 0.2, "tone_amount": 0.6, "tone_freq_start": 180.0, "tone_freq_end": 70.0, "volume": 0.65},

	"drawer_open": {"duration": 0.35, "noise_amount": 0.5, "noise_filter": "lowpass", "filter_strength": 0.4, "tone_amount": 0.2, "tone_freq_start": 150.0, "tone_freq_end": 180.0, "volume": 0.4},
	"drawer_close": {"duration": 0.2, "noise_amount": 0.6, "noise_filter": "highpass", "filter_strength": 0.2, "tone_amount": 0.4, "tone_freq_start": 200.0, "tone_freq_end": 90.0, "volume": 0.5},

	"engine_install": {"duration": 0.4, "noise_amount": 0.6, "noise_filter": "lowpass", "filter_strength": 0.65, "tone_amount": 0.8, "tone_freq_start": 140.0, "tone_freq_end": 50.0, "volume": 0.8},
	"engine_start": {"duration": 0.9, "noise_amount": 0.6, "noise_filter": "lowpass", "filter_strength": 0.5, "tone_amount": 0.7, "tone_freq_start": 60.0, "tone_freq_end": 110.0, "attack": 0.05, "volume": 0.7},
	"gas_pour": {"duration": 0.8, "noise_amount": 0.5, "noise_filter": "lowpass", "filter_strength": 0.7, "volume": 0.35},

	"jump": {"duration": 0.12, "noise_amount": 0.3, "noise_filter": "highpass", "filter_strength": 0.2, "tone_amount": 0.6, "tone_freq_start": 300.0, "tone_freq_end": 500.0, "volume": 0.4},
	"land": {"duration": 0.15, "noise_amount": 0.6, "noise_filter": "lowpass", "filter_strength": 0.5, "tone_amount": 0.3, "tone_freq_start": 100.0, "tone_freq_end": 60.0, "volume": 0.5},
	"throw": {"duration": 0.08, "noise_amount": 0.5, "noise_filter": "highpass", "filter_strength": 0.3, "volume": 0.3},
}


func play(preset_name: String, at_position: Vector3, pitch_variance: float = 0.06) -> void:
	if not PRESETS.has(preset_name):
		push_warning("Unknown SFX preset: " + preset_name)
		return
	if not is_inside_tree():
		return

	var voice: AudioStreamPlayer3D = SfxVoiceScript.new()
	get_tree().current_scene.add_child(voice)
	voice.global_position = at_position
	voice.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)

	var preset: Dictionary = PRESETS[preset_name]
	for key in preset:
		voice.set(key, preset[key])

	voice.play_sfx()
