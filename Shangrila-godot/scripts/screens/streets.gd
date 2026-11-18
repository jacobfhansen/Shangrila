extends Control
## The streets of Lehan, walked in first person like the mines (see LehanStreets and MarketData).
## Keys: W/Up forward, S/Down back, A/Left and D/Right turn, Q/E step sideways,
## Space/Enter talk to (or use) what is straight ahead, M the town plan, Esc closes it, C the
## party's character screen.
## Walking into a person talks to them; walking into a door goes through it. The plan shows the
## places found so far; clicking one walks the party straight to its entrance.
## Args: {"at": place key, "into": bool}: start at that entrance (default: the south gate),
## facing the door if `into`, otherwise with the back to it (just came out). Or {"at_cell":
## [x, y], "facing": dir} to stand at a cell.

const TOWN := "lehan"

var area := LehanStreets.new()
var view: DungeonView
var compass: Compass
var hint: Label
var plan: _Plan
var map_btn: Button
var talking := false
var buttons: Array = []
var scene_box: DialogueBox      # the arrival scene's conversation, while it runs
var scene_back: Control         # the panel behind it
var gone_at_start: Array = []   # recruits already gone from the square when the view was built


func _ready() -> void:
	var args: Dictionary = get_meta("args", {})
	area.place_at(args.get("at", "gate"), args.get("into", false))
	if args.has("at_cell"):   # back exactly where the party stood (after the square changed)
		area.pos = Vector2i(args.at_cell[0], args.at_cell[1])
		area.facing = args.get("facing", 0)
	for k in MarketData.PEOPLE:
		if LehanQuests.gone_from_square(MarketData.PEOPLE[k].key):
			gone_at_start.append(MarketData.PEOPLE[k].key)
	Ui.stone_background(self)
	view = DungeonView.new()
	view.area = area
	add_child(view)
	view.moved.connect(_after_move)
	Ui.frame(self, Rect2(14, 14, 412, 412), Color.BLACK, Color("#a07a40"), 4)
	var vr := TextureRect.new()
	vr.texture = view.get_texture()
	vr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vr.stretch_mode = TextureRect.STRETCH_SCALE
	vr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vr)
	Ui.place(vr, Rect2(20, 20, 400, 400))
	plan = _Plan.new()
	plan.area = area
	plan.visible = false
	plan.picked.connect(_travel)
	add_child(plan)
	Ui.place(plan, Rect2(20, 20, 400, 400))

	Ui.title(self, Game.city.name, Vector2(438, 18), 24, 190, HORIZONTAL_ALIGNMENT_CENTER)
	compass = Compass.new()
	compass.area = area
	add_child(compass)
	Ui.place(compass, Rect2(482, 58, 101, 101))
	var mv := [["↶", 0, 0, _turn.bind(-1), "Turn left (A / Left)"],
		["↑", 1, 0, _walk.bind(0), "Forward (W / Up)"],
		["↷", 2, 0, _turn.bind(1), "Turn right (D / Right)"],
		["←", 0, 1, _walk.bind(3), "Step left (Q)"],
		["↓", 1, 1, _walk.bind(2), "Back (S / Down)"],
		["→", 2, 1, _walk.bind(1), "Step right (E)"]]
	for m in mv:
		var b := Ui.btn(self, m[0], Rect2(476 + m[1] * 39, 168 + m[2] * 38, 35, 34), m[3], m[4])
		b.add_theme_font_size_override("font_size", 18)
		buttons.append(b)
	buttons.append(Ui.btn(self, "Talk / Enter", Rect2(446, 252, 180, 32), _use_ahead,
		"Talk to whoever is straight ahead, or go through the door (Space)"))
	map_btn = Ui.btn(self, "Map", Rect2(446, 290, 58, 30), _on_map, "The town plan: click a place to go to its entrance (M)")
	map_btn.toggle_mode = true
	buttons.append(Ui.btn(self, "Party", Rect2(507, 290, 58, 30), _on_party, "Your characters: abilities, gear and silver (C)"))
	buttons.append(Ui.btn(self, "Quests", Rect2(568, 290, 58, 30), _on_quests, "The quest log: every quest and what was said (J)"))
	buttons.append(Ui.btn(self, "Save", Rect2(446, 326, 88, 30), _on_save, "Save the game"))
	buttons.append(Ui.btn(self, "Quit", Rect2(538, 326, 88, 30), _on_quit, "Back to the main menu"))
	Ui.frame(self, Rect2(436, 364, 196, 62))
	var help := Ui.label(self, "Walk up to people to talk, and into doors to go in. Map shows the town.",
		Vector2(444, 368), 11, Ui.DIM, 182)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size = Vector2(182, 54)
	Ui.frame(self, Rect2(14, 432, 618, 38))
	hint = Ui.label(self, "", Vector2(24, 442), 13, Ui.TEXT, 600)
	_after_move()
	if _arrival_pending():
		_arrival.call_deferred()


