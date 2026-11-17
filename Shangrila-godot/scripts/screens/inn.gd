extends Control
## AssmParty - the inn where characters are created and the party is assembled.

const ROWS := 10

var scroll := 0
var chosen := -1      # index into Game.roster
var member := -1      # index into Game.party

var member_boxes := []   # [{btn, portrait, name, cls, bars}]
var roster_rows := []    # [{btn, name, cls}]
var gold_label: Label
var cmd := {}


func _ready() -> void:
	Ui.stone_background(self)
	Ui.btn(self, "Leave Inn", Rect2(20, 20, 206, 28), _on_leave, "Back out into the town")
	Ui.btn(self, "Save", Rect2(20, 54, 100, 28), _on_save, "Save the game")
	Ui.btn(self, "Quit", Rect2(126, 54, 100, 28), _on_quit, "Back to the main menu")

	Ui.title(self, "The Inn", Vector2(250, 26), 30)
	Ui.label(self, "of " + Game.city.name, Vector2(254, 64), 14, Ui.DIM)
	gold_label = Ui.label(self, "", Vector2(250, 92), 12, Ui.TEXT)
	Ui.frame(self, Rect2(464, 34, 148, 121), Color(0, 0, 0, 0.6), Color("#a07a40"), 2)
	Ui.image(self, "The_Man", Rect2(468, 38, 140, 113))

	# Party, two columns of three (AssmParty 35-55).
	Ui.frame(self, Rect2(14, 128, 330, 340))
	Ui.label(self, "Party", Vector2(24, 132), 15, Ui.GOLD)
	for i in Game.MAX_PARTY:
		var x := 26 + (i % 2) * 160
		var y := 158 + (i / 2) * 102
		var name_l := Ui.label(self, "", Vector2(x, y), 13, Ui.TEXT, 150)
		var cls_l := Ui.label(self, "", Vector2(x, y + 74), 11, Ui.DIM, 150)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		add_child(b)
		Ui.place(b, Rect2(x, y + 20, 52, 52))
		b.pressed.connect(_on_member.bind(i))
		var p := Portrait.new()
		b.add_child(p)
		Ui.place(p, Rect2(2, 2, 48, 48))
		var bars := StatusBars.new()
		add_child(bars)
		Ui.place(bars, Rect2(x + 60, y + 20, 66, 52))
		member_boxes.append({"btn": b, "portrait": p, "name": name_l, "cls": cls_l, "bars": bars})

	# Command column.
	cmd.up = Ui.btn(self, "Up", Rect2(354, 160, 76, 30), _on_scroll.bind(-1), "Scroll the list up")
	cmd.down = Ui.btn(self, "Down", Rect2(354, 196, 76, 30), _on_scroll.bind(1), "Scroll the list down")
	cmd.muster = Ui.btn(self, "Muster", Rect2(354, 250, 76, 30), _on_muster, "Add the chosen character to the party")
	cmd.dismiss = Ui.btn(self, "Dismiss", Rect2(354, 286, 76, 30), _on_dismiss, "Send the chosen party member back to the inn")
	cmd.info = Ui.btn(self, "Info", Rect2(354, 340, 76, 30), _on_info, "View character and inventory")
	cmd.kill = Ui.btn(self, "Kill", Rect2(354, 394, 76, 30), _on_kill, "Delete the chosen character")

	# Roster list (AssmParty 14-33).
	Ui.frame(self, Rect2(440, 164, 190, 304))
	Ui.label(self, "Characters", Vector2(450, 168), 15, Ui.GOLD)
	for r in ROWS:
		var y := 192 + r * 27
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		add_child(b)
		Ui.place(b, Rect2(446, y, 178, 25))
		b.pressed.connect(_on_row.bind(r))
		var n := Ui.label(b, "", Vector2(4, 3), 13, Ui.TEXT, 96)
		var c := Ui.label(b, "", Vector2(104, 4), 11, Ui.DIM, 72)
		roster_rows.append({"btn": b, "name": n, "cls": c})
	refresh()
	if get_meta("args", {}).get("split", false):
		_split_notice.call_deferred()


func _split_notice() -> void:
	await Game.main.message("The company has split up. Your old companions are here at the inn.\n\nThey won't come without a job. Find work first (the market square is where news is cried), then choose one here and press Muster to talk them round.")


