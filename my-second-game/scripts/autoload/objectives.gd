extends Node

signal objective_added(id: String, text: String)
signal objective_completed(id: String)

var _order: Array[String] = []
var _texts: Dictionary[String, String] = {}
var _completed: Dictionary[String, bool] = {}


func add(id: String, text: String) -> void:
	if _texts.has(id):
		return
	_order.append(id)
	_texts[id] = text
	_completed[id] = false
	objective_added.emit(id, text)


func complete(id: String) -> void:
	if not _texts.has(id) or _completed.get(id, false):
		return
	_completed[id] = true
	objective_completed.emit(id)


func is_completed(id: String) -> bool:
	return _completed.get(id, false)


func get_order() -> Array[String]:
	var copy: Array[String] = []
	copy.assign(_order)
	return copy


func get_text(id: String) -> String:
	return _texts.get(id, "")


func reset() -> void:
	_order.clear()
	_texts.clear()
	_completed.clear()