func _process(_delta: float) -> void:
	if scene_box and is_instance_valid(scene_box):
		scene_back.size.y = scene_box.content_height() + 16


func _place_name(key: String) -> String:
	return Game.TOWNS[TOWN].places[key].name


func _after_move() -> void:
	compass.queue_redraw()
	plan.queue_redraw()
	if scene_box and is_instance_valid(scene_box):
		hint.text = _where()   # the arrival scene walks on its own
		return
	if not talking and LisbetQuest.tail_due(area.pos):
		_dialog.call_deferred("On the gate road", LisbetQuest.tail_scene(), "lisbet")
	var t := area.thing_at(area.ahead())
	match t.get("kind", ""):
		"person":
			hint.text = "Ahead: %s.  Walk on or press Space to talk." % MarketData.PEOPLE[t.id].name
		"exit":
			if t.to == "gate":
				hint.text = "Ahead: the South Gate.  Walk on or press Space to leave town."
			else:
				var nm := _place_name(t.to)
				if t.to == "smith" and not "smith" in Game.town_places(TOWN):
					nm = "a shop with a sword on its sign"
				if t.to == "warehouse" and not "warehouse" in Game.town_places(TOWN):
					nm = "a warehouse with wide loading doors and a barrel on its sign"
				if t.to == "tannery" and not "tannery" in Game.town_places(TOWN):
					nm = "a tannery, stinking of lime, with hides hung out to dry"
				if t.to == "council" and not "council" in Game.town_places(TOWN):
					nm = "a stone hall with the town's banner over the door"
				hint.text = "Ahead: %s.  Walk on or press Space to go in." % nm
		"prop":
			hint.text = {"well": "The town well. The council's notices are pinned to its post.",
				"stall": "A market stall: fruit, cloth and pots.", "cart": "A farmer's cart, half unloaded.",
				"barrels": "Barrels of salt fish. You can smell them from here."}.get(t.what, "")
		_:
			hint.text = _where()


## A line about the street the party is in.
func _where() -> String:
	var p := area.pos
	if p == LehanStreets.ENTRANCES.hideout.cell:
		return "Tanners' Row, at the door of a narrow, plain house."
	if p == LehanStreets.ENTRANCES.tannery.cell:
		return "Tanners' Row, at the gate of a tannery. The stink makes your eyes water."
	if p == LehanStreets.ENTRANCES.warehouse.cell:
		return "The corner where the smith's street meets the square, by a warehouse's loading doors."
	if p == LehanStreets.ENTRANCES.council.cell:
		return "The north side of the square, below the council house's banner."
	if p == LehanStreets.ENTRANCES.inn.cell:
		return "The lane's end, at the door of the inn."
	if p.x >= 8 and p.x <= 15 and p.y >= 3 and p.y <= 10:
		return "The market square: stalls, a well, and people going about their business."
	if p.y == 15 and p.x < 11:
		return "Tanners' Row. The smell of the tanneries hangs in the air."
	if p.x == 11 and p.y > 10:
		return "The gate road, between the square and the South Gate."
	if p.y == 6 and p.x > 15:
		return "A lane off the square, towards the inn."
	return "A narrow street between tall, leaning houses."


