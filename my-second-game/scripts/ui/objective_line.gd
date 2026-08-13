extends Label

const STEP := 8.0
const JITTER := 2.5

var strike_progress := 0.0

var _tween: Tween
var _wobble_seed := 0


func _ready() -> void:
	_wobble_seed = randi()


func set_struck(struck: bool, animate: bool) -> void:
	if _tween:
		_tween.kill()

	if not struck:
		strike_progress = 0.0
		modulate = Color(1, 1, 1, 1)
		queue_redraw()
		return

	if not animate:
		strike_progress = 1.0
		modulate = Color(1, 1, 1, 0.55)
		queue_redraw()
		return

	modulate = Color(1, 1, 1, 0.55)
	strike_progress = 0.0
	_tween = create_tween()
	_tween.tween_method(_set_strike_progress, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_strike_progress(value: float) -> void:
	strike_progress = value
	queue_redraw()


func _draw() -> void:
	if strike_progress <= 0.0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = _wobble_seed

	var full_width := size.x
	var y := size.y * 0.55
	var end_x := full_width * strike_progress

	var points := PackedVector2Array()
	var x := 0.0
	while x <= full_width:
		var jitter := rng.randf_range(-JITTER, JITTER)
		if x > end_x:
			break
		points.append(Vector2(x, y + jitter))
		x += STEP

	if points.size() >= 2:
		draw_polyline(points, Color(0.75, 0.08, 0.08, 0.95), 2.5, true)
