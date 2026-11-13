extends Control
## CreateCha - roll a character, pick race, portrait and class.

const STAT_ROWS := [
	["Strength", "strength"], ["Dexterity", "dexterity"], ["Constitution", "constitution"],
	["Intelligence", "intelligence"], ["Will Power", "will"], ["Charisma", "charisma"],
	["Hit Points", "max_hits"], ["Endurance", "max_health"], ["Mana", "max_magic"],
]

var c: Dictionary
var portrait: Portrait
var race_label: Label
var stat_values := {}
var money_values := []
var class_btns := []
var skill_values := []
var accept: Button
var hint: Label


func _ready() -> void:
	c = Game.blank_character()
	Ui.stone_background(self)

	# Portrait chooser (CreateCha 3-6).
	Ui.btn(self, "<", Rect2(20, 20, 26, 64), _on_portrait.bind(-1), "Previous portrait")
	portrait = Portrait.new()
	add_child(portrait)
	Ui.place(portrait, Rect2(52, 20, 64, 64))
	Ui.btn(self, ">", Rect2(122, 20, 26, 64), _on_portrait.bind(1), "Next portrait")

	# Race (CreateCha 10-15).
	Ui.btn(self, "▲", Rect2(20, 94, 24, 18), _on_race.bind(1), "Next race")
	Ui.btn(self, "▼", Rect2(20, 114, 24, 18), _on_race.bind(-1), "Previous race")
	race_label = Ui.label(self, "", Vector2(52, 100), 16, Ui.GOLD, 120)

	Ui.frame(self, Rect2(14, 138, 176, 286))
	for i in STAT_ROWS.size():
		var y := 146 + i * 22
		if i >= 6:
			y += 8
		Ui.label(self, STAT_ROWS[i][0], Vector2(24, y), 13, Ui.TEXT)
		stat_values[STAT_ROWS[i][1]] = Ui.label(self, "", Vector2(130, y), 14, Ui.GOLD, 48, HORIZONTAL_ALIGNMENT_RIGHT)
	var coins := ["Gold_Coin", "Silver_Coin", "Copper_Coin"]
	for i in 3:
		var y := 356 + i * 22
		Ui.image(self, coins[i], Rect2(24, y, 22, 19))
		Ui.label(self, ["Gold", "Silver", "Copper"][i], Vector2(52, y + 1), 13, Ui.TEXT)
		money_values.append(Ui.label(self, "", Vector2(130, y + 1), 14, Ui.GOLD, 48, HORIZONTAL_ALIGNMENT_RIGHT))

	# Class buttons (CreateCha 23-30).
	for k in 8:
		var b := Ui.btn(self, Game.CLASSES[k], Rect2(204 + (k % 4) * 106, 20 + (k / 4) * 41, 99, 32), _on_class.bind(k))
		b.toggle_mode = true
		class_btns.append(b)

	# Skills (CreateCha 31-52).
	Ui.frame(self, Rect2(200, 106, 430, 236))
	Ui.label(self, "Skills", Vector2(212, 110), 15, Ui.GOLD)
	var cols := [[0, 8, 212], [8, 15, 352], [15, 22, 492]]
	for col in cols:
		for s in range(col[0], col[1]):
			var y: int = 138 + (s - col[0]) * 24
			Ui.label(self, Game.SKILLS[s], Vector2(col[2], y), 12, Ui.TEXT)
			skill_values.append(Ui.label(self, "", Vector2(col[2] + 88, y), 13, Ui.GOLD, 38, HORIZONTAL_ALIGNMENT_RIGHT))

	hint = Ui.label(self, "", Vector2(200, 356), 13, Ui.DIM, 430, HORIZONTAL_ALIGNMENT_CENTER)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size.y = 60

	Ui.btn(self, "Close", Rect2(16, 436, 90, 32), func(): Game.main.goto("inn"), "Back to the inn")
	Ui.btn(self, "Reroll", Rect2(275, 436, 90, 32), _on_reroll, "Roll the dice for new statistics")
	accept = Ui.btn(self, "Accept", Rect2(534, 436, 90, 32), _on_accept, "Name the character and add it to the inn")
	refresh()


func refresh() -> void:
	portrait.index = c.icon
	race_label.text = Game.RACES[c.race]
	var rolled: bool = c.strength != 0
	for k in stat_values:
		stat_values[k].text = str(c[k]) if rolled else ""
	var money := [c.gold, c.silver, c.copper]
	for i in 3:
		money_values[i].text = str(money[i]) if rolled else ""
	for k in 8:
		class_btns[k].disabled = not Game.class_allowed(c, k)
		class_btns[k].set_pressed_no_signal(k == c.cls)
	for s in 22:
		skill_values[s].text = str(c.skills[s]) if c.cls != Game.NO_CLASS else ""
	accept.disabled = c.cls == Game.NO_CLASS
	if not rolled:
		hint.text = Game.RACE_INFO[c.race] + " Choose race and portrait, then press Reroll to roll the dice."
	elif c.cls == Game.NO_CLASS:
		var any := false
		for k in 8:
			any = any or Game.class_allowed(c, k)
		hint.text = "Choose a class." if any else "These rolls do not qualify for any class. Reroll!"
	else:
		hint.text = "A %s %s. Starting equipment is in the backpack. Accept when ready." % [Game.RACES[c.race], Game.CLASSES[c.cls]]


func _clear_class() -> void:
	c.cls = Game.NO_CLASS
	for i in range(Game.PACK_FIRST, Game.PACK_FIRST + 6):
		c.items[i] = 0
	for s in 22:
		c.skills[s] = -25


func _on_portrait(d: int) -> void:
	c.icon = posmod(c.icon + d, Game.PORTRAITS)
	refresh()


func _on_race(d: int) -> void:
	c.race = posmod(c.race + d, Game.RACES.size())
	# Changing race throws the rolls away, as in the original.
	for k in ["strength", "dexterity", "constitution", "intelligence", "will", "charisma", "max_hits", "hits", "max_health", "health", "gold", "silver", "copper"]:
		c[k] = 0
	_clear_class()
	refresh()


func _on_reroll() -> void:
	Game.roll_character(c)
	_clear_class()
	refresh()


func _on_class(k: int) -> void:
	if Game.class_allowed(c, k):
		Game.set_class(c, k)
	refresh()


func _on_accept() -> void:
	var nm: String = await Game.main.ask_name()
	Game.finish_character(c, nm)
	Game.roster.append(c)
	Game.main.goto("inn")
