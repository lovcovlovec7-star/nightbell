extends Node3D

const PlayerController = preload("res://scripts/player_controller.gd")
const QuestManager = preload("res://scripts/quest_manager.gd")
const DialogueManager = preload("res://scripts/dialogue_manager.gd")
const DeviceUI = preload("res://scripts/device_ui.gd")
const Interactable = preload("res://scripts/interactable.gd")
const RadioLogic = preload("res://scripts/radio.gd")

var player
var camera
var quest
var dialogue
var device_ui
var radio_logic
var hud_objective
var hud_evidence
var prompt_label
var pause_panel
var current_interactable = null
var furniture_count = 0
var rooms_count = 11
var npc_defs = [
	{"name":"Кадзуо Сато","role":"охранник","file":"kazuo_sato.png","pos":Vector3(-7,0,1),"step":0},
	{"name":"Ая Морита","role":"ресепшен","file":"aya_morita.png","pos":Vector3(-3,0,1),"step":1},
	{"name":"Начальник смены","role":"строгий руководитель","file":"boss.png","pos":Vector3(8,0,-3),"step":-1},
	{"name":"Эми Накамура","role":"HR-сотрудник","file":"hr_worker.png","pos":Vector3(2,0,-9),"step":-1},
	{"name":"Рё Кобаяси","role":"IT-сотрудник","file":"it_worker.png","pos":Vector3(11,0,-8),"step":-1},
	{"name":"Синъя Ватанабэ","role":"дежурный инженер","file":"engineer.png","pos":Vector3(11,0,5),"step":-1},
	{"name":"Юи Танакa","role":"уборка ночной смены","file":"cleaner.png","pos":Vector3(-10,0,-8),"step":-1}
]

func _ready():
	_ensure_input_actions()
	_build_world()
	_build_ui()
	quest = QuestManager.new()
	add_child(quest)
	quest.objective_changed.connect(func(text): hud_objective.text = "Цель: " + text)
	quest.evidence_changed.connect(func(count): hud_evidence.text = "Улики: " + str(count))
	dialogue = DialogueManager.new()
	add_child(dialogue)
	dialogue.closed.connect(_unlock_player)
	device_ui = DeviceUI.new()
	add_child(device_ui)
	device_ui.closed.connect(_unlock_player)
	device_ui.action.connect(_device_action)
	radio_logic = RadioLogic.new()
	add_child(radio_logic)
	quest.ready_state()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_world():
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.08, 0.10, 0.13)
	world.environment = env
	add_child(world)
	_add_box("Floor", Vector3(0,-0.06,-3), Vector3(28,0.12,24), Color(0.08,0.085,0.09), true)
	_make_rooms()
	_make_player()
	_make_npcs()
	_make_devices()
	_make_lights()

func _make_player():
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PlayerController)
	player.position = Vector3(-7, 0.1, 5)
	add_child(player)
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.height = 1.7
	capsule.radius = 0.32
	shape.shape = capsule
	shape.position.y = 0.85
	player.add_child(shape)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = 1.65
	camera.current = true
	player.add_child(camera)

func _make_rooms():
	var rooms = [
		["РЕСЕПШЕН", Vector3(-4,0,3), Vector3(8,0.12,5), Color(0.11,0.10,0.09)],
		["ОХРАНА", Vector3(-10,0,3), Vector3(4,0.12,5), Color(0.07,0.09,0.11)],
		["ОЖИДАНИЕ", Vector3(3,0,3), Vector3(5,0.12,5), Color(0.09,0.08,0.10)],
		["OPEN SPACE", Vector3(5,0,-4), Vector3(12,0.12,7), Color(0.08,0.09,0.10)],
		["АРХИВ", Vector3(-8,0,-7), Vector3(6,0.12,5), Color(0.12,0.095,0.07)],
		["СЕРВЕРНАЯ", Vector3(10,0,-9), Vector3(6,0.12,5), Color(0.06,0.09,0.12)],
		["КУХНЯ", Vector3(-1,0,-9), Vector3(5,0.12,5), Color(0.08,0.11,0.08)],
		["ТУАЛЕТ", Vector3(-12,0,-2), Vector3(4,0.12,4), Color(0.09,0.10,0.11)],
		["CCTV", Vector3(-12,0,7), Vector3(4,0.12,3), Color(0.06,0.08,0.10)],
		["КОРИДОР", Vector3(0,0,0), Vector3(24,0.10,2), Color(0.07,0.07,0.075)],
		["ЛИФТ / ЛЕСТНИЦА", Vector3(12,0,3), Vector3(4,0.12,4), Color(0.075,0.075,0.08)]
	]
	for room in rooms:
		_add_room(str(room[0]), room[1], room[2], room[3])
	_populate_furniture()

