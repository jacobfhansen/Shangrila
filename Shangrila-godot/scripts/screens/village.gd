extends Control
## Oggal, the Thuug stilt village on the causeway, walked in first person like Lehan's streets
## (see MarshVillage and MarshData). The hub for the Drowned Shrine.
## Keys: W/Up forward, S/Down back, A/Left and D/Right turn, Q/E step sideways,
## Space/Enter talk to (or use) what is straight ahead, C the party's character screen, J quests.
## Args: {"at": place key, "into": bool}, or {"at_cell": [x, y], "facing": dir}. Without either the
## party comes in at the causeway gate; the first time, Orrun stops them there.

var area := MarshVillage.new()
var view: DungeonView
var compass: Compass
var hint: Label
var talking := false
var buttons: Array = []


func _ready() -> void:
	var args: Dictionary = get_meta("args", {})
	area.place_at(args.get("at", "gate"), args.get("into", false))
	if not args.has("at"):
		area.facing = 1   # in off the causeway, looking along the boardwalk
	if args.has("at_cell"):
		area.pos = Vector2i(args.at_cell[0], args.at_cell[1])
		area.facing = args.get("facing", 1)
	Game.location = "marsh_shrine"
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

	Ui.title(self, "Oggal", Vector2(438, 18), 24, 190, HORIZONTAL_ALIGNMENT_CENTER)
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
	buttons.append(Ui.btn(self, "Party", Rect2(446, 290, 88, 30), _on_party, "Your characters: abilities, gear and silver (C)"))
	buttons.append(Ui.btn(self, "Quests", Rect2(538, 290, 88, 30), _on_quests, "The quest log: every quest and what was said (J)"))
	buttons.append(Ui.btn(self, "Save", Rect2(446, 326, 58, 30), _on_save, "Save the game"))
	buttons.append(Ui.btn(self, "Load", Rect2(507, 326, 58, 30), Game.main.load_menu, "Load a saved game (what isn't saved is lost)"))
	buttons.append(Ui.btn(self, "Quit", Rect2(568, 326, 58, 30), _on_quit, "Back to the main menu"))
	Ui.frame(self, Rect2(436, 364, 196, 62))
	var help := Ui.label(self, "A Thuug stilt village on the causeway. Walk up to people to talk, and into doors to go in.",
		Vector2(444, 368), 11, Ui.DIM, 182)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size = Vector2(182, 54)
	Ui.frame(self, Rect2(14, 432, 618, 38))
	hint = Ui.label(self, "", Vector2(24, 442), 13, Ui.TEXT, 600)
	_after_move()
	if not Game.story.get("marsh_arrived", false):
		_arrival.call_deferred()


func _arrival() -> void:
	Game.story["marsh_arrived"] = true
	await _dialog("At the causeway gate", MarshData.meet_orrun())


func _after_move() -> void:
	compass.queue_redraw()
	var t := area.thing_at(area.ahead())
	match t.get("kind", ""):
		"person":
			hint.text = "Ahead: %s.  Walk on or press Space to talk." % MarshData.PEOPLE[t.id].name
		"exit":
			hint.text = {
				"gate": "Ahead: the causeway gate, back out to the road.  Space to leave.",
				"trader": "Ahead: Hett's stall, hung with dried fish.  Space to trade.",
				"guest": "Ahead: the guest hut, with a lamp by the door.  Space to go in.",
				"ubba_hut": "Ahead: Ubba's hut.",
				"elder": "Ahead: the elder's longhouse.",
				"shrine": "Ahead: the causeway runs on east into the mist, towards the drowned house.",
			}.get(t.to, "")
		"prop":
			hint.text = {"reeds": "Reeds, taller than a man.", "boat": "A dugout boat, tied to the boardwalk.",
				"rack": "A rack of fish drying in the smoke."}.get(t.what, "")
		"water":
			hint.text = "Black water. The boardwalks are the only way through."
		_:
			hint.text = _where()


func _where() -> String:
	var p := area.pos
	if p.y == 6:
		return "The main boardwalk through Oggal, from the causeway gate to the far causeway."
	return "A side walk between the stilt huts. The planks creak, and water laps underneath."


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
	return talking or Game.main.modal_open


func _use_ahead() -> void:
	if _locked() or view.busy:
		return
	_use(area.thing_at(area.ahead()))