func _walk(dir_rel: int) -> void:
	if _locked():
		return
	var dir: int = posmod(area.facing + dir_rel, 4)
	var target: Vector2i = area.pos + Game.DIR_VEC[dir]
	if not view.step(dir) and dir_rel == 0:
		_use(area.thing_at(target))


func _turn(d: int) -> void:
	if _locked():
		return
	view.turn(d)


func _locked() -> bool:
	return talking or Game.main.modal_open or plan.visible


func _use_ahead() -> void:
	if _locked() or view.busy:
		return
	_use(area.thing_at(area.ahead()))


func _use(t: Dictionary) -> void:
	match t.get("kind", ""):
		"person":
			await _talk(t.id)
		"exit":
			match t.to:
				"smith":
					if Game.discover_place(TOWN, "smith"):
						await Game.main.message("The Weapon Smith is now on the town map.")
					Game.main.goto("shop")
				"inn":
					Game.main.goto("inn")
				"tannery":
					Game.discover_place(TOWN, "tannery")
					await _dialog("The Tannery", SkeeQuest.tannery(), "skee")
					if SkeeQuest.way_open() and LehanQuests.get_q("skee") != "":
						Game.main.goto("tunnels")
				"warehouse":
					Game.discover_place(TOWN, "warehouse")
					await _dialog("Gell's Warehouse", BoddoQuest.warehouse(), "boddo")
				"council":
					if not LehanData.has_job():
						await Game.main.message("A clerk blocks the door of the stone hall.\n\n\"The council sits on council business. Have you any?\"\n\nNot yet, it seems.")
						return
					Game.discover_place(TOWN, "council")
					Game.main.goto("council")
				"hideout":
					await Game.main.message(LehanData.knock_text())
				"gate":
					if Game.story.has("employer"):
						Game.story["left_lehan"] = true
					Game.main.goto("world")


# ---------------------------------------------------------------- the town plan

func _on_map() -> void:
	if talking or Game.main.modal_open:
		map_btn.button_pressed = plan.visible
		return
	plan.visible = map_btn.button_pressed
	plan.queue_redraw()
	hint.text = "Click a place to go to its entrance. Esc or Map closes the plan." if plan.visible else _where()


func _travel(place: String) -> void:
	area.place_at(place, true)
	view.snap()
	map_btn.button_pressed = false
	plan.visible = false
	_after_move()


# ---------------------------------------------------------------- arriving in Lehan

## The first visit after the road: the company walks to the employer's house, meets him, and
## walks on to the inn, where it splits up (the text is in LehanData).
func _arrival_pending() -> bool:
	return Game.story.get("road_done", false) and Game.story.has("host") and not Game.story.has("employer")


func _arrival() -> void:
	_lock(true)
	var host: String = Game.story.host
	Game.discover_place(TOWN, "hideout")
	area.place_at("gate", false)
	view.snap()
	# The conversation sits at the top, over the sky, with a solid panel behind it that grows
	# only while there are replies to choose from, leaving the street below in view.
	scene_back = Ui.frame(self, Rect2(12, 12, 620, 122), Color("#1a120a"), Color("#a07a40"), 2)
	var box := DialogueBox.new()
	box.cast = PrologueData.company_cast()
	box.cast["employer"] = LehanData.EMPLOYER
	box.host = host
	Ui.place(box, Rect2(20, 20, 600, 270))   # sized before _ready builds it
	add_child(box)
	scene_box = box
	box.effect.connect(_on_scene_fx)
	hint.text = "The company makes its way to the employer's house."
	var walk := {"done": false}
	_auto_walk(LehanStreets.PATH_TO_HOUSE, 1.4, 3, walk)
	box.play(LehanData.walk(host))
	await box.finished
	while not walk.done:
		await get_tree().process_frame
	box.play(LehanData.meeting(host))
	await box.finished
	LehanData.settle(host)
	Game.story["employer"] = "met"
	hint.text = "Off to the inn."
	walk.done = false
	_auto_walk(LehanStreets.PATH_TO_INN, 0.7, 1, walk)
	box.play(LehanData.parting(host))
	await box.finished
	while not walk.done:
		await get_tree().process_frame
	box.show_buttons([["Go into the inn", func(): Game.main.goto("inn", {"split": true})]])


