extends Control
## City - Lehan. The gate leads out to the world map, plus the inn and the weapon smith (Shops[2]).


func _ready() -> void:
	# Sky (the original SKY picture) and ground.
	Ui.image(self, "SKY", Rect2(0, 0, 640, 230))
	var ground := Ui.image(self, "floor_tiles", Rect2(0, 330, 640, 150), true)
	ground.modulate = Color(0.75, 0.65, 0.55)
	Ui.shade(self, Rect2(0, 330, 640, 150), Color(0, 0, 0, 0.25))

	# City wall with the gate in the middle.
	var wall := Ui.image(self, "rock2", Rect2(0, 190, 640, 145), true)
	wall.modulate = Color(0.8, 0.78, 0.75)
	for x in range(0, 640, 32):
		Ui.image(self, "rock2", Rect2(x, 176, 18, 16), true).modulate = Color(0.8, 0.78, 0.75)
	_tower(Rect2(258, 120, 50, 215))
	_tower(Rect2(372, 120, 50, 215))
	Ui.image(self, "rock", Rect2(308, 160, 64, 175), true)
	_door(Rect2(316, 220, 48, 115), "Gate", _on_gate, "Leave the city and set out into the land", Color("#0a0806"))

	# Weapon smith (left).
	_house(Rect2(36, 220, 190, 140), "dark_stone", Color("#7a2a1a"))
	_sign(Rect2(66, 232, 130, 24), "Weapon Smith")
	_door(Rect2(110, 288, 40, 72), "Shop", _on_shop, "Enter the weapon smith", Color("#3a2410"))

	# Inn (right).
	_house(Rect2(440, 214, 176, 146), "try2", Color("#3a3a5a"))
	_sign(Rect2(488, 226, 80, 24), "The Inn")
	_door(Rect2(508, 290, 40, 70), "Inn", _on_inn, "Enter the inn", Color("#3a2410"))

	Ui.title(self, Game.city.name, Vector2(0, 14), 34, 640, HORIZONTAL_ALIGNMENT_CENTER)
	Ui.btn(self, "Quit", Rect2(10, 438, 70, 32), _on_quit, "Back to the main menu")
	if not "mines" in Game.known:
		_hear_of_mines.call_deferred()
	var who := "Party: " + (", ".join(Game.party.map(func(c): return c.name)) if Game.party.size() > 0 else "nobody - visit the inn to muster a party")
	Ui.label(self, who, Vector2(92, 446), 12, Ui.TEXT, 540)


func _poly(pts: Array, col: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = col
	add_child(p)


func _tower(r: Rect2) -> void:
	Ui.image(self, "rock2", r, true).modulate = Color(0.7, 0.68, 0.66)
	for i in 3:
		Ui.image(self, "rock2", Rect2(r.position.x + i * 18, r.position.y - 14, 12, 14), true).modulate = Color(0.7, 0.68, 0.66)
	Ui.shade(self, Rect2(r.position.x + r.size.x / 2 - 3, r.position.y + 30, 6, 16), Color(0, 0, 0, 0.8))


func _house(r: Rect2, tex: String, roof: Color) -> void:
	Ui.image(self, tex, r, true).modulate = Color(0.85, 0.8, 0.75)
	_poly([r.position + Vector2(-12, 0), r.position + Vector2(r.size.x / 2, -60), r.position + Vector2(r.size.x + 12, 0)], roof)
	_poly([r.position + Vector2(-12, 0), r.position + Vector2(r.size.x + 12, 0), r.position + Vector2(r.size.x + 12, 6), r.position + Vector2(-12, 6)], roof.darkened(0.4))
	# windows
	for wx in [r.position.x + 18, r.end.x - 42]:
		Ui.frame(self, Rect2(wx, r.position.y + 70, 24, 26), Color("#e8b040"), Color("#3a2410"), 3)


func _sign(r: Rect2, text: String) -> void:
	Ui.frame(self, r, Color("#5a3a18"), Color("#d4a24a"), 2)
	Ui.label(self, text, r.position + Vector2(0, 3), 13, Ui.GOLD, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _door(r: Rect2, text: String, cb: Callable, tip: String, col: Color) -> void:
	var b := Ui.btn(self, text, r, cb, tip)
	var normal := StyleBoxFlat.new()
	normal.bg_color = col
	normal.border_color = Color("#1a1008")
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = int(r.size.x / 2)
	normal.corner_radius_top_right = int(r.size.x / 2)
	var hover := normal.duplicate()
	hover.bg_color = col.lightened(0.25)
	hover.border_color = Color("#e0b060")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.0))
	b.add_theme_color_override("font_hover_color", Ui.GOLD)


## The first time in Lehan: rumours of the council's job put the mines on the map.
func _hear_of_mines() -> void:
	Game.known.append("mines")
	await Game.main.message("In the market square a crier reads a notice from the council: miners have gone missing in the old workings above the town, and the council will pay well for anyone willing to look into it.\n\nThe Mines are now on your map.")


func _on_gate() -> void:
	if Game.party.is_empty():
		await Game.main.message("You have no characters in your party.\nMuster one at the inn first.")
		return
	Game.main.goto("world")


func _on_shop() -> void:
	Game.main.goto("shop")


func _on_inn() -> void:
	Game.main.goto("inn")


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")