func _add_room(label, pos, size, color):
	_add_box(label + " floor", pos + Vector3(0,0.01,0), size, color, false)
	_add_box(label + " north wall", pos + Vector3(0,1.2,-size.z/2), Vector3(size.x,2.4,0.12), Color(0.13,0.14,0.15), true)
	_add_box(label + " south wall", pos + Vector3(0,1.2,size.z/2), Vector3(size.x,2.4,0.12), Color(0.13,0.14,0.15), true)
	_add_box(label + " west wall", pos + Vector3(-size.x/2,1.2,0), Vector3(0.12,2.4,size.z), Color(0.12,0.13,0.14), true)
	_add_box(label + " east wall", pos + Vector3(size.x/2,1.2,0), Vector3(0.12,2.4,size.z), Color(0.12,0.13,0.14), true)
	_add_box("Табличка " + label, pos + Vector3(-size.x/2 + 0.08,1.6,0), Vector3(0.04,0.35,1.2), Color(0.85,0.82,0.62), false)
	_add_label_3d(label, pos + Vector3(-size.x/2 + 0.12,1.75,0), 0.28)

func _populate_furniture():
	for x in [-1, 2, 5, 8]:
		for z in [-5, -3]:
			_add_desk(Vector3(x,0,z))
	for x in [-9,-7,-5]:
		for z in [-8,-6]:
			_add_shelf(Vector3(x,0,z))
	for x in [-4,-2,2,4,6,8,10,-10,-12]:
		_add_chair(Vector3(x,0,4.5))
	_add_counter(Vector3(-4,0,1.0), "стойка ресепшена")
	_add_counter(Vector3(-9.5,0,1.0), "стойка охраны")
	for i in range(18):
		_add_box("Папка " + str(i), Vector3(-9 + (i % 6) * 0.8, 0.55, -7.8 + int(i / 6) * 0.9), Vector3(0.42,0.12,0.28), Color(0.18 + 0.03 * (i % 3),0.12,0.07), false)
	for i in range(10):
		_add_box("Растение/мусорка/лампа " + str(i), Vector3(-12 + i * 2.4,0.4,6.8), Vector3(0.28,0.8,0.28), Color(0.08,0.25,0.12), true)
	for x in [9.2,10.5,11.8]:
		_add_box("Серверная стойка", Vector3(x,1,-9), Vector3(0.7,2.0,1.4), Color(0.02,0.025,0.03), true)
		_add_box("Индикаторы серверов", Vector3(x,1.1,-8.25), Vector3(0.55,1.4,0.02), Color(0.0,0.5,0.8), false)

