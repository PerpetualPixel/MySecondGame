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
			mesh.create_trimesh_collision()


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
