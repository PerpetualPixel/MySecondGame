extends CanvasLayer

const ObjectiveLineScene := preload("res://scenes/ui/objective_line.tscn")

@onready var objective_list: VBoxContainer = $ObjectivePanel/VBox/ObjectiveList
@onready var scribble_sound: AudioStreamPlayer = $ScribbleSound

var _lines: Dictionary[String, Label] = {}


func _ready() -> void:
	Objectives.objective_added.connect(_on_objective_added)
	Objectives.objective_completed.connect(_on_objective_completed)

	for id in Objectives.get_order():
		_on_objective_added(id, Objectives.get_text(id))
		if Objectives.is_completed(id):
			_lines[id].set_struck(true, false)


func _on_objective_added(id: String, text: String) -> void:
	if _lines.has(id):
		return
	var line: Label = ObjectiveLineScene.instantiate()
	line.text = text
	objective_list.add_child(line)
	_lines[id] = line


func _on_objective_completed(id: String) -> void:
	if not _lines.has(id):
		return
	_lines[id].set_struck(true, true)
	scribble_sound.play_scribble()
