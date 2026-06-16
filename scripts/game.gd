extends Node3D

const SAVE_PATH := "user://nightbell_save.json"
const INTERACT_DISTANCE := 3.2

var mouse_sensitivity := 0.0025
var evidence := {}
var objective := "Register with Kazuo Sato at security."
var quest_step := 0
var ui_mode := "menu"
var current_floor := 1
var interactables: Array[Node3D] = []
var current_target: Node3D
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var player: CharacterBody3D
var camera: Camera3D
var yaw := 0.0
var pitch := 0.0
var hud: CanvasLayer
var objective_label: Label
var evidence_label: Label
var prompt_label: Label
var panel: Panel
var speaker_label: Label
var body_label: Label
var portrait: ColorRect
var overlay: Panel
var rng := RandomNumberGenerator.new()

var npcs := [
	["Kazuo Sato", "Security Guard", Vector3(-5, 0, -4), Color(0.22, 0.34, 0.42), ["New night staff? Sign here. The bell after midnight is only the elevator settling.", "Take the temporary pass from Aya. Do not force the emergency exit."]],
	["Aya Morita", "Reception", Vector3(-1.8, 0, -5.2), Color(0.55, 0.31, 0.38), ["Your pass is active for floor one. Smile for the camera; it likes new faces.", "Open-space computer, radio check, print the shift form. Then I can unlock floor two."]],
	["Mika Hayashi", "HR Manager", Vector3(11, 3.4, -3), Color(0.46, 0.38, 0.56), ["Policy says archived incidents are not incidents once reclassified.", "Collect only approved forms. Unapproved memories create liability."]],
	["Ren Takahashi", "IT Technician", Vector3(15, 3.4, 4), Color(0.25, 0.48, 0.56), ["Camera four loops, but the timestamps keep breathing.", "If you find my tablet log, copy it before the chief arrives."]],
	["Mrs. Noguchi", "Cleaner", Vector3(2, 0, 6), Color(0.38, 0.52, 0.35), ["Wet floor, dry throat, closed mouths. The old archive remembers shoes.", "When lights go red, trust paper more than people."]],
	["Shinji Oda", "Archivist", Vector3(8, 6.8, -4), Color(0.42, 0.36, 0.28), ["The 2009 folder was never destroyed. It was promoted upstairs.", "Seven pieces make a report heavy enough to open the final door."]],
	["Takeo Inoue", "Accountant", Vector3(11, 3.4, 5.5), Color(0.50, 0.45, 0.31), ["Numbers sleep in pairs. Missing overtime, missing person, balanced column."]],
	["Yuta Senda", "Intern", Vector3(4, 0, 1), Color(0.28, 0.36, 0.58), ["I heard the radio say my name yesterday. I was not hired yesterday."]],
	["Night Administrator", "Attached PNG Staff", Vector3(-4, 0, 3), Color(0.60, 0.42, 0.52), ["I know where the old card is, but I forgot why I hid it."]],
	["Haruto Kume", "HR Man With Folder", Vector3(13, 3.4, -6), Color(0.35, 0.35, 0.42), ["Rule 6: Do not discuss Rule 5 with employees who still cast shadows."]],
	["Nao Fujii", "IT Staff With Tablet", Vector3(15, 3.4, 1), Color(0.30, 0.55, 0.62), ["Do not rewind camera six unless you want it to notice you."]],
	["Emi Kurata", "Archive Clerk", Vector3(9, 6.8, 2), Color(0.52, 0.42, 0.34), ["Folders are safer than mouths. Take the one stamped NIGHT BELL."]],
	["Daichi Mori", "Tired Office Worker", Vector3(1, 0, 4), Color(0.48, 0.43, 0.36), ["Coffee cold. Bell warm. Shift repeats. Coffee cold."]]
]

func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_player()
	_build_ui()
	_show_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and ui_mode == "game":
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.35, 1.35)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event.is_action_pressed("interact") and ui_mode == "game":
		_use_target()
	if event.is_action_pressed("next_line") and ui_mode == "dialogue":
		_advance_dialogue()
	if event.is_action_pressed("ui_cancel"):
		if ui_mode == "game": _show_pause()
		elif ui_mode in ["pause", "computer", "cctv", "document", "report", "options"]: _resume_game()

func _physics_process(delta: float) -> void:
	if ui_mode != "game": return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis := player.global_transform.basis
	var dir := (basis.x * input_dir.x + basis.z * input_dir.y).normalized()
	var speed := 5.0 if Input.is_action_pressed("sprint") else 3.0
	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed
	player.velocity.y -= 18.0 * delta
	player.move_and_slide()
	_update_prompt()

