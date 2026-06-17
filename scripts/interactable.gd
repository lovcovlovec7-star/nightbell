extends Area3D
class_name Interactable

@export var label = "E — взаимодействовать"
@export var kind = "generic"
@export var payload = ""

func setup(new_label, new_kind, new_payload):
	label = new_label
	kind = new_kind
	payload = new_payload