func _make_npcs():
	for def in npc_defs:
		var root = Node3D.new()
		root.name = def.name
		root.position = def.pos
		add_child(root)
		var plane = MeshInstance3D.new()
		var mesh = PlaneMesh.new()
		mesh.size = Vector2(1.25, 2.25)
		plane.mesh = mesh
		plane.position.y = 1.13
		plane.rotation_degrees.y = 180
		var mat = StandardMaterial3D.new()
		var npc_texture_path = "res://assets/npc_png/" + def.file
		if ResourceLoader.exists(npc_texture_path):
			mat.albedo_texture = load(npc_texture_path)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		else:
			mat.albedo_color = Color(0.035, 0.04, 0.055, 1.0)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		plane.material_override = mat
		root.add_child(plane)
		_add_box(def.name + " подставка", def.pos + Vector3(0,0.03,0), Vector3(1.1,0.06,0.45), Color(0.02,0.02,0.025), true)
		var area = Area3D.new()
		area.set_script(Interactable)
		area.setup("E — поговорить: " + def.name + ", " + def.role, "npc", def.name)
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(1.2,2.2,0.6)
		shape.shape = box
		shape.position.y = 1.1
		area.add_child(shape)
		root.add_child(area)
		var body = StaticBody3D.new()
		var c = CollisionShape3D.new()
		var b = BoxShape3D.new()
		b.size = Vector3(0.9,1.9,0.35)
		c.shape = b
		c.position.y = 0.95
		body.add_child(c)
		root.add_child(body)
		_add_label_3d(def.name + "\n" + def.role, def.pos + Vector3(0,2.35,0), 0.16)

func _make_devices():
	_add_device("Компьютер NightBell", Vector3(4,0.95,-3), Vector3(0.8,0.55,0.12), Color(0.05,0.25,0.42), "computer", "E — открыть компьютер")
	_add_device("Принтер", Vector3(8,0.65,-1.4), Vector3(1.0,0.45,0.65), Color(0.18,0.18,0.20), "printer", "E — печать документа")
	_add_device("CCTV монитор", Vector3(-12,1.05,6.9), Vector3(1.2,0.7,0.1), Color(0.03,0.38,0.25), "cctv", "E — смотреть CCTV")
	_add_device("Радио", Vector3(-9.4,0.85,1.1), Vector3(0.65,0.38,0.35), Color(0.12,0.10,0.07), "radio", "E — включить/переключить радио")
	_add_device("Архивная улика", Vector3(-7.5,0.8,-6.0), Vector3(0.55,0.08,0.38), Color(0.9,0.82,0.55), "archive", "E — взять улику из архива")

func _add_device(name, pos, size, color, kind, label):
	_add_box(name, pos, size, color, true)
	var area = Area3D.new()
	area.set_script(Interactable)
	area.setup(label, kind, name)
	area.position = pos
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size + Vector3(1.0,1.0,1.0)
	shape.shape = box
	area.add_child(shape)
	add_child(area)

func _make_lights():
	var sun = DirectionalLight3D.new()
	sun.light_energy = 0.35
	sun.rotation_degrees = Vector3(-65,20,0)
	add_child(sun)
	for pos in [Vector3(-8,2.5,3),Vector3(-2,2.5,3),Vector3(5,2.5,-4),Vector3(-8,2.5,-7),Vector3(10,2.5,-9),Vector3(-1,2.5,-9),Vector3(-12,2.5,7)]:
		var light = OmniLight3D.new()
		light.position = pos
		light.light_color = Color(0.65,0.75,0.95)
		light.light_energy = 1.1
		light.omni_range = 7.0
		add_child(light)

func _build_ui():
	var hud = CanvasLayer.new()
	add_child(hud)
	hud_objective = Label.new()
	hud_objective.position = Vector2(20,20)
	hud_objective.add_theme_font_size_override("font_size", 20)
	hud.add_child(hud_objective)
	hud_evidence = Label.new()
	hud_evidence.position = Vector2(20,50)
	hud_evidence.add_theme_font_size_override("font_size", 20)
	hud.add_child(hud_evidence)
	prompt_label = Label.new()
	prompt_label.anchor_left = 0.35
	prompt_label.anchor_top = 0.58
	prompt_label.anchor_right = 0.75
	prompt_label.anchor_bottom = 0.66
	prompt_label.add_theme_font_size_override("font_size", 22)
	hud.add_child(prompt_label)
	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.35
	pause_panel.anchor_top = 0.25
	pause_panel.anchor_right = 0.65
	pause_panel.anchor_bottom = 0.65
	pause_panel.visible = false
	hud.add_child(pause_panel)
	var col = VBoxContainer.new()
	pause_panel.add_child(col)
	var title = Label.new()
	title.text = "Пауза"
	title.add_theme_font_size_override("font_size", 34)
	col.add_child(title)
	var pause_buttons = [["Resume", "_resume"], ["Options: E/Enter/Esc/WASD", "_noop"], ["Quit to menu", "_quit_to_menu"]]
	for pair in pause_buttons:
		var button = Button.new()
		button.text = pair[0]
		button.pressed.connect(Callable(self, pair[1]))
		col.add_child(button)

