extends CanvasLayer
class_name DeviceUI

signal closed
signal action(action_name)

var panel
var title_label
var body_label
var buttons = []
var active = false

func _ready():
	_build()
	close()

func _build():
	panel = PanelContainer.new()
	panel.anchor_left = 0.18
	panel.anchor_top = 0.12
	panel.anchor_right = 0.82
	panel.anchor_bottom = 0.86
	add_child(panel)
	var col = VBoxContainer.new()
	panel.add_child(col)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 32)
	col.add_child(title_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 20)
	col.add_child(body_label)
	for action_name in ["read_mail", "print", "camera_reception", "camera_open_space", "camera_archive", "camera_server", "close"]:
		var button = Button.new()
		button.text = action_name
		button.pressed.connect(func(): _pressed(action_name))
		buttons.append(button)
		col.add_child(button)

func open_device(title, body, available):
	active = true
	title_label.text = title
	body_label.text = body
	for button in buttons:
		button.visible = available.has(button.text)
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _pressed(action_name):
	if action_name == "close":
		close()
	else:
		emit_signal("action", action_name)

func close():
	active = false
	if panel:
		panel.visible = false
	emit_signal("closed")
