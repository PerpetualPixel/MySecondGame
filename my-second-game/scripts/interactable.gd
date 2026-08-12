extends PhysicsBody3D
class_name Interactable

## PICKABLE: node must be a RigidBody3D; pickup/drop/throw is handled by the player controller.
## DOOR: rotates open around local Y at `open_angle_degrees`.
## DRAWER: slides open along `open_axis` (local space) by `open_distance`.
enum Type { PICKABLE, DOOR, DRAWER }

@export var type: Type = Type.PICKABLE
@export var display_name: String = "Object"

@export_group("Door")
@export var open_angle_degrees: float = 90.0

@export_group("Drawer")
@export var open_axis: Vector3 = Vector3.BACK
@export var open_distance: float = 0.5

@export_group("Animation")
@export var open_speed: float = 4.0

var is_open := false

var _closed_transform: Transform3D
var _target_transform: Transform3D


func _ready() -> void:
	_closed_transform = transform
	_target_transform = transform


func _physics_process(delta: float) -> void:
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
	_target_transform = Transform3D(_closed_transform.basis.rotated(Vector3.UP, angle), _closed_transform.origin)


func _toggle_drawer() -> void:
	is_open = not is_open
	var offset := Vector3.ZERO
	if is_open:
		offset = (_closed_transform.basis * open_axis.normalized()) * open_distance
	_target_transform = Transform3D(_closed_transform.basis, _closed_transform.origin + offset)