func _on_scene_fx(name: String) -> void:
	if name.contains("="):
		LehanData.record(name)
	elif name == "split":
		var host_name: String = PrologueData.CAST[Game.story.host].name
		for c in Game.party.duplicate():
			if c.name != host_name:
				Game.hand_over_quest_items(c)
				Game.party.erase(c)
				Game.roster.append(c)


## Walks the view through the waypoints (turning at each corner), `pause` seconds between steps,
## and finally turns to face `end_dir`. Sets state.done when finished.
func _auto_walk(points: Array, pause: float, end_dir: int, state: Dictionary) -> void:
	for wp: Vector2i in points:
		while area.pos != wp and is_inside_tree():
			var d := wp - area.pos
			var dir := 0
			if d.x > 0: dir = 1
			elif d.x < 0: dir = 3
			elif d.y > 0: dir = 2
			await _face(dir)
			view.step(dir)
			await view.moved
			if not is_inside_tree():
				return
			await get_tree().create_timer(pause).timeout
	await _face(end_dir)
	state.done = true


func _face(dir: int) -> void:
	while area.facing != dir and is_inside_tree():
		view.turn(1 if posmod(dir - area.facing, 4) <= 2 else -1)
		await view.moved


func _lock(on: bool) -> void:
	talking = on
	for b in buttons:
		b.disabled = on
	map_btn.disabled = on


# ---------------------------------------------------------------- talking

func _talk(id: String) -> void:
	var quest := Journal.quest_of_person(MarketData.PEOPLE[id].key)   # before the talk changes it
	await _dialog("Talking to " + MarketData.PEOPLE[id].name, MarketData.talk(id, Game.story.get("host", "")), quest)


## A conversation or a scene in the street, in a window over the lower part of the view.
## `quest`: the quest it belongs to, kept in the quest log (see Journal).
func _dialog(title: String, lines: Array, quest := "") -> void:
	if lines.is_empty():
		return
	_lock(true)
	var host: String = Game.story.get("host", "")
	if host == "":
		# No host (an old save): leave out what the host would say and think.
		lines = lines.filter(func(st): return not (st.has("s") and st.s == "") and not st.has("i"))
	var ov := Control.new()
	add_child(ov)
	Ui.place(ov, Rect2(0, 0, 640, 480))
	Ui.frame(ov, Rect2(10, 150, 620, 322), Color("#1a120a"), Color("#a07a40"), 2)
	Ui.label(ov, title, Vector2(22, 156), 15, Ui.GOLD)
	var box := DialogueBox.new()
	box.cast = MarketData.cast()
	box.host = host
	box.journal = quest
	box.journal_place = title
	Ui.place(box, Rect2(20, 180, 600, 286))   # sized before _ready builds it
	ov.add_child(box)
	box.effect.connect(_on_effect)
	box.play(lines)
	await box.finished
	box.show_buttons([["Goodbye", func(): box.finished.emit()]])
	await box.finished
	ov.queue_free()
	_lock(false)
	_after_move()
	if LehanQuests.any_done() and _square_needs_rebuild():
		Game.main.goto("streets", {"at_cell": [area.pos.x, area.pos.y], "facing": area.facing})


## Someone left the square for the inn during the talk, and the 3D view still shows them.
func _square_needs_rebuild() -> bool:
	for k in MarketData.PEOPLE:
		var key: String = MarketData.PEOPLE[k].key
		if LehanQuests.gone_from_square(key) and not key in gone_at_start:
			return true
	return false


func _on_effect(fx: String) -> void:
	LehanQuests.apply(fx)
	if fx == "notice":
		Game.story["job_notice"] = true
		Game.discover_place(TOWN, "council")
		Game.discover_place(TOWN, "smith")


func _on_party() -> void:
	if _locked() or Game.party.is_empty():
		return
	Game.main.goto("view", {"party": true, "index": 0, "back": "streets",
		"back_args": {"at_cell": [area.pos.x, area.pos.y], "facing": area.facing}})


