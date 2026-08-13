extends Node3D

## Generates trimesh collision for every mesh under this node at runtime.
## Used for large imported environment scenes where hand-placing collision
## shapes per-mesh isn't practical. Meshes whose name contains one of these
## (case-insensitive) are skipped, e.g. glass panes and door slabs that
## shouldn't block the player from walking through the opening they sit in.
@export var skip_name_contains: PackedStringArray = ["DOOR", "GLASS", "JALOUSIE"]


func _ready() -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(self, meshes)
	for mesh in meshes:
		if not _should_skip(mesh.name):
			_add_collision(mesh)


func _add_collision(mesh: MeshInstance3D) -> void:
	# Deliberately not MeshInstance3D.create_trimesh_collision(): the shape it
	# builds is single-sided, and much of this environment (the ground plane in
	# particular) is zero-thickness geometry whose faces point away from the
	# play area. Rays still hit those faces and kinematic bodies still resolve
	# against them, but rigid bodies fall straight through. Building the shape
	# by hand lets us enable backface collision so props and the car rest on it.
	if mesh.mesh == null:
		return
	var shape := mesh.mesh.create_trimesh_shape()
	if shape == null:
		return
	shape.backface_collision = true

	var body := StaticBody3D.new()
	body.name = mesh.name + "_col"
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	mesh.add_child(body)


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_collect_meshes(child, out)


func _should_skip(mesh_name: String) -> bool:
	var upper := mesh_name.to_upper()
	for token in skip_name_contains:
		if upper.contains(token):
			return true
	return false