func _process(delta):
	_update_interaction_prompt()

func _unhandled_input(event):
	if Input.is_action_just_pressed("pause"):
		if device_ui and device_ui.active:
			device_ui.close()
		else:
			_toggle_pause()
	if Input.is_action_just_pressed("dialogue_next") and dialogue and dialogue.active:
		dialogue.next()
	if Input.is_action_just_pressed("interact") and current_interactable and not dialogue.active and not device_ui.active and not get_tree().paused:
		_handle_interaction(current_interactable)

func _update_interaction_prompt():
	if not camera or (dialogue and dialogue.active) or (device_ui and device_ui.active):
		prompt_label.text = ""
		return
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + -camera.global_transform.basis.z * 3.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit = space.intersect_ray(query)
	current_interactable = null
	if hit.has("collider") and hit.collider is Interactable:
		current_interactable = hit.collider
		prompt_label.text = current_interactable.label
	else:
		prompt_label.text = ""

func _handle_interaction(area):
	if area.kind == "npc":
		_talk(area.payload)
	elif area.kind == "computer":
		_open_computer()
	elif area.kind == "printer":
		_use_printer()
	elif area.kind == "cctv":
		_open_cctv()
	elif area.kind == "radio":
		_use_radio()
	elif area.kind == "archive":
		_use_archive(area)

func _talk(npc_name):
	_lock_player()
	var def = _find_npc(npc_name)
	var lines = ["Сейчас не время для пустых разговоров. Следуйте текущей цели: " + quest.current_objective()]
	if npc_name == "Кадзуо Сато" and quest.step == 0:
		lines = ["Вы новый на ночной смене? Не отходите от маршрута.", "Сначала отметьтесь у Аи на ресепшене. Если услышите колокол — не отвечайте вслух."]
		quest.advance(0, 0)
	elif npc_name == "Ая Морита" and quest.step == 1:
		lines = ["Журнал посетителей пропал после 23:40.", "Проверьте open-space: последнее письмо пришло с компьютера без пользователя."]
		quest.advance(1, 0)
	elif (npc_name == "Кадзуо Сато" or npc_name == "Ая Морита") and quest.step == 8:
		lines = ["Документ, запись CCTV и архивная карточка совпадают.", "Звонок Night Bell шёл изнутри серверной. Смена закончена, но здание ещё нет."]
		quest.advance(8, 0)
	dialogue.start_dialogue(def.name, def.role, lines, _npc_portrait_path(def))

func _npc_portrait_path(def):
	var npc_texture_path = "res://assets/npc_png/" + def.file
	if ResourceLoader.exists(npc_texture_path):
		return npc_texture_path
	return ""

func _find_npc(npc_name):
	for def in npc_defs:
		if def.name == npc_name:
			return def
	return npc_defs[0]

func _open_computer():
	_lock_player()
	if quest.step == 2:
		quest.advance(2, 0)
	device_ui.open_device("Компьютер open-space", "Почта: NIGHT BELL / вложение: schedule_anomaly.txt\nФайлы: журнал пропусков, карта архива.", ["read_mail","close"])

