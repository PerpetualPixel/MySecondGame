extends CharacterBody3D

const SPEED := 5.0
const CROUCH_SPEED := 2.5
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.003

const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.0
const STAND_CAMERA_Y := 1.6
const CROUCH_CAMERA_Y := 0.9
const CROUCH_LERP_SPEED := 6.0

const INTERACT_DISTANCE := 3.0
const THROW_FORCE := 8.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching := false

var held_body: RigidBody3D = null
var _held_original_parent: Node = null
var _held_original_layer: int = 0
var _held_original_mask: int = 0

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interact_ray: RayCast3D = $Camera3D/InteractRayCast3D
@onready var hold_point: Marker3D = $Camera3D/HoldPoint


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_ray.target_position = Vector3(0, 0, -INTERACT_DISTANCE)
	# Avoid mutating the shared CapsuleShape3D resource across instances.
	collision_shape.shape = collision_shape.shape.duplicate()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("throw"):
		_throw_held()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	is_crouching = Input.is_action_pressed("crouch")

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	_update_crouch(delta)

	var speed := CROUCH_SPEED if is_crouching else SPEED
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()


func _update_crouch(delta: float) -> void:
	var target_height := CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	var target_camera_y := CROUCH_CAMERA_Y if is_crouching else STAND_CAMERA_Y

	var shape: CapsuleShape3D = collision_shape.shape
	shape.height = move_toward(shape.height, target_height, CROUCH_LERP_SPEED * delta)
	collision_shape.position.y = shape.height * 0.5
	camera.position.y = move_toward(camera.position.y, target_camera_y, CROUCH_LERP_SPEED * delta)


func _try_interact() -> void:
	if held_body != null:
		_release_held(false)
		return

	if not interact_ray.is_colliding():
		return

	var collider := interact_ray.get_collider()
	if not (collider is Interactable):
		return

	if collider.type == Interactable.Type.PICKABLE and collider is RigidBody3D:
		_pick_up(collider)
	else:
		collider.interact()


func _pick_up(body: RigidBody3D) -> void:
	held_body = body
	_held_original_parent = body.get_parent()
	_held_original_layer = body.collision_layer
	_held_original_mask = body.collision_mask

	_held_original_parent.remove_child(body)
	hold_point.add_child(body)
	body.transform = Transform3D.IDENTITY

	body.freeze = true
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.collision_layer = 0
	body.collision_mask = 0


func _throw_held() -> void:
	if held_body != null:
		_release_held(true)


func _release_held(throw: bool) -> void:
	var body := held_body
	var released_transform := body.global_transform

	hold_point.remove_child(body)
	_held_original_parent.add_child(body)
	body.global_transform = released_transform

	body.collision_layer = _held_original_layer
	body.collision_mask = _held_original_mask
	body.freeze = false
	body.linear_velocity = velocity
	body.angular_velocity = Vector3.ZERO

	if throw:
		body.linear_velocity += -camera.global_transform.basis.z * THROW_FORCE

	held_body = null
	_held_original_parent = null