func _use(t: Dictionary) -> void:
	match t.get("kind", ""):
		"person":
			await _dialog("Talking to " + MarshData.PEOPLE[t.id].name, MarshData.talk(t.id))
		"exit":
			match t.to:
				"gate":
					if await Game.main.confirm("Leave Oggal by the causeway?", "Leave"):
						Game.main.goto("world")
				"trader":
					Game.main.goto("shop", {"shop": "marsh"})
				"guest":
					await _guest_hut()
				"ubba_hut":
					await Game.main.message("Ubba's hut. Nets hang drying by the door; she sits outside most of the day.")
				"elder":
					await Game.main.message("The elder's longhouse. The elder is out on the water with the fishing boats; Ubba speaks for the village while he is gone.")
				"shrine":
					if await Game.main.confirm("Follow the causeway east, out to the drowned house?", "Go"):
						Game.site = "shrine"
						Game.mine_level = 1
						Game.pos = ShrineArea.START
						Game.facing = ShrineArea.START_FACING
						Game.main.goto("dungeon")


## The guest hut: the village's checkpoint (saved on going in), and a night's rest.
func _guest_hut() -> void:
	Game.reach_checkpoint("village")
	var price := Game.INN_NIGHT * Game.party.size()
	if not await Game.main.confirm("The guest hut: reed mats, a fire pit, the smell of smoked fish. (Checkpoint: the game is saved.)\n\nRest a night for %d silver?" % price, "Rest"):
		return
	if not Game.pay(price):
		await Game.main.message("The purse can't cover a night (%d silver)." % price)
		return
	for c in Game.party:
		c.hits = c.max_hits
		c.magic = c.max_magic
	var lines := ["The party sleeps to the sound of water under the floor."]
	lines.append_array(Game.pass_days(1))
	if Game.party.any(func(c): return c.get("wounded", false)):
		lines.append("A bad wound needs days of proper rest, at the inn in Lehan.")
	_refresh_view()
	await Game.main.message("\n".join(lines))


func _refresh_view() -> void:
	_after_move()


# ---------------------------------------------------------------- talking

func _dialog(title: String, lines: Array) -> void:
	if lines.is_empty():
		return
	talking = true
	for b in buttons:
		b.disabled = true
	var host: String = Game.story.get("host", "")
	if host == "":
		lines = lines.filter(func(st): return not (st.has("s") and st.s == "") and not st.has("i") and not st.has("sp"))
	var ov := Control.new()
	add_child(ov)
	Ui.place(ov, Rect2(0, 0, 640, 480))
	Ui.frame(ov, Rect2(10, 150, 620, 322), Color("#1a120a"), Color("#a07a40"), 2)
	Ui.label(ov, title, Vector2(22, 156), 15, Ui.GOLD)
	var box := DialogueBox.new()
	box.cast = MarshData.cast()
	box.host = host
	box.journal = "marsh"
	box.journal_place = title
	Ui.place(box, Rect2(20, 180, 600, 286))
	ov.add_child(box)
	box.effect.connect(func(fx: String):
		var l := MarshRoad.apply(fx)
		if l != "":
			box.log_line(l))
	box.play(lines)
	await box.finished
	box.show_buttons([["Goodbye", func(): box.finished.emit()]])
	await box.finished
	ov.queue_free()
	talking = false
	for b in buttons:
		b.disabled = false
	_after_move()


func _on_party() -> void:
	if _locked() or Game.party.is_empty():
		return
	Game.main.goto("view", {"party": true, "index": 0, "back": "village",
		"back_args": {"at_cell": [area.pos.x, area.pos.y], "facing": area.facing}})


func _on_save() -> void:
	await Game.main.save_menu("village")


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


func _on_quests() -> void:
	if not _locked():
		QuestLog.open()


func _unhandled_input(e: InputEvent) -> void:
	if talking or Game.main.modal_open or not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.keycode:
		KEY_W, KEY_UP: _walk(0)
		KEY_S, KEY_DOWN: _walk(2)
		KEY_A, KEY_LEFT: _turn(-1)
		KEY_D, KEY_RIGHT: _turn(1)
		KEY_Q: _walk(3)
		KEY_E: _walk(1)
		KEY_SPACE, KEY_ENTER, KEY_KP_ENTER: _use_ahead()
		KEY_C: _on_party()
		KEY_J: _on_quests()
		_: return
	get_viewport().set_input_as_handled()
