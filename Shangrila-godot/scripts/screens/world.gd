extends Control
## World map - the known lands. Shows discovered locations and the routes between them.
## Click the party's location to enter it, or a place connected by a route to travel there.

const MAP_RECT := Rect2(20, 52, 600, 370)

var layer: MapLayer
var info: Label


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
		b.tooltip_text = _tip(key)
		b.pressed.connect(_on_location.bind(key))
		layer.add_child(b)
		Ui.place(b, Rect2(at.x - 16, at.y - 16, 32, 32))

	var here: Dictionary = Game.LOCATIONS[Game.location]
	var enter: String = "Look around" if here.screen == "" else "Enter " + here.name
	Ui.btn(self, enter, Rect2(20, 436, 150, 32), _on_location.bind(Game.location), here.desc)
	Ui.btn(self, "Save", Rect2(470, 436, 70, 32), _on_save, "Save the game")
	Ui.btn(self, "Quit", Rect2(550, 436, 70, 32), _on_quit, "Back to the main menu")
	info = Ui.label(self, "", Vector2(180, 444), 12, Ui.TEXT, 284)
	info.text = "Click a place on the map to travel there."


func _tip(key: String) -> String:
	var loc: Dictionary = Game.LOCATIONS[key]
	if key == Game.location:
		return "%s\n%s\nThe party is here. Click to enter." % [loc.name, loc.desc]
	for r in Game.routes_from(Game.location):
		if r.to == key:
			return "%s\n%s\n%d day%s away." % [loc.name, loc.desc, r.days, "" if r.days == 1 else "s"]
	return "%s\n%s\nNo known route from here." % [loc.name, loc.desc]


func _on_location(key: String) -> void:
	if Game.main.modal_open:
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
	var q := "Travel to %s?\n%d day%s, %d Endurance each." % [
		loc.name, days, "" if days == 1 else "s", Game.TRAVEL_COST * days]
	if not await Game.main.confirm(q, "Travel"):
		return
	await Game.main.message("\n".join(Game.travel(key, days)))
	Game.main.goto(loc.screen)


func _on_save() -> void:
	info.text = "Game saved." if Game.save_game("world") else "The game could not be saved."


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


## Draws the routes and the location markers under the labels and buttons.
class MapLayer extends Control:
	var t := 0.0

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
		var at: Vector2 = Game.LOCATIONS[Game.location].at
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		draw_arc(at, 15 + pulse * 3, 0, TAU, 32, Color(0.75, 0.1, 0.05, 0.5 + 0.4 * pulse), 2.5, true)

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