func _build_world() -> void:
	var env := WorldEnvironment.new(); add_child(env)
	var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.015,0.018,0.022); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.08,0.1,0.13); env.environment = e
	var sun := DirectionalLight3D.new(); sun.light_energy = 0.15; add_child(sun)
	for f in range(3):
		_create_floor(f + 1, f * 3.4)
	for data in npcs: _create_npc(data)
	_create_interactable("Work Computer", "computer", Vector3(4,0, -2), "E — use: Work Computer")
	_create_interactable("Radio", "radio", Vector3(2.7,0,-1.7), "E — tune: Office Radio")
	_create_interactable("Printer/Copier", "printer", Vector3(6,0,-2.4), "E — print: Shift Form")
	_create_interactable("CCTV Console", "cctv", Vector3(-6,0,-1), "E — inspect: CCTV Console")
	_create_interactable("Elevator", "elevator", Vector3(-8,0,5), "E — ride: Elevator")
	_create_interactable("Emergency Exit", "exit", Vector3(18,0,6), "E — open: Emergency Exit")
	_create_interactable("Old Archive Folder", "evidence_archive", Vector3(8,6.8,-2), "E — collect: Archive Folder")
	_create_interactable("IT Terminal", "it_computer", Vector3(14,3.4,3), "E — use: IT Computer")
	_create_interactable("Final Report Desk", "report", Vector3(17,6.8,4), "E — assemble: Final Report")

func _create_floor(floor_num:int, y:float) -> void:
	_add_box("Floor %d slab" % floor_num, Vector3(0,y-0.05,0), Vector3(42,0.1,20), Color(0.12,0.13,0.14), true)
	_add_box("Floor %d ceiling" % floor_num, Vector3(0,y+2.8,0), Vector3(42,0.08,20), Color(0.05,0.055,0.06), false)
	for x in [-20,20]: _add_box("Wall", Vector3(x,y+1.4,0), Vector3(0.25,2.8,20), Color(0.18,0.19,0.20), true)
	for z in [-10,10]: _add_box("Wall", Vector3(0,y+1.4,z), Vector3(42,2.8,0.25), Color(0.16,0.17,0.18), true)
	for x in [-13,-6,2,9,16]: _add_box("Glass/partition", Vector3(x,y+1.15,0), Vector3(0.08,2.3,13), Color(0.20,0.28,0.32,0.55), true)
	for i in range(12):
		var px := -16 + (i % 6) * 6.0; var pz := -6 + int(i / 6) * 8.0
		_create_desk_cluster(Vector3(px,y,pz))
	for i in range(10):
		_add_box("Ceiling Lamp", Vector3(-17 + i*4,y+2.65, -7), Vector3(2,0.05,0.28), Color(0.65,0.85,0.95), false)
		var l := OmniLight3D.new(); l.position = Vector3(-17+i*4,y+2.45,-7); l.light_color = Color(0.58,0.76,0.9); l.light_energy = 0.55; l.omni_range = 6; add_child(l)
	_add_room_labels(floor_num, y)

func _create_desk_cluster(pos:Vector3) -> void:
	_add_box("Office Desk", pos + Vector3(0,0.45,0), Vector3(2.2,0.12,1.1), Color(0.28,0.22,0.16), true)
	_add_box("Monitor", pos + Vector3(0,0.95,-0.35), Vector3(0.8,0.45,0.06), Color(0.02,0.05,0.07), true)
	_add_box("Keyboard", pos + Vector3(0,0.56,0.15), Vector3(0.75,0.04,0.22), Color(0.04,0.04,0.045), true)
	_add_box("Chair", pos + Vector3(0,0.45,0.95), Vector3(0.65,0.8,0.55), Color(0.08,0.09,0.10), true)
	_add_box("Papers", pos + Vector3(0.55,0.54,0.05), Vector3(0.45,0.02,0.32), Color(0.82,0.80,0.70), false)

func _add_room_labels(f:int, y:float) -> void:
	var names := ["Reception / Security", "Open Space", "Archive", "Server", "Kitchen", "CCTV", "HR", "Accounting", "IT", "Legal", "Old Files", "Final Room"]
	for i in range(4):
		_add_box(names[(f-1)*4+i], Vector3(-15+i*10,y+1.7,-9.8), Vector3(3.8,0.35,0.04), Color(0.7,0.68,0.55), false)

