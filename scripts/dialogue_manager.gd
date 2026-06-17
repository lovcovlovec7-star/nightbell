extends CanvasLayer
class_name DialogueManager

signal closed

var panel
var portrait
var name_label
var role_label
var body_label
var lines = []
var index = 0
var active = false
var portrait_path = ""

func _ready():
	_build()
	hide_dialogue()

func _build():
	panel = PanelContainer.new()
	panel.anchor_left = 0.04
	panel.anchor_top = 0.70
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.96
	add_child(panel)
	var row = HBoxContainer.new()
	panel.add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(150, 220)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var col = VBoxContainer.new()
	row.add_child(col)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 26)
	col.add_child(name_label)
	role_label = Label.new()
	role_label.add_theme_font_size_override("font_size", 18)
	col.add_child(role_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 22)
	col.add_child(body_label)

func start_dialogue(npc_name, role, new_lines, new_portrait):
	lines = new_lines
	index = 0
	active = true
	name_label.text = npc_name
	role_label.text = role
	portrait_path = new_portrait
	if new_portrait != "" and ResourceLoader.exists(new_portrait):
		portrait.texture = load(new_portrait)
	else:
		portrait.texture = null
	panel.visible = true
	_show_current()

func next():
	if not active:
		return
	index += 1
	if index >= lines.size():
		hide_dialogue()
		emit_signal("closed")
	else:
		_show_current()

func _show_current():
	body_label.text = str(lines[index]) + "\n\n[Enter] дальше"

func hide_dialogue():
	active = false
	if panel:
		panel.visible = false
