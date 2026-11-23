extends Control
## Aubermont's river gate district, walked in first person like Lehan's streets and Oggal (see
## AubermontStreets and AubermontData).
## Keys: W/Up forward, S/Down back, A/Left and D/Right turn, Q/E step sideways,
## Space/Enter talk to (or use) what is straight ahead, M the plan of the district (Esc closes it),
## C the party's character screen, J quests.
## Args: {"district": "gate" / "oldtown", "at": place key, "into": bool}, or {"at_cell": [x, y],
## "facing": dir}. The district is remembered (Game.story.aub_district) for saves and the sheet.

var area := AubermontStreets.new()
var view: DungeonView
var compass: Compass
var hint: Label
var talking := false
var buttons: Array = []
var plan: _Plan
var map_btn: Button
## The places on the plan, by AubermontStreets.ENTRANCES key.
const PLACE_NAMES := {"gate": "River Gate", "inn": "The Lamplighter", "shop": "Corvin's Arms",
	"oldtown": "To the Old Town", "hill": "Hill Gate", "rivergate": "To the River Gate",
	"library": "The Great Library", "temple": "Temple of the Hours"}


func _ready() -> void:
	var args: Dictionary = get_meta("args", {})
	area.set_district(args.get("district", Game.story.get("aub_district", "gate")))
	Game.story["aub_district"] = area.district
	area.place_at(args.get("at", area.entrances.keys()[0]), args.get("into", false))
	if args.has("at_cell"):
		area.pos = Vector2i(args.at_cell[0], args.at_cell[1])
		area.facing = args.get("facing", 0)
	Game.location = "aubermont"
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

	Ui.title(self, "Aubermont", Vector2(438, 18), 24, 190, HORIZONTAL_ALIGNMENT_CENTER)
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
	map_btn = Ui.btn(self, "Map", Rect2(446, 290, 58, 30), _on_map, "The plan of the district: click a place to go to its entrance (M)")
	map_btn.toggle_mode = true
	buttons.append(Ui.btn(self, "Party", Rect2(507, 290, 58, 30), _on_party, "Your characters: abilities, gear and silver (C)"))
	buttons.append(Ui.btn(self, "Quests", Rect2(568, 290, 58, 30), _on_quests, "The quest log: every quest and what was said (J)"))
	buttons.append(Ui.btn(self, "Save", Rect2(446, 326, 58, 30), _on_save, "Save the game"))
	buttons.append(Ui.btn(self, "Load", Rect2(507, 326, 58, 30), Game.main.load_menu, "Load a saved game (what isn't saved is lost)"))
	buttons.append(Ui.btn(self, "Quit", Rect2(568, 326, 58, 30), _on_quit, "Back to the main menu"))
	Ui.frame(self, Rect2(436, 364, 196, 62))
	var help := Ui.label(self, "%s. Walk up to people to talk, and into doors to go in. Map shows the district." % AubermontStreets.DISTRICTS[area.district].name.capitalize(),
		Vector2(444, 368), 11, Ui.DIM, 182)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size = Vector2(182, 54)
	Ui.frame(self, Rect2(14, 432, 618, 38))
	hint = Ui.label(self, "", Vector2(24, 442), 13, Ui.TEXT, 600)
	_after_move()
	if area.district == "gate" and not Game.story.get("aubermont_entered", false):
		_arrival.call_deferred()
	elif area.district == "oldtown" and not Game.story.get("oldtown_entered", false):
		Game.story["oldtown_entered"] = true
		_dialog.call_deferred("The old town", AubermontData.oldtown_arrival())


func _arrival() -> void:
	Game.story["aubermont_entered"] = true
	await _dialog("Aubermont", AubermontData.arrival())


func _after_move() -> void:
	compass.queue_redraw()
	var t := area.thing_at(area.ahead())
	match t.get("kind", ""):
		"person":
			hint.text = "Ahead: %s.  Walk on or press Space to talk." % AubermontData.PEOPLE[t.id].name
		"exit":
			hint.text = {
				"gate": "Ahead: the river gate, out to the north road.  Space to leave.",
				"inn": "Ahead: the Lamplighter inn, a lantern over the door.  Space to go in.",
				"shop": "Ahead: Corvin's Arms, a blade and a sack on the sign.  Space to go in.",
				"oldtown": "Ahead: the arch to the old town, dark as a mouth.  Space to go through.",
				"hill": "Ahead: the iron gate to the hill.",
				"rivergate": "Ahead: the arch back to the river gate.  Space to go through.",
				"library": "Ahead: the Great Library, an open book carved over its door.  Space to go in.",
				"temple": "Ahead: the Temple of the Hours, its clock face high above.  Space to go in.",
			}.get(t.to, "")
		"prop":
			hint.text = {"founders": "Ahead: the Founders, five lords in stone round a broken crown.  Space to look.",
				"lamp": "An iron lamp post, its lantern lit at midday.", "stall": "A market stall under a sagging awning.",
				"barrels": "Barrels, smelling of fish and tar.", "grave": "A headstone, the name worn away.",
				"yew": "A dead yew, black and twisted.", "well": "An old well. The water is a long way down."}.get(t.what, "")
		_:
			hint.text = _where()