func _device_action(action_name):
	if action_name == "read_mail":
		quest.advance(3, 1)
		device_ui.open_device("Письмо прочитано", "Тема: NIGHT BELL. 'Распечатай сменный приказ, включи радио и проверь камеру архива'.", ["close"])
	elif action_name == "print":
		quest.advance(5, 1)
		device_ui.open_device("Принтер", "Документ напечатан. На полях проступает время 00:13.", ["close"])
	elif action_name.begins_with("camera"):
		quest.advance(6, 1)
		var body = "Камера показывает пустой участок."
		if action_name == "camera_archive" and quest.step >= 6:
			body = "Камера архива: возле шкафа стоит тёмная фигура. Запись сохранена как улика."
		device_ui.open_device("CCTV / " + action_name, body, ["camera_reception","camera_open_space","camera_archive","camera_server","close"])

func _use_printer():
	_lock_player()
	if quest.step < 5:
		device_ui.open_device("Принтер", "Нет задания печати. Сначала прочитайте письмо и включите радио.", ["close"])
	else:
		device_ui.open_device("Принтер", "Готов к печати сменного приказа.", ["print","close"])

func _open_cctv():
	_lock_player()
	device_ui.open_device("CCTV комната", "Камеры: ресепшен, open-space, архив, серверная. После письма архивная камера ловит странную фигуру.", ["camera_reception","camera_open_space","camera_archive","camera_server","close"])

func _use_radio():
	_lock_player()
	var text = radio_logic.toggle(quest.step)
	if quest.step == 4:
		quest.advance(4, 0)
	dialogue.start_dialogue("Радио", "объект", [text], "")

func _use_archive(area):
	_lock_player()
	var lines = ["Архивный шкаф закрыт процедурой. Нужны письмо, печать и CCTV-запись."]
	if quest.step == 7:
		quest.advance(7, 1)
		lines = ["Вы взяли карточку пропуска 00:13.", "На обороте написано: 'Вернись к стойке, пока звонок не повторился'."]
	dialogue.start_dialogue("Архивная улика", "документ", lines, "")

func _lock_player():
	player.locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unlock_player():
	if player and not get_tree().paused:
		player.locked = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _toggle_pause():
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused
	player.locked = get_tree().paused
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _resume():
	get_tree().paused = false
	pause_panel.visible = false
	_unlock_player()

func _noop():
	pass

func _quit_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _add_desk(pos):
	_add_box("Стол", pos + Vector3(0,0.45,0), Vector3(1.5,0.12,0.75), Color(0.23,0.17,0.10), true)
	_add_box("Монитор", pos + Vector3(0,0.95,-0.25), Vector3(0.65,0.42,0.06), Color(0.02,0.08,0.12), true)
	_add_box("Клавиатура", pos + Vector3(0,0.55,0.22), Vector3(0.7,0.04,0.18), Color(0.02,0.02,0.025), true)
	_add_chair(pos + Vector3(0,0,0.85))

func _add_chair(pos):
	_add_box("Стул сиденье", pos + Vector3(0,0.35,0), Vector3(0.55,0.12,0.55), Color(0.08,0.08,0.09), true)
	_add_box("Стул спинка", pos + Vector3(0,0.75,0.25), Vector3(0.55,0.7,0.1), Color(0.07,0.07,0.08), true)

func _add_shelf(pos):
	_add_box("Шкаф архивный", pos + Vector3(0,1,0), Vector3(0.85,2.0,0.45), Color(0.18,0.16,0.12), true)

func _add_counter(pos, name):
	_add_box(name, pos + Vector3(0,0.55,0), Vector3(2.5,1.1,0.8), Color(0.20,0.18,0.14), true)
	_add_box(name + " столешница", pos + Vector3(0,1.14,0), Vector3(2.7,0.12,0.9), Color(0.28,0.25,0.18), true)

func _add_box(name, pos, size, color, collision):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = name
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
	mesh_instance.position = pos
	add_child(mesh_instance)
	if collision:
		var body = StaticBody3D.new()
		body.name = name + " collision"
		body.position = pos
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		add_child(body)
	furniture_count += 1
	return mesh_instance

func _add_label_3d(text, pos, size):
	var label = Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = size / 64.0
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.9,0.88,0.72)
	add_child(label)

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