func _on_save() -> void:
	if Game.save_game("streets"):
		await Game.main.message("The game has been saved.")
	else:
		await Game.main.message("Could not save the game.")


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


func _unhandled_input(e: InputEvent) -> void:
	if talking or Game.main.modal_open or not (e is InputEventKey and e.pressed and not e.echo):
		return
	if plan.visible:
		if e.keycode in [KEY_ESCAPE, KEY_M]:
			map_btn.button_pressed = false
			_on_map()
			get_viewport().set_input_as_handled()
		return
	match e.keycode:
		KEY_W, KEY_UP: _walk(0)
		KEY_S, KEY_DOWN: _walk(2)
		KEY_A, KEY_LEFT: _turn(-1)
		KEY_D, KEY_RIGHT: _turn(1)
		KEY_Q: _walk(3)
		KEY_E: _walk(1)
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER: _use_ahead()
		KEY_M:
			map_btn.button_pressed = true
			_on_map()
		KEY_C: _on_party()
		KEY_J: _on_quests()
		_: return
	get_viewport().set_input_as_handled()


func _on_quests() -> void:
	if not _locked():
		QuestLog.open()


## The town plan drawn from the street map: streets, the square, the places found so far
## (clickable) and the party.
class _Plan:
	extends Control
	signal picked(place: String)
	var area: LehanStreets
	var spots := {}   # place -> Vector2 (centre of its marker)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _cell_rect(c: Vector2i, cs: float, o: Vector2) -> Rect2:
		return Rect2(o + Vector2(c) * cs, Vector2(cs, cs))

	func _draw() -> void:
		draw_texture_rect(Ui.tex("parchment"), Rect2(Vector2.ZERO, size), false)
		var n := area.size()
		var cs := floorf(minf((size.x - 20) / n.x, (size.y - 60) / n.y))
		var o := Vector2((size.x - cs * n.x) / 2.0, 40)
		var ink := Color("#3a2410")
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 28), "Lehan", HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, ink)
		# Houses as blocks along the streets, streets as pale paper.
		for y in n.y:
			for x in n.x:
				var c := Vector2i(x, y)
				var r := _cell_rect(c, cs, o)
				if area.is_open(c):
					draw_rect(r, Color("#efe2bf"))
				else:
					var near := false
					for d in 4:
						if area.is_open(c + Game.DIR_VEC[d]):
							near = true
					if near:
						draw_rect(r.grow(-1), Color("#b89a6a"))
						draw_rect(r.grow(-1), ink, false, 1.0)
		var well: Vector2i = Vector2i(12, 6)
		draw_arc(_cell_rect(well, cs, o).get_center(), cs * 0.35, 0, TAU, 16, ink, 2.0)
		# Places found so far.
		spots.clear()
		var known := Game.town_places("lehan")
		for key in LehanStreets.ENTRANCES:
			if not key in known:
				continue
			var e: Dictionary = LehanStreets.ENTRANCES[key]
			var door: Vector2i = e.cell + (Game.DIR_VEC[e.dir] if key != "market" else Vector2i(-1, -5))
			var p := _cell_rect(door, cs, o).get_center()
			spots[key] = p
			draw_circle(p, 7, Color("#b03020"))
			draw_arc(p, 7, 0, TAU, 16, ink, 1.5)
			var label: String = Game.TOWNS.lehan.places[key].name
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var lp := p + Vector2(10, 4)
			if lp.x + w > size.x - 4:
				lp.x = p.x - 10 - w
			draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
		# The party: a red arrow at its cell.
		var pc := _cell_rect(area.pos, cs, o).get_center()
		var dir := Vector2(Game.DIR_VEC[area.facing])
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([pc + dir * cs * 0.6, pc + side * cs * 0.4 - dir * cs * 0.3,
			pc - side * cs * 0.4 - dir * cs * 0.3]), Color("#e02010"))
		draw_string(font, Vector2(0, size.y - 10), "Click a place to go there", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(ink, 0.7))

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			for key in spots:
				if e.position.distance_to(spots[key]) < 14:
					picked.emit(key)
					accept_event()
					return