func _add_box(n:String, pos:Vector3, size:Vector3, color:Color, collision:bool) -> Node3D:
	var body: Node3D = StaticBody3D.new() if collision else Node3D.new(); body.name = n; body.position = pos; add_child(body)
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.emission_enabled = color.r > 0.6; mat.emission = color; mat.emission_energy_multiplier = 0.35; mesh.material_override = mat; body.add_child(mesh)
	if collision:
		var col := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; col.shape = shape; body.add_child(col)
	return body

func _create_npc(data:Array) -> void:
	var npc := _add_box(data[0], data[2] + Vector3(0,0.9,0), Vector3(0.85,1.8,0.08), data[3], true)
	npc.set_meta("type", "npc"); npc.set_meta("display", "E — talk: %s, %s" % [data[0], data[1]]); npc.set_meta("lines", data[4]); npc.set_meta("role", data[1]); interactables.append(npc)
	_add_box("Shadow " + data[0], data[2] + Vector3(0,0.02,0.08), Vector3(0.9,0.02,0.35), Color(0,0,0,0.7), false)

func _create_interactable(n:String, t:String, pos:Vector3, display:String) -> void:
	var node := _add_box(n, pos + Vector3(0,0.55,0), Vector3(1.0,1.1,0.8), Color(0.24,0.30,0.32), true)
	node.set_meta("type", t); node.set_meta("display", display); interactables.append(node)

func _build_player() -> void:
	player = CharacterBody3D.new(); player.name = "Player"; player.position = Vector3(-7,0.2,-7); add_child(player)
	var col := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.height = 1.7; capsule.radius = 0.32; col.shape = capsule; player.add_child(col)
	camera = Camera3D.new(); camera.position = Vector3(0,1.55,0); player.add_child(camera)

func _build_ui() -> void:
	hud = CanvasLayer.new(); add_child(hud)
	objective_label = Label.new(); objective_label.position = Vector2(24,18); hud.add_child(objective_label)
	evidence_label = Label.new(); evidence_label.position = Vector2(24,44); hud.add_child(evidence_label)
	prompt_label = Label.new(); prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; prompt_label.position = Vector2(360,430); prompt_label.size = Vector2(560,40); hud.add_child(prompt_label)
	panel = Panel.new(); panel.visible = false; panel.position = Vector2(80,500); panel.size = Vector2(1120,190); hud.add_child(panel)
	portrait = ColorRect.new(); portrait.position = Vector2(20,20); portrait.size = Vector2(110,140); panel.add_child(portrait)
	speaker_label = Label.new(); speaker_label.position = Vector2(150,18); panel.add_child(speaker_label)
	body_label = Label.new(); body_label.position = Vector2(150,55); body_label.size = Vector2(920,110); body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; panel.add_child(body_label)
	overlay = Panel.new(); overlay.visible = false; overlay.position = Vector2(220,100); overlay.size = Vector2(840,520); hud.add_child(overlay)

func _show_menu() -> void:
	ui_mode = "menu"; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; overlay.visible = true; overlay.get_children().map(func(c): c.queue_free())
	_add_overlay_title("NIGHT BELL: OFFICE SHIFT\nナイトベル・オフィスシフト")
	_add_button("New Game", _new_game, 120); _add_button("Continue", _continue_game, 180); _add_button("Options", _show_options, 240); _add_button("Exit", func(): get_tree().quit(), 300)

func _add_overlay_title(text:String) -> void:
	var l := Label.new(); l.text = text; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.position = Vector2(40,35); l.size = Vector2(760,80); overlay.add_child(l)

func _add_button(text:String, call:Callable, y:int) -> void:
	var b := Button.new(); b.text = text; b.position = Vector2(300,y); b.size = Vector2(240,44); b.pressed.connect(call); overlay.add_child(b)

func _new_game() -> void:
	evidence.clear(); quest_step = 0; objective = "Register with Kazuo Sato at security."; _save(); _resume_game()
func _continue_game() -> void:
	_load(); _resume_game()
func _resume_game() -> void:
	ui_mode = "game"; overlay.visible = false; panel.visible = false; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED; _refresh_hud()
func _show_pause() -> void:
	ui_mode = "pause"; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; overlay.visible = true; overlay.get_children().map(func(c): c.queue_free()); _add_overlay_title("PAUSED"); _add_button("Resume", _resume_game, 160); _add_button("Save", _save, 220); _add_button("Main Menu", _show_menu, 280)
func _show_options() -> void:
	ui_mode = "options"; overlay.get_children().map(func(c): c.queue_free()); _add_overlay_title("Options\nVolume handled by generated office ambience. Mouse sensitivity saved."); _add_button("Fullscreen / Windowed", func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED), 180); _add_button("Back", _show_menu, 250)

