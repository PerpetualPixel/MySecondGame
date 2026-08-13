extends AudioStreamPlayer3D

## Plays individual footsteps sliced out of a continuous walking recording.
##
## The source clip walks at a fixed ~0.68s per step, which is slower than the
## player's stride. Rather than pitch-shifting the whole loop to fit (which
## would badly colour the timbre), each step is triggered as a one-shot: seek
## to a known step onset, let it ring, then stop before the next step in the
## recording is reached. Cadence is therefore driven entirely by the caller,
## so it always matches the player's actual movement.
##
## Onsets were measured off the imported clip via an AudioEffectCapture tap,
## then backed off slightly so the initial transient isn't clipped.
const STEP_OFFSETS: Array[float] = [0.46, 1.17, 1.87, 2.54, 3.21, 3.86, 4.56, 5.21, 5.91, 6.59, 7.30]

## How long to let a single step ring before stopping. Must stay below the
## source clip's ~0.65s step spacing so we never bleed into the next step.
const SLICE_DURATION := 0.40

var _time_left := 0.0
var _last_index := -1


func play_step(pitch_variance: float = 0.06) -> void:
	# Avoid repeating the same slice twice in a row so steps don't sound looped.
	var index := randi() % STEP_OFFSETS.size()
	if STEP_OFFSETS.size() > 1 and index == _last_index:
		index = (index + 1) % STEP_OFFSETS.size()
	_last_index = index

	pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	play(STEP_OFFSETS[index])
	_time_left = SLICE_DURATION


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		stop()