func refresh() -> void:
	scroll = clampi(scroll, 0, maxi(0, Game.roster.size() - ROWS))
	if chosen >= Game.roster.size():
		chosen = -1
	if member >= Game.party.size():
		member = -1
	for i in Game.MAX_PARTY:
		var mb: Dictionary = member_boxes[i]
		var has := i < Game.party.size()
		mb.btn.visible = has
		mb.bars.visible = has
		if has:
			var c: Dictionary = Game.party[i]
			mb.name.text = c.name
			mb.cls.text = "%s %s" % [Game.RACES[c.race], Game.CLASSES[c.cls]]
			mb.portrait.index = c.icon
			mb.portrait.highlight = i == member
			mb.bars.who = c
		else:
			mb.name.text = "- empty -"
			mb.cls.text = ""
		mb.name.add_theme_color_override("font_color", Ui.RED if i == member else (Ui.TEXT if has else Ui.DIM))
	for r in ROWS:
		var row: Dictionary = roster_rows[r]
		var idx := scroll + r
		if idx < Game.roster.size():
			var c: Dictionary = Game.roster[idx]
			row.name.text = c.name
			row.cls.text = Game.CLASSES[c.cls]
			row.btn.disabled = false
		else:
			row.name.text = "<empty>"
			row.cls.text = ""
			row.btn.disabled = true
		var col := Ui.RED if idx == chosen else Ui.TEXT
		row.name.add_theme_color_override("font_color", col if idx < Game.roster.size() else Ui.DIM)
		row.cls.add_theme_color_override("font_color", col if idx == chosen else Ui.DIM)
	cmd.up.disabled = scroll == 0
	cmd.down.disabled = scroll >= Game.roster.size() - ROWS
	cmd.muster.disabled = chosen < 0 or Game.party.size() >= Game.MAX_PARTY
	cmd.dismiss.disabled = member < 0 or Game.roster.size() >= Game.MAX_ROSTER
	cmd.info.disabled = chosen < 0 and member < 0
	cmd.kill.disabled = chosen < 0
	gold_label.text = "Party purse: " + Game.money_string(Game.party_silver())


func _on_member(i: int) -> void:
	chosen = -1
	member = -1 if member == i else i
	refresh()


func _on_row(r: int) -> void:
	member = -1
	var idx := scroll + r
	chosen = -1 if chosen == idx else idx
	refresh()


func _on_scroll(d: int) -> void:
	scroll += d
	refresh()


func _on_muster() -> void:
	var c: Dictionary = Game.roster[chosen]
	if c.get("rejoin", "") != "":
		if not await _rejoin_talk(c):
			refresh()
			return
		c.erase("rejoin")
		c.erase("grudge")
		c.erase("owed")
	Game.party.append(c)
	Game.roster.erase(c)
	chosen = -1
	refresh()


## A companion who left after the split must be talked round before they join again.
## Plays a short conversation over the inn; returns true if they agree.
func _rejoin_talk(c: Dictionary) -> bool:
	var key := ""
	for k in PrologueData.ORDER:
		if PrologueData.CAST[k].name == c.name:
			key = k
	if key == "":
		return true
	var host: String = Game.story.get("host", "")
	if not LehanData.has_job():
		await Game.main.message("%s: \"%s\"\n\n%s" % [c.name.split(" ")[0], LehanData.no_job_line(key, c, host), LehanData.NO_JOB_HINT])
		return false
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.6)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	Ui.place(ov, Rect2(0, 0, 640, 480))
	Ui.frame(ov, Rect2(10, 110, 620, 280), Color("#1a120a"), Color("#a07a40"), 2)
	Ui.label(ov, "Talking to " + c.name, Vector2(20, 86), 15, Ui.GOLD)
	var box := DialogueBox.new()
	box.cast = PrologueData.company_cast()
	box.host = host
	ov.add_child(box)
	Ui.place(box, Rect2(20, 120, 600, 260))
	var result := {"join": false}
	box.effect.connect(func(fx: String):
		if fx == "join":
			result.join = true
		elif fx.begins_with("pay:"):
			Game.pay(int(fx.substr(4)))
			refresh())
	box.play(LehanData.rejoin_talk(key, c, host, Game.party_silver()))
	await box.finished
	var label := "%s joins the party" % c.name.split(" ")[0] if result.join else "Maybe later"
	box.show_buttons([[label, func(): box.finished.emit()]])
	await box.finished
	ov.queue_free()
	return result.join


func _on_dismiss() -> void:
	Game.roster.append(Game.party[member])
	Game.party.remove_at(member)
	member = -1
	refresh()


func _on_info() -> void:
	if member >= 0:
		Game.main.goto("view", {"party": true, "index": member})
	elif chosen >= 0:
		Game.main.goto("view", {"party": false, "index": chosen})


func _on_kill() -> void:
	var c: Dictionary = Game.roster[chosen]
	if await Game.main.confirm("Do you really want to kill %s?\nThis cannot be undone." % c.name, "Kill"):
		Game.roster.remove_at(chosen)
		chosen = -1
		refresh()


func _on_leave() -> void:
	Game.main.goto("town")


func _on_save() -> void:
	if Game.save_game("inn"):
		await Game.main.message("The game has been saved.")
	else:
		await Game.main.message("Could not save the game.")


func _on_quit() -> void:
	if await Game.main.confirm("Do you really want to quit to the main menu?\nUnsaved progress will be lost."):
		Game.main.goto("title")