func _update_prompt() -> void:
	current_target = null; var best := INTERACT_DISTANCE
	for i in interactables:
		var d := camera.global_position.distance_to(i.global_position)
		var forward := -camera.global_transform.basis.z
		if d < best and forward.dot((i.global_position - camera.global_position).normalized()) > 0.65:
			best = d; current_target = i
	prompt_label.text = current_target.get_meta("display", "") if current_target else ""
	_refresh_hud()

func _use_target() -> void:
	if current_target == null: return
	var t:String = current_target.get_meta("type")
	match t:
		"npc": _start_dialogue(current_target.name, current_target.get_meta("role"), current_target.get_meta("lines"))
		"computer": _screen("WORK COMPUTER", "Mail: Welcome to night shift. Task: switch on radio and print Form N-13. Attachment mentions a 2009 elevator bell incident."); _progress(1, "Turn on the radio, then print the shift form.")
		"radio": _screen("RADIO", "Track 01: fluorescent hum. Track 02: weather in Japanese. Static phrase: 'Do not let HR file you.'"); _progress(2, "Print the shift form at the copier.")
		"printer": evidence["printed_form"] = true; _screen("PRINTER", "Form N-13 printed. A second page appears: CCTV timestamp 00:13, archive corridor."); _progress(3, "Review CCTV in the security room.")
		"cctv": evidence["cctv_recording"] = true; _screen("CCTV", "Cameras: Reception, Open-space, 2F Corridor, Archive, Server, Emergency Exit. Camera Archive shows a standee-like employee staring back. Recording saved as evidence."); _progress(4, "Use the elevator to reach floor 2 and question HR/IT.")
		"elevator": _ride_elevator()
		"evidence_archive": evidence["archive_folder"] = true; _screen("OLD ARCHIVE", "Folder 2009-NB: employee disappeared during an unscheduled night shift. Bell heard from disconnected elevator.")
		"it_computer": evidence["it_file"] = true; _screen("IT TERMINAL", "Recovered file: access logs were edited by Shift Chief account. Server room contains hidden export.")
		"exit": _ending()
		"report": _report()

func _start_dialogue(n:String, role:String, lines:Array) -> void:
	ui_mode = "dialogue"; panel.visible = true; dialogue_lines = lines; dialogue_index = 0; speaker_label.text = "%s — %s" % [n, role]; portrait.color = Color(randf(), randf(), randf(), 1); body_label.text = dialogue_lines[0]
func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size(): _resume_game()
	else: body_label.text = dialogue_lines[dialogue_index]

func _screen(title:String, text:String) -> void:
	ui_mode = "computer"; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; overlay.visible = true; overlay.get_children().map(func(c): c.queue_free()); _add_overlay_title(title); var l:=Label.new(); l.text=text + "\n\nEsc — close"; l.position=Vector2(55,140); l.size=Vector2(730,260); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; overlay.add_child(l)
func _progress(step:int, obj:String) -> void:
	if quest_step < step: quest_step = step; objective = obj; _save()
func _ride_elevator() -> void:
	current_floor = current_floor % 3 + 1; player.position = Vector3(-8, (current_floor-1)*3.4 + 0.2, 5); _progress(4, "Collect archive, HR, IT and hidden evidence; assemble final report on floor 3.")
func _report() -> void:
	evidence["final_report"] = true; _screen("FINAL REPORT", "Evidence attached: %d/7. Trust paper, CCTV, and IT logs. Emergency exit authorization generated." % evidence.size()); objective = "Leave through the emergency exit or keep searching for all seven clues."; _save()
func _ending() -> void:
	var ending := "BAD END: You leave with gaps. The office files you as night staff."
	if evidence.size() >= 4: ending = "NEUTRAL END: You escape with partial proof. The company opens Monday."
	if evidence.has("final_report") and evidence.size() >= 5: ending = "SECRET GOOD END: Your complete report exposes the Night Bell cover-up. Dawn reaches the office."
	_screen("ENDING", ending)
func _refresh_hud() -> void:
	objective_label.text = "Objective: " + objective; evidence_label.text = "Evidence: %d / 7" % evidence.size()
func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"quest_step":quest_step,"objective":objective,"evidence":evidence,"floor":current_floor}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) == TYPE_DICTIONARY:
		quest_step = int(data.get("quest_step",0))
		objective = str(data.get("objective",objective))
		evidence = data.get("evidence",{})
		current_floor = int(data.get("floor",1))
