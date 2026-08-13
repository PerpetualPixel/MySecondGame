extends AudioStreamPlayer3D

## Plays single hits sliced out of a longer recording.
##
## Source clips here are continuous takes containing many footsteps/landings,
## so playing them whole would ignore the game's own timing. Instead each
## trigger seeks to a measured onset, lets it ring, then stops before the next
## hit in the recording is reached. Timing therefore stays driven by gameplay.
##
## Offsets are measured off the imported clip with an AudioEffectCapture tap,
## backed off slightly so the attack transient isn't clipped.

## Seek points, in seconds, of each usable hit in the source clip.
@export var slice_offsets: PackedFloat32Array = PackedFloat32Array()
## How long to let a hit ring. Must stay below the tightest gap between
## consecutive offsets, or one slice bleeds into the next hit.
@export var slice_duration: float = 0.40
@export var pitch_variance: float = 0.06

## Slices are cut mid-decay, so ramp the tail out rather than stopping dead,
## which would click.
const FADE_TIME := 0.06
const FADE_DEPTH_DB := 30.0

var _time_left := 0.0
var _last_index := -1
var _base_volume_db := 0.0


func _ready() -> void:
	_base_volume_db = volume_db


func play_slice() -> void:
	if slice_offsets.is_empty():
		return

	volume_db = _base_volume_db

	# Avoid repeating the same slice twice running so hits don't sound looped.
	var index := randi() % slice_offsets.size()
	if slice_offsets.size() > 1 and index == _last_index:
		index = (index + 1) % slice_offsets.size()
	_last_index = index

	pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	play(slice_offsets[index])
	_time_left = slice_duration


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		stop()
		volume_db = _base_volume_db
	elif _time_left < FADE_TIME:
		volume_db = _base_volume_db - FADE_DEPTH_DB * (1.0 - _time_left / FADE_TIME)
