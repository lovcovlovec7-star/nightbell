extends Control

var options_panel
var info_label

func _ready():
	_ensure_input_actions()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_menu()

func _build_menu():
	var bg = ColorRect.new()
	bg.color = Color(0.015, 0.018, 0.025, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box = VBoxContainer.new()
	box.anchor_left = 0.08
	box.anchor_top = 0.16
	box.anchor_right = 0.48
	box.anchor_bottom = 0.9
	box.add_theme_constant_override("separation", 16)
	add_child(box)
	var title = Label.new()
	title.text = "NIGHT BELL:\nOFFICE SHIFT"
	title.add_theme_font_size_override("font_size", 48)
	box.add_child(title)
	info_label = Label.new()
	info_label.text = "Ночная смена. Закрытый офис. Звонок, которого нет в расписании."
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info_label)
	_add_button(box, "New Game", _new_game)
	_add_button(box, "Continue", _continue_game)
	_add_button(box, "Options", _options)
	_add_button(box, "Exit", _exit)
	options_panel = Label.new()
	options_panel.text = "Options: WASD — ходьба, мышь — взгляд, E — взаимодействие, Enter — диалог, Esc — пауза."
	options_panel.visible = false
	options_panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(options_panel)

func _add_button(parent, text, callable):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 46)
	button.pressed.connect(callable)
	parent.add_child(button)

func _new_game():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _continue_game():
	info_label.text = "Сохранение пока не найдено: начните New Game."

func _options():
	options_panel.visible = not options_panel.visible

func _exit():
	get_tree().quit()

func _ensure_input_actions():
	var actions = {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"interact": KEY_E,
		"dialogue_next": KEY_ENTER,
		"pause": KEY_ESCAPE
	}
	for action in actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event = InputEventKey.new()
			event.physical_keycode = actions[action]
			InputMap.action_add_event(action, event)
