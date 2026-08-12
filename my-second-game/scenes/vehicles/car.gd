extends VehicleBody3D
class_name Car

const ENGINE_POWER := 800.0
const REVERSE_POWER := 400.0
const BRAKE_FORCE := 40.0
const MAX_STEER := 0.6
const STEER_SPEED := 3.0
const ATTACH_RANGE := 1.4

var has_engine := false
var has_gas := false
var wheel_filled := [false, false, false, false]

var driver: Node = null
var _steer_amount := 0.0

@onready var wheels: Array[VehicleWheel3D] = [$WheelFL, $WheelFR, $WheelRL, $WheelRR]
@onready var engine_slot: Marker3D = $EngineSlot
@onready var gas_slot: Marker3D = $GasSlot
@onready var driver_door: Marker3D = $DriverDoor
@onready var exit_point: Marker3D = $ExitPoint
@onready var driver_camera: Camera3D = $DriverCamera


func wheels_attached() -> int:
	return wheel_filled.count(true)


func can_drive() -> bool:
	return has_engine and has_gas and wheels_attached() >= 4


func _physics_process(delta: float) -> void:
	if driver == null:
		return

	var steer_input := 0.0
	if Input.is_action_pressed("move_left"):
		steer_input += 1.0
	if Input.is_action_pressed("move_right"):
		steer_input -= 1.0
	_steer_amount = move_toward(_steer_amount, steer_input, STEER_SPEED * delta)
	steering = _steer_amount * MAX_STEER

	if not can_drive():
		engine_force = 0.0
		brake = BRAKE_FORCE
		return

	var forward_speed := -global_transform.basis.z.dot(linear_velocity)

	if Input.is_action_pressed("move_forward"):
		engine_force = ENGINE_POWER
		brake = 0.0
	elif Input.is_action_pressed("move_back"):
		if forward_speed > 0.5:
			engine_force = 0.0
			brake = BRAKE_FORCE
		else:
			engine_force = -REVERSE_POWER
			brake = 0.0
	else:
		engine_force = 0.0
		brake = 0.0


func try_interact(player: Node, hit_point: Vector3) -> void:
	if player.held_body != null:
		_try_attach_part(player, hit_point)
	else:
		_try_enter(player, hit_point)


func _try_enter(player: Node, hit_point: Vector3) -> void:
	if hit_point.distance_to(driver_door.global_position) > ATTACH_RANGE:
		return
	if not can_drive():
		return

	driver = player
	player.enter_vehicle(self)
	driver_camera.current = true


func exit_vehicle(player: Node) -> void:
	driver = null
	engine_force = 0.0
	brake = BRAKE_FORCE
	steering = 0.0
	_steer_amount = 0.0
	driver_camera.current = false
	player.exit_vehicle(exit_point.global_position)


func _try_attach_part(player: Node, hit_point: Vector3) -> void:
	var part: Node3D = player.held_body
	if not (part is Interactable):
		return

	match part.part_type:
		"wheel":
			_try_attach_wheel(player, hit_point)
		"engine":
			_try_attach_engine(player, hit_point)
		"gas":
			_try_attach_gas(player, hit_point)


func _try_attach_wheel(player: Node, hit_point: Vector3) -> void:
	var index := _nearest_empty_wheel_index(hit_point)
	if index == -1:
		return

	var part: RigidBody3D = player.take_held_part()
	wheel_filled[index] = true
	_attach_visual(part, wheels[index], Vector3(0, 0, 90))


func _nearest_empty_wheel_index(hit_point: Vector3) -> int:
	var best_index := -1
	var best_dist := ATTACH_RANGE
	for i in wheels.size():
		if wheel_filled[i]:
			continue
		var dist := hit_point.distance_to(wheels[i].global_position)
		if dist < best_dist:
			best_dist = dist
			best_index = i
	return best_index


func _try_attach_engine(player: Node, hit_point: Vector3) -> void:
	if has_engine:
		return
	if hit_point.distance_to(engine_slot.global_position) > ATTACH_RANGE:
		return

	var part: RigidBody3D = player.take_held_part()
	has_engine = true
	_attach_visual(part, engine_slot)


func _try_attach_gas(player: Node, hit_point: Vector3) -> void:
	if has_gas:
		return
	if hit_point.distance_to(gas_slot.global_position) > ATTACH_RANGE:
		return

	var part: RigidBody3D = player.take_held_part()
	has_gas = true
	part.queue_free()


func _attach_visual(part: Node3D, slot: Node3D, extra_rotation_degrees: Vector3 = Vector3.ZERO) -> void:
	var source_mesh: MeshInstance3D = part.get_node_or_null("MeshInstance3D")
	if source_mesh:
		var visual := MeshInstance3D.new()
		visual.mesh = source_mesh.mesh
		visual.set_surface_override_material(0, source_mesh.get_surface_override_material(0))
		visual.rotation_degrees = extra_rotation_degrees
		slot.add_child(visual)
	part.queue_free()
