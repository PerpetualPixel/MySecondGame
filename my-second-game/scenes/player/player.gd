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

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_crouching := false

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interact_ray: RayCast3D = $Camera3D/InteractRayCast3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
	if interact_ray.is_colliding():
		var collider := interact_ray.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact()
