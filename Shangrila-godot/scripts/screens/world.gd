extends Control
## World map - the known lands. Shows discovered locations and the routes between them.
## Click the party's location to enter it, or a place connected by a route to travel there.

const MAP_RECT := Rect2(20, 52, 600, 370)

var layer: MapLayer
var info: Label
var buttons: Array = []
var busy := false


func _ready() -> void:
	Ui.stone_background(self, 0.5)
	Ui.title(self, "The Known Lands", Vector2(0, 8), 28, 640, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.frame(self, MAP_RECT.grow(4), Color("#2a1c0e"), Color("#a07a40"), 2)
	Ui.image(self, "world_map", MAP_RECT)

	layer = MapLayer.new()
	add_child(layer)
	Ui.place(layer, MAP_RECT)

	for key in Game.known:
		var loc: Dictionary = Game.LOCATIONS[key]
		var at: Vector2 = loc.at
		var lbl := Label.new()
		lbl.text = loc.name
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_color_override("font_color", Ui.INK)
		lbl.add_theme_color_override("font_outline_color", Color(0.93, 0.86, 0.7, 0.9))
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(lbl)
		Ui.place(lbl, Rect2(at.x - 70, at.y + 11, 140, 20))
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = Ui.tip(_tip(key))
		b.pressed.connect(_on_location.bind(key))
		layer.add_child(b)
		Ui.place(b, Rect2(at.x - 16, at.y - 16, 32, 32))

	var here: Dictionary = Game.LOCATIONS[Game.location]
	var enter: String = "Look around" if here.screen == "" else "Enter " + here.name
	buttons.append(Ui.btn(self, enter, Rect2(20, 436, 150, 32), _on_location.bind(Game.location), here.desc))
	buttons.append(Ui.btn(self, "Quests", Rect2(334, 436, 66, 32), _on_quests, "The quest log: every quest and what was said (J)"))
	buttons.append(Ui.btn(self, "Save", Rect2(406, 436, 66, 32), _on_save, "Save the game"))
	buttons.append(Ui.btn(self, "Load", Rect2(478, 436, 66, 32), Game.main.load_menu, "Load a saved game (what isn't saved is lost)"))
	buttons.append(Ui.btn(self, "Quit", Rect2(550, 436, 70, 32), _on_quit, "Back to the main menu"))
	info = Ui.label(self, "", Vector2(180, 444), 12, Ui.TEXT, 150)
	info.text = "Click a place to travel."
	if get_meta("args", {}).get("road", false) and _road_pending("lehan"):
		_road_scene.call_deferred()


## The first trip from the shrine to Lehan is a scene of its own.
func _road_pending(dest: String) -> bool:
	return Game.story.has("host") and not Game.story.get("road_done", false) \
		and Game.location == "shrine" and dest == "lehan"


func _set_busy(on: bool) -> void:
	busy = on
	for b in buttons:
		b.disabled = on


## Moves the party marker from `a` to `b` (map coordinates) between fractions f0 and f1.
func _move_marker(a: Vector2, b: Vector2, f0: float, f1: float, secs: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(f: float): layer.party_at = a.lerp(b, f), f0, f1, secs).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _road_scene() -> void:
	_set_busy(true)
	var host: String = Game.story.host
	var a: Vector2 = Game.LOCATIONS["shrine"].at
	var b: Vector2 = Game.LOCATIONS["lehan"].at
	info.text = "The company sets out for Lehan."
	var box := DialogueBox.new()
	box.cast = PrologueData.company_cast()
	box.cast["brigand"] = RoadData.BRIGAND
	box.host = host
	Ui.place(box, Rect2(20, 52, 600, 248))
	add_child(box)
	box.effect.connect(func(name: String):
		if name.begins_with("consent_"):
			Game.story["consent"] = "given" if name == "consent_given" else "forced")
	_move_marker(a, b, 0.0, 0.5, 6.0)
	box.play(RoadData.before(host))
	await box.finished
	box.visible = false
	var battle := BattleWindow.new()
	battle.title = "Ambush on the road!"
	battle.box = box
	for i in Game.party.size():
		if Game.party[i].name == PrologueData.CAST[host].name:
			battle.host_index = i
	Ui.place(battle, MAP_RECT)
	add_child(battle)
	battle.start(RoadData.AMBUSH)
	var r: Array = await battle.done
	battle.queue_free()
	box.visible = true
	_move_marker(a, b, 0.5, 1.0, 6.0)
	box.play(RoadData.after(host, r[0], r[1]))
	await box.finished
	Game.story["road_done"] = true
	Game.story["host_control"] = true
	var lines := Game.travel("lehan", 1)
	if lines.size() > 1:
		box.log_line(lines[1])
		await Game.main.message(lines[1])
	box.show_buttons([["Enter Lehan", func(): Game.main.goto("streets")]])


func _tip(key: String) -> String:
	var loc: Dictionary = Game.LOCATIONS[key]
	if key == Game.location:
		return "%s\n%s\nThe party is here. Click to enter." % [loc.name, loc.desc]
	for r in Game.routes_from(Game.location):
		if r.to == key:
			return "%s\n%s\n%d day%s away." % [loc.name, loc.desc, r.days, "" if r.days == 1 else "s"]
	return "%s\n%s\nNo known route from here." % [loc.name, loc.desc]


func _on_location(key: String) -> void:
	if Game.main.modal_open or busy:
		return
	if key == Game.location:
		var screen: String = Game.LOCATIONS[key].screen
		if screen == "":
			await Game.main.message(Game.LOCATIONS[key].desc)
		else:
			Game.main.goto(screen)
		return
	var days := -1
	for r in Game.routes_from(Game.location):
		if r.to == key:
			days = r.days
	var loc: Dictionary = Game.LOCATIONS[key]
	if days < 0:
		await Game.main.message("You know of no road from %s to %s." % [Game.LOCATIONS[Game.location].name, loc.name])
		return
	var food := Game.food_days()
	var q := "Travel to %s?\n%d day%s, %d Endurance each a day.\nFood in the packs: %s." % [
		loc.name, days, "" if days == 1 else "s", Game.TRAVEL_COST, "none" if food < 0.5
		else "about %d day%s" % [roundi(food), "" if roundi(food) == 1 else "s"]]
	if not await Game.main.confirm(q, "Travel"):
		return
	if _road_pending(key):
		_road_scene()
		return
	var scenes := {}
	if key == "marsh_shrine" and not Game.story.get("marsh_road_done", false):
		scenes = MarshRoad.SCENES
		Game.story["marsh_road_done"] = true
	await _travel_days(key, days, scenes)


## The trip a day at a time (Game.road_day): the marker moves along the route, and a scene
## can be played after a given day (MarshRoad). Then the summary, and in through the gate.
func _travel_days(key: String, days: int, scenes: Dictionary) -> void:
	_set_busy(true)
	var loc: Dictionary = Game.LOCATIONS[key]
	var a: Vector2 = Game.LOCATIONS[Game.location].at
	var lines := ["After %d day%s on the road the party reaches %s." % [days, "" if days == 1 else "s", loc.name]]
	var box: DialogueBox = null
	for d in days:
		await _move_marker(a, loc.at, float(d) / days, float(d + 1) / days, 1.4)
		if scenes.has(d + 1):
			if box == null:
				box = DialogueBox.new()
				box.cast = MarshRoad.cast()
				box.host = Game.story.get("host", "")
				Ui.place(box, Rect2(20, 52, 600, 248))
				add_child(box)
				box.effect.connect(func(fx: String):
					var l := MarshRoad.apply(fx)
					if l != "":
						box.log_line(l))
			box.visible = true
			info.text = "Day %d on the road." % (d + 1)
			box.play(MarshRoad.scene(scenes[d + 1]))
			await box.finished
			box.show_buttons([["Go on", func(): box.finished.emit()]])
			await box.finished
			box.visible = false
		for l in Game.road_day():
			lines.append("Day %d: %s" % [d + 1, l] if days > 1 else l)
	Game.location = key
	if box != null:
		box.queue_free()
	await Game.main.message("\n".join(lines))
	Game.main.goto(loc.screen if loc.screen != "" else "world")


func _on_quests() -> void:
	if not buttons[0].disabled:   # not in the middle of a scene
		QuestLog.open()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_J and not Game.main.modal_open:
		_on_quests()
		get_viewport().set_input_as_handled()


func _on_save() -> void:
	if await Game.main.save_menu("world"):
		info.text = "Game saved."


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


## Draws the routes and the location markers under the labels and buttons.
class MapLayer extends Control:
	var t := 0.0
	var party_at := Vector2(-1, -1)   # set while travelling; otherwise the party's location

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var ink := Color("#46301a")
		var drawn := {}
		for key in Game.known:
			for r in Game.routes_from(key):
				var id := [key, r.to]
				id.sort()
				if drawn.has(str(id)):
					continue
				drawn[str(id)] = true
				_dashed(Game.LOCATIONS[key].at, Game.LOCATIONS[r.to].at, Color(ink, 0.8))
		for key in Game.known:
			var loc: Dictionary = Game.LOCATIONS[key]
			match loc.kind:
				"city": _city(loc.at, ink)
				"ruin": _ruin(loc.at, ink)
				_: _cave(loc.at, ink)
		# The party: a pulsing red ring around its location.
		var at: Vector2 = party_at if party_at.x >= 0 else Game.LOCATIONS[Game.location].at
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		draw_arc(at, 15 + pulse * 3, 0, TAU, 32, Color(0.75, 0.1, 0.05, 0.5 + 0.4 * pulse), 2.5, true)
		if party_at.x >= 0:
			draw_circle(at, 5.5, Color(0.75, 0.1, 0.05))
			draw_arc(at, 5.5, 0, TAU, 16, Color("#46301a"), 1.2, true)

	func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
		var len := a.distance_to(b)
		var dir := (b - a) / len
		var d := 14.0
		while d < len - 14.0:
			draw_line(a + dir * d, a + dir * minf(d + 6.0, len - 14.0), col, 2.0, true)
			d += 11.0

	func _city(p: Vector2, ink: Color) -> void:
		var body := Rect2(p.x - 9, p.y - 5, 18, 11)
		draw_rect(body, Color("#e8d8b0"))
		for i in 3:
			draw_rect(Rect2(p.x - 9 + i * 7, p.y - 9, 4, 4), Color("#e8d8b0"))
			draw_rect(Rect2(p.x - 9 + i * 7, p.y - 9, 4, 4), ink, false, 1.0)
		draw_rect(body, ink, false, 1.5)
		draw_rect(Rect2(p.x - 2, p.y, 4, 6), ink)

	func _ruin(p: Vector2, ink: Color) -> void:
		var stone := Color("#d8c8a0")
		draw_rect(Rect2(p.x - 9, p.y + 2, 18, 5), stone)
		draw_rect(Rect2(p.x - 9, p.y + 2, 18, 5), ink, false, 1.0)
		var pillar := PackedVector2Array([p + Vector2(-4, 2), p + Vector2(-4, -9), p + Vector2(-1, -6),
			p + Vector2(1, -10), p + Vector2(4, -7), p + Vector2(4, 2)])
		draw_colored_polygon(pillar, stone)
		draw_polyline(pillar + PackedVector2Array([pillar[0]]), ink, 1.2, true)
		draw_circle(p + Vector2(8, 0), 1.6, ink)
		draw_circle(p + Vector2(-8, -1), 1.2, ink)

	func _cave(p: Vector2, ink: Color) -> void:
		var hill := PackedVector2Array([p + Vector2(-12, 7), p + Vector2(-4, -8), p + Vector2(4, -9), p + Vector2(12, 7)])
		draw_colored_polygon(hill, Color("#c8b088"))
		draw_polyline(hill, ink, 1.5, true)
		var mouth := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			mouth.append(p + Vector2(cos(a) * 5, 7 + sin(a) * 7))
		draw_colored_polygon(mouth, Color("#1a1008"))
