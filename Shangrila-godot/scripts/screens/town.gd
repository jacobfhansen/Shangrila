extends Control
## A town map (replaces the old painted city view). Shows the places discovered so far;
## click one to go there. More places appear as they are found (see Game.TOWNS).

const MAP_RECT := Rect2(20, 52, 600, 370)

var town := "lehan"
var layer: TownLayer
var info: Label
var buttons: Array = []
var busy := false


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

	buttons.append(Ui.btn(self, "Leave town", Rect2(20, 436, 110, 32), _on_place.bind("gate"), "Out through the gate, onto the world map"))
	buttons.append(Ui.btn(self, "Save", Rect2(470, 436, 70, 32), _on_save, "Save the game"))
	buttons.append(Ui.btn(self, "Quit", Rect2(550, 436, 70, 32), _on_quit, "Back to the main menu"))
	var who := "Party: " + (", ".join(Game.party.map(func(c): return c.name)) if Game.party.size() > 0 else "nobody")
	info = Ui.label(self, who, Vector2(140, 444), 12, Ui.TEXT, 320)
	if _arrival_pending():
		Game.main.goto.call_deferred("streets")   # the arrival is played in the streets


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
	if Game.main.modal_open or busy:
		return
	match Game.TOWNS[town].places[key].kind:
		"gate":
			if Game.story.has("employer"):
				Game.story["left_lehan"] = true
			Game.main.goto("world")
		"house":
			await _knock()
		"inn":
			Game.main.goto("inn")
		"smith":
			Game.main.goto("shop")
		"market":
			Game.main.goto("streets", {"at": "market", "into": true})
		"council":
			Game.main.goto("streets", {"at": "council", "into": true})
		"warehouse":
			Game.main.goto("streets", {"at": "warehouse", "into": true})


# ---------------------------------------------------------------- arriving in Lehan

## The first visit after the road: the walk to the employer, the meeting, and the split.
func _arrival_pending() -> bool:
	return town == "lehan" and Game.story.get("road_done", false) and Game.story.has("host") \
		and not Game.story.has("employer")


func _set_busy(on: bool) -> void:
	busy = on
	for b in buttons:
		b.disabled = on


## Moves the red party dot along a list of points (town map coordinates).
## Knocking at the employer's door after the meeting.
func _knock() -> void:
	await Game.main.message(LehanData.knock_text())


func _on_save() -> void:
	info.text = "Game saved." if Game.save_game("town") else "The game could not be saved."


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")


## Draws a marker for each discovered place.
class TownLayer extends Control:
	var town := ""
	var party_at := Vector2(-1, -1)   # the red dot while the company walks through town
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _process(delta: float) -> void:
		if party_at.x >= 0:
			t += delta
			queue_redraw()

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
				"house":
					# A narrow house.
					draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -1), p + Vector2(0, -8), p + Vector2(6, -1)]), ink)
					draw_rect(Rect2(p.x - 5, p.y - 1, 10, 8), ink, false, 1.5)
					draw_rect(Rect2(p.x - 1.5, p.y + 2, 3, 5), ink)
				"warehouse":
					# A barrel.
					draw_rect(Rect2(p.x - 6, p.y - 7, 12, 14), ink, false, 1.6)
					draw_line(p + Vector2(-6, -2), p + Vector2(6, -2), ink, 1.2)
					draw_line(p + Vector2(-6, 2), p + Vector2(6, 2), ink, 1.2)
				"council":
					# A hall with columns.
					draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -3), p + Vector2(0, -8), p + Vector2(8, -3)]), ink)
					for k in 3:
						draw_line(p + Vector2(-5 + k * 5, -2), p + Vector2(-5 + k * 5, 5), ink, 1.6)
					draw_line(p + Vector2(-8, 6), p + Vector2(8, 6), ink, 1.6)
				"smith":
					# An anvil.
					draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -4), p + Vector2(7, -4), p + Vector2(4, 0),
						p + Vector2(2, 0), p + Vector2(4, 5), p + Vector2(-4, 5), p + Vector2(-2, 0), p + Vector2(-5, 0)]), ink)
		if party_at.x >= 0:
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_arc(party_at, 10 + pulse * 3, 0, TAU, 24, Color(0.75, 0.1, 0.05, 0.5 + 0.4 * pulse), 2.0, true)
			draw_circle(party_at, 5.5, Color(0.75, 0.1, 0.05))
			draw_arc(party_at, 5.5, 0, TAU, 16, ink, 1.2, true)