func _where() -> String:
	var p := area.pos
	if area.district == "oldtown":
		if p.x >= 16 and p.y <= 9:
			return "The graveyard behind the Temple of the Hours. Crooked stones, wet grass, a dead yew."
		if p.y <= 3:
			return "The library's forecourt. Scholars in black hurry past without looking up."
		if p.x <= 8 and p.y >= 6 and p.y <= 8:
			return "A little square round an old well. Washing hangs between the houses, grey with soot."
		if p.y >= 11:
			return "A narrow alley. It smells of damp and smoke, and goes nowhere."
		return "The old town's crooked street. The houses here are older still, and lean further."
	if p.x >= 6 and p.x <= 14 and p.y >= 4 and p.y <= 9:
		return "The market square. The houses lean in over it from every side."
	return "A narrow street. The upper storeys almost meet overhead; water drips from the eaves."


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


func _use_ahead() -> void:
	if _locked() or view.busy:
		return
	_use(area.thing_at(area.ahead()))


func _use(t: Dictionary) -> void:
	match t.get("kind", ""):
		"person":
			await _dialog("Talking to " + AubermontData.PEOPLE[t.id].name, AubermontData.talk(t.id))
		"prop":
			if t.what == "founders":
				await _dialog("The Founders", AubermontData.founders())
		"exit":
			match t.to:
				"gate":
					if await Game.main.confirm("Leave Aubermont by the river gate?", "Leave"):
						Game.main.goto("world")
				"shop":
					Game.main.goto("shop", {"shop": "aubermont"})
				"inn":
					Game.main.goto("inn")
				"oldtown":
					Game.main.goto("city", {"district": "oldtown", "at": "rivergate"})
				"rivergate":
					Game.main.goto("city", {"district": "gate", "at": "oldtown"})
				"library":
					await _dialog("The Great Library", AubermontData.library())
				"temple":
					await _dialog("The Temple of the Hours", AubermontData.temple())
				"hill":
					await _dialog("The hill gate", AubermontData.talk("2"))


# ---------------------------------------------------------------- talking

func _dialog(title: String, lines: Array) -> void:
	if lines.is_empty():
		return
	talking = true
	map_btn.disabled = true
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
	box.cast = AubermontData.cast()
	box.host = host
	box.journal = "aubermont"
	box.journal_place = "Aubermont: " + title.to_lower()
	Ui.place(box, Rect2(20, 180, 600, 286))
	ov.add_child(box)
	box.effect.connect(func(fx: String):
		var l := AubermontData.apply(fx)
		if l != "":
			box.log_line(l))
	box.play(lines)
	await box.finished
	box.show_buttons([["Goodbye", func(): box.finished.emit()]])
	await box.finished
	ov.queue_free()
	talking = false
	map_btn.disabled = false
	for b in buttons:
		b.disabled = false
	_after_move()


func _on_party() -> void:
	if _locked() or Game.party.is_empty():
		return
	Game.main.goto("view", {"party": true, "index": 0, "back": "city",
		"back_args": {"at_cell": [area.pos.x, area.pos.y], "facing": area.facing}})


func _on_save() -> void:
	await Game.main.save_menu("city")


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


func _on_quests() -> void:
	if not _locked():
		QuestLog.open()


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
		KEY_M:
			map_btn.button_pressed = true
			_on_map()
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


## The plan of the district drawn from the street map: streets and the square, the houses along
## them, the Founders, the places (clickable) and the party.
class _Plan:
	extends Control
	signal picked(place: String)
	var area: AubermontStreets
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
		var ink := Color("#2a1a10")
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 28), "Aubermont: " + AubermontStreets.DISTRICTS[area.district].name.capitalize(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, ink)
		for y in n.y:
			for x in n.x:
				var c := Vector2i(x, y)
				var r := _cell_rect(c, cs, o)
				if area.thing_at(c).get("kind", "") in ["", "person", "prop"]:
					draw_rect(r, Color("#e8dab4"))
				else:
					var near := false
					for d in 4:
						var t: String = area.thing_at(c + Game.DIR_VEC[d]).get("kind", "")
						if t in ["", "person", "prop"]:
							near = true
					if near:
						draw_rect(r.grow(-1), Color("#6a5a4a"))
						draw_rect(r.grow(-1), ink, false, 1.0)
		if area.district == "gate":
			var founders := _cell_rect(Vector2i(10, 6), cs, o).get_center()
			draw_arc(founders, cs * 0.4, 0, TAU, 16, ink, 2.0)
			draw_circle(founders, cs * 0.15, ink)
		spots.clear()
		for key in area.entrances:
			var e: Dictionary = area.entrances[key]
			var door: Vector2i = e.cell + Game.DIR_VEC[e.dir]
			var p := _cell_rect(door, cs, o).get_center()
			spots[key] = p
			draw_circle(p, 7, Color("#b03020"))
			draw_arc(p, 7, 0, TAU, 16, ink, 1.5)
			var label: String = PLACE_NAMES[key]
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var lp := p + Vector2(10, 4)
			if lp.x + w > size.x - 4 or key == "shop":
				lp.x = p.x - 10 - w
			if lp.x < 4:
				lp.x = 4
				lp.y = p.y - 10
			draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
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
