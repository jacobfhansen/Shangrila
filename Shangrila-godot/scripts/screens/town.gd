extends Control
## A town map (replaces the old painted city view). Shows the places discovered so far;
## click one to go there. More places appear as they are found (see Game.TOWNS).

const MAP_RECT := Rect2(20, 52, 600, 370)

var town := "lehan"
var layer: TownLayer
var info: Label


func _ready() -> void:
	town = Game.location if Game.TOWNS.has(Game.location) else "lehan"
	var t: Dictionary = Game.TOWNS[town]
	Ui.stone_background(self, 0.5)
	Ui.title(self, t.name, Vector2(0, 8), 28, 640, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.frame(self, MAP_RECT.grow(4), Color("#2a1c0e"), Color("#a07a40"), 2)
	Ui.image(self, t.image, MAP_RECT)
	layer = TownLayer.new()
	layer.town = town
	add_child(layer)
	Ui.place(layer, MAP_RECT)
	_build_places()

	Ui.btn(self, "Leave town", Rect2(20, 436, 110, 32), _on_place.bind("gate"), "Out through the gate, onto the world map")
	Ui.btn(self, "Save", Rect2(470, 436, 70, 32), _on_save, "Save the game")
	Ui.btn(self, "Quit", Rect2(550, 436, 70, 32), _on_quit, "Back to the main menu")
	var who := "Party: " + (", ".join(Game.party.map(func(c): return c.name)) if Game.party.size() > 0 else "nobody")
	info = Ui.label(self, who, Vector2(140, 444), 12, Ui.TEXT, 320)


func _build_places() -> void:
	for ch in layer.get_children():
		ch.queue_free()
	var places: Dictionary = Game.TOWNS[town].places
	for key in Game.town_places(town):
		var pl: Dictionary = places[key]
		var at: Vector2 = pl.at
		var lbl := Label.new()
		lbl.text = pl.name
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_color_override("font_color", Ui.INK)
		lbl.add_theme_color_override("font_outline_color", Color(0.95, 0.89, 0.74, 0.95))
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(lbl)
		var ly := at.y + 13 if key != "gate" else at.y - 34
		Ui.place(lbl, Rect2(at.x - 70, ly, 140, 20))
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = "%s\n%s" % [pl.name, pl.desc]
		b.pressed.connect(_on_place.bind(key))
		layer.add_child(b)
		Ui.place(b, Rect2(at.x - 16, at.y - 16, 32, 32))
	layer.queue_redraw()


func _on_place(key: String) -> void:
	if Game.main.modal_open:
		return
	match Game.TOWNS[town].places[key].kind:
		"gate":
			Game.main.goto("world")
		"inn":
			Game.main.goto("inn")
		"smith":
			Game.main.goto("shop")
		"market":
			await _market()


## The market square: the crier's notice about the mines, and a first look around.
func _market() -> void:
	if not "mines" in Game.known:
		Game.known.append("mines")
		Game.discover_place(town, "smith")
		_build_places()
		await Game.main.message("A crier reads a notice from the council: miners have gone missing in the old workings above the town, and the council will pay well for anyone willing to look into it.\n\nThe Mines are now on your map.")
		await Game.main.message("Across the square hangs the sign of a weapon smith.\n\nThe Weapon Smith is now on the town map.")
		return
	if Game.discover_place(town, "smith"):
		_build_places()
		await Game.main.message("Across the square hangs the sign of a weapon smith.\n\nThe Weapon Smith is now on the town map.")
		return
	await Game.main.message("The market is busy. The council's notice about the mines still hangs by the well.")


func _on_save() -> void:
	info.text = "Game saved." if Game.save_game("town") else "The game could not be saved."


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


## Draws a marker for each discovered place.
class TownLayer extends Control:
	var town := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var ink := Color("#46301a")
		var fill := Color("#ecdcb4")
		var places: Dictionary = Game.TOWNS[town].places
		for key in Game.town_places(town):
			var pl: Dictionary = places[key]
			var p: Vector2 = pl.at
			draw_circle(p, 13, Color(fill, 0.92))
			draw_arc(p, 13, 0, TAU, 32, ink, 1.6, true)
			match pl.kind:
				"gate":
					draw_rect(Rect2(p.x - 7, p.y - 6, 14, 12), ink, false, 1.5)
					draw_arc(p + Vector2(0, 2), 4, PI, TAU, 12, ink, 1.5, true)
					draw_line(p + Vector2(-4, 2), p + Vector2(-4, 6), ink, 1.5)
					draw_line(p + Vector2(4, 2), p + Vector2(4, 6), ink, 1.5)
				"market":
					# A stall with an awning.
					draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -2), p + Vector2(-6, -7), p + Vector2(6, -7), p + Vector2(8, -2)]), Color("#b04a30"))
					draw_rect(Rect2(p.x - 7, p.y - 2, 14, 8), ink, false, 1.5)
				"inn":
					# A tankard.
					draw_rect(Rect2(p.x - 5, p.y - 6, 9, 12), ink, false, 1.6)
					draw_arc(p + Vector2(5, 0), 3, -PI / 2, PI / 2, 8, ink, 1.6, true)
					draw_line(p + Vector2(-5, -3), p + Vector2(4, -3), ink, 1.2)
				"smith":
					# An anvil.
					draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -4), p + Vector2(7, -4), p + Vector2(4, 0),
						p + Vector2(2, 0), p + Vector2(4, 5), p + Vector2(-4, 5), p + Vector2(-2, 0), p + Vector2(-5, 0)]), ink)
