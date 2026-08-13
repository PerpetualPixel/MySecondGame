extends PhysicsBody3D
class_name Interactable

## PICKABLE: node must be a RigidBody3D; pickup/drop/throw is handled by the player controller.
## DOOR: rotates open around `door_axis` (local space) at `open_angle_degrees`.
## DRAWER: slides open along `open_axis` (local space) by `open_distance`.
enum Type { PICKABLE, DOOR, DRAWER }

@export var type: Type = Type.PICKABLE
@export var display_name: String = "Object"
## Non-empty for PICKABLE parts the car assembly can accept (e.g. "wheel", "engine", "gas").
@export var part_type: String = ""
## Used to pick pickup/drop sound presets, e.g. "metal", "rubber", "plastic".
@export var material_kind: String = "metal"

@export_group("Door")
@export var open_angle_degrees: float = 90.0
## Hinge axis in local space. Vector3.UP swings sideways like a door; Vector3.RIGHT tilts up like a hood.
@export var door_axis: Vector3 = Vector3.UP

@export_group("Drawer")
@export var open_axis: Vector3 = Vector3.BACK
@export var open_distance: float = 0.5

@export_group("Animation")
@export var open_speed: float = 4.0

@export_group("Sound")
## Sfx preset names; leave empty to skip. Used by DOOR/DRAWER on toggle.
@export var open_sound: String = ""
@export var close_sound: String = ""
## Sfx preset played on hard contact with another body; leave empty to skip.
@export var bounce_sound: String = ""
@export var bounce_cooldown: float = 0.15
@export var bounce_min_speed: float = 1.5

var is_open := false

var _closed_transform: Transform3D
var _target_transform: Transform3D
var _bounce_timer := 0.0


func _ready() -> void:
	_closed_transform = transform
	_target_transform = transform

	if bounce_sound != "" and self is RigidBody3D:
		var rb := self as RigidBody3D
		rb.contact_monitor = true
		rb.max_contacts_reported = 4
		rb.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _bounce_timer > 0.0:
		_bounce_timer = maxf(_bounce_timer - delta, 0.0)

	if type == Type.PICKABLE:
		return
	if transform != _target_transform:
		transform = transform.interpolate_with(_target_transform, clamp(open_speed * delta, 0.0, 1.0))


func interact() -> void:
	match type:
		Type.DOOR:
			_toggle_door()
		Type.DRAWER:
			_toggle_drawer()
		Type.PICKABLE:
			pass


func _toggle_door() -> void:
	is_open = not is_open
	var angle := deg_to_rad(open_angle_degrees) if is_open else 0.0
	_target_transform = Transform3D(_closed_transform.basis.rotated(door_axis.normalized(), angle), _closed_transform.origin)
	_play_toggle_sound()


func _toggle_drawer() -> void:
	is_open = not is_open
	var offset := Vector3.ZERO
	if is_open:
		offset = (_closed_transform.basis * open_axis.normalized()) * open_distance
	_target_transform = Transform3D(_closed_transform.basis, _closed_transform.origin + offset)
	_play_toggle_sound()


func _play_toggle_sound() -> void:
	var sound := open_sound if is_open else close_sound
	if sound != "":
		Sfx.play(sound, global_position)


func _on_body_entered(_body: Node) -> void:
	if bounce_sound == "" or _bounce_timer > 0.0:
		return
	if self is RigidBody3D and (self as RigidBody3D).linear_velocity.length() < bounce_min_speed:
		return
	_bounce_timer = bounce_cooldown
	Sfx.play(bounce_sound, global_position)
