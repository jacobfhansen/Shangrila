extends Control
## ViewCha - character sheet with equipment and backpack. Items are moved by drag & drop;
## drop on the eye for info, on the mouth to eat, on the trash to throw away, or on another
## character's portrait to hand it over.

## slot -> [rect, caption]
const BODY_SLOTS := {
	1: [Rect2(392, 128, 36, 36), "Head"],
	2: [Rect2(448, 164, 36, 36), "Neck"],
	3: [Rect2(392, 184, 36, 36), "Chest"],
	4: [Rect2(336, 184, 36, 36), "Arms"],
	5: [Rect2(392, 240, 36, 36), "Belt"],
	6: [Rect2(312, 262, 36, 36), "Right\nhand"],
	7: [Rect2(472, 262, 36, 36), "Left\nhand"],
	8: [Rect2(392, 304, 36, 36), "Legs"],
	9: [Rect2(392, 404, 36, 36), "Feet"],
	28: [Rect2(300, 318, 30, 30), "Ring"],
	29: [Rect2(490, 318, 30, 30), "Ring"],
	30: [Rect2(500, 120, 36, 36), "Quiver"],
}

var from_party := true
var list: Array
var index := 0
var strip_first := 0

var slots := {}
var stat_labels := {}
var ability_rows := {}   # key -> {name, pips, plus, hover}
var strip := []      # [{slot, portrait, name, bars}]
var name_label: Label
var cls_label: Label
var race_label: Label
var log_label: Label
var back := "inn"         # the screen Leave returns to (args "back", "back_args")
var back_args := {}


func _ready() -> void:
	var args: Dictionary = get_meta("args", {})
	from_party = args.get("party", true)
	list = Game.party if from_party else Game.roster
	index = args.get("index", 0)
	strip_first = index
	Ui.stone_background(self)

	back = args.get("back", "inn")
	back_args = args.get("back_args", {})
	Ui.btn(self, "Leave", Rect2(16, 20, 70, 30), _on_leave, {"inn": "Back to the inn", "dungeon": "Back to the mines", "tunnels": "Back to the tunnels"}.get(back, "Back to the streets"))
	Ui.btn(self, "Quests", Rect2(16, 56, 70, 28), QuestLog.open, "The quest log: every quest and what was said (J)")
	# Character strip (ViewCha 110-118).
	for j in 3:
		var x := 104 + j * 158
		var n := Ui.label(self, "", Vector2(x, 12), 13, Ui.TEXT, 140)
		var s := Slot.make(self, Rect2(x, 32, 46, 46), j, "member", self)
		s.clicked.connect(_on_strip_click)
		var p := Portrait.new()
		s.add_child(p)
		Ui.place(p, Rect2(1, 1, 44, 44))
		var bars := StatusBars.new()
		add_child(bars)
		Ui.place(bars, Rect2(x + 54, 32, 60, 46))
		strip.append({"slot": s, "portrait": p, "name": n, "bars": bars})
	Ui.btn(self, "◀", Rect2(584, 18, 42, 28), _on_strip_scroll.bind(-1), "Previous character")
	Ui.btn(self, "▶", Rect2(584, 50, 42, 28), _on_strip_scroll.bind(1), "Next character")

	# Abilities (0-10, shown as pips) with a button to raise each one, then the derived values.
	Ui.frame(self, Rect2(8, 92, 228, 378))
	for i in Game.ABILITIES.size():
		var k: String = Game.ABILITIES[i]
		var y := 98 + i * 20
		var hover := Control.new()
		hover.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(hover)
		Ui.place(hover, Rect2(14, y, 180, 20))
		var nl := Ui.label(self, Game.ABILITY_NAMES[k], Vector2(18, y + 1), 12, Ui.TEXT)
		var pips := _Pips.new()
		add_child(pips)
		Ui.place(pips, Rect2(122, y + 6, 70, 8))
		var plus := Ui.btn(self, "+", Rect2(200, y + 1, 26, 18), _on_raise.bind(k))
		plus.add_theme_font_size_override("font_size", 12)
		ability_rows[k] = {"name": nl, "pips": pips, "plus": plus, "hover": hover}
	var rows := [["Hits", "hits"], ["Health", "health"], ["Mana", "mana"], ["Encumbrance", "enc"],
		["Armour", "ac"], ["To Hit  R / L", "hit"], ["Damage  R / L", "dam"], ["Power", "power"],
		["Experience earned", "xp_total"], ["Unspent", "xp"], ["Silver", "silver"]]
	for i in rows.size():
		var y := 302 + i * 15.3
		Ui.label(self, rows[i][0], Vector2(18, y), 12, Ui.DIM)
		stat_labels[rows[i][1]] = Ui.label(self, "", Vector2(124, y), 13, Ui.GOLD, 104, HORIZONTAL_ALIGNMENT_RIGHT)

	name_label = Ui.title(self, "", Vector2(250, 88), 20)
	cls_label = Ui.label(self, "", Vector2(400, 94), 14, Ui.TEXT, 100)
	race_label = Ui.label(self, "", Vector2(500, 94), 14, Ui.TEXT, 80)

	var body := _Body.new()
	add_child(body)
	Ui.place(body, Rect2(290, 120, 260, 340))
	for k in BODY_SLOTS:
		var s := Slot.make(self, BODY_SLOTS[k][0], k, "equip", self)
		s.draggable = true
		s.caption = BODY_SLOTS[k][1]
		s.hint = BODY_SLOTS[k][1].replace("\n", " ")
		slots[k] = s

	# Info / eat / trash (ViewCha 42, 43, 47).
	var eye := Slot.make(self, Rect2(246, 128, 40, 40), -1, "eye", self)
	eye.caption = "Info"
	eye.hint = "Drop an item here to examine it"
	var mouth := Slot.make(self, Rect2(246, 180, 40, 40), -2, "mouth", self)
	mouth.caption = "Eat"
	mouth.hint = "Drop food here to eat it"
	var trash := Slot.make(self, Rect2(246, 420, 40, 40), -4, "trash", self)
	trash.caption = "Trash"
	trash.hint = "Drop an item here to throw it away"
	trash.set_border(Color("#8a3020"))

	# Backpack (ViewCha 10-27).
	Ui.label(self, "Backpack", Vector2(556, 90), 13, Ui.GOLD)
	for i in 18:
		var k := Game.PACK_FIRST + i
		var s := Slot.make(self, Rect2(556 + (i % 2) * 38, 110 + (i / 2) * 38, 36, 36), k, "pack", self)
		s.draggable = true
		s.hint = "Backpack"
		slots[k] = s

	log_label = Ui.label(self, "Drag items to move them. + spends experience on an ability.", Vector2(244, 462), 11, Ui.DIM, 390)
	refresh()


func viewed() -> Dictionary:
	return list[index]


func refresh() -> void:
	var c := viewed()
	name_label.text = c.name
	cls_label.text = Game.CLASSES[c.cls]
	race_label.text = Game.RACES[c.race]
	for k in ability_rows:
		var row: Dictionary = ability_rows[k]
		var v := Game.ability(c, k)
		var fav := Game.is_favoured(c, k)
		var cost := Game.raise_cost(c, k)
		row.pips.value = v
		row.name.add_theme_color_override("font_color", Ui.GOLD if fav else Ui.TEXT)
		row.plus.disabled = cost < 0 or c.xp < cost
		var tip := "%s %d / %d%s\n%s" % [Game.ABILITY_NAMES[k], v, Game.MAX_ABILITY,
			" (favoured by the %s class)" % Game.CLASSES[c.cls] if fav else "", Game.ABILITY_INFO[k]]
		if cost >= 0:
			tip += "\nRaising it to %d costs %d experience." % [v + 1, cost]
		row.hover.tooltip_text = tip
		row.plus.tooltip_text = tip
	stat_labels["hits"].text = "%d / %d" % [c.hits, c.max_hits]
	stat_labels["health"].text = "%d / %d" % [c.health, c.max_health]
	stat_labels["mana"].text = "%d / %d" % [c.magic, c.max_magic]
	var enc := Game.encumbrance(c)
	stat_labels["enc"].text = "%d / %d" % [enc, c.max_encum]
	stat_labels["enc"].add_theme_color_override("font_color", Ui.RED if enc > c.max_encum else Ui.GOLD)
	stat_labels["ac"].text = str(Game.armor(c))
	stat_labels["hit"].text = "%d / %d" % [Game.to_hit(c, Game.SLOT_RHAND), Game.to_hit(c, Game.SLOT_LHAND)]
	stat_labels["dam"].text = "%s / %s" % [Game.damage_string(c, Game.SLOT_RHAND), Game.damage_string(c, Game.SLOT_LHAND)]
	var pl: Label = stat_labels["power"]
	var best := Game.best_fighting(c)
	pl.text = str(Game.power(c))
	pl.mouse_filter = Control.MOUSE_FILTER_PASS
	var other := Game.other_raises(c)
	pl.tooltip_text = ("How far %s has come: best fighting ability (%s %d) + Toughness %d + 1 for every 2 other raises bought (%d so far).\n"
		+ "Fights against monsters above this pay more experience, those below pay less, and three or more levels below pay nothing.") % [
		c.name.split(" ")[0], Game.ABILITY_NAMES[best], Game.ability(c, best), Game.ability(c, "toughness"), other]
	# Experience: earned in all, and what is left to spend on abilities (the + buttons; a gold star
	# on the portrait when it is enough for a raise).
	var tl: Label = stat_labels["xp_total"]
	tl.text = str(c.get("xp_total", c.xp))
	tl.mouse_filter = Control.MOUSE_FILTER_PASS
	tl.tooltip_text = "All the experience %s has earned, from fights and the story: %d spent on abilities, %d left to spend." % [
		c.name.split(" ")[0], int(c.get("xp_total", c.xp)) - c.xp, c.xp]
	var xl: Label = stat_labels["xp"]
	xl.text = str(c.xp)
	xl.mouse_filter = Control.MOUSE_FILTER_PASS
	xl.tooltip_text = "Experience left to spend on abilities with the + buttons.%s" % (
		" Enough for a raise: see the gold star on the portrait." if Game.can_raise(c) else "")
	stat_labels["silver"].text = str(c.silver)
	for k in slots:
		slots[k].item_id = c.items[k]
	# Strip of three characters, starting at strip_first, wrapping around.
	var n := list.size()
	for j in 3:
		var e: Dictionary = strip[j]
		var shown := j < n
		e.slot.visible = shown
		e.bars.visible = shown
		e.name.visible = shown
		if shown:
			var who: Dictionary = list[(strip_first + j) % n]
			e.name.text = who.name
			e.portrait.index = who.icon
			e.portrait.highlight = (strip_first + j) % n == index
			e.portrait.star = Game.can_raise(who)
			e.bars.who = who
			e.name.add_theme_color_override("font_color", Ui.RED if (strip_first + j) % n == index else Ui.TEXT)


func _strip_char(j: int) -> int:
	return (strip_first + j) % list.size()


func _on_strip_click(s: Slot) -> void:
	index = _strip_char(s.slot_id)
	refresh()


func _on_strip_scroll(d: int) -> void:
	strip_first = posmod(strip_first + d, list.size())
	refresh()


func _on_raise(key: String) -> void:
	var c := viewed()
	var cost := Game.raise_cost(c, key)
	if Game.raise_ability(c, key):
		log_label.text = "%s spends %d experience: %s is now %d." % [c.name, cost, Game.ABILITY_NAMES[key], Game.ability(c, key)]
	refresh()


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo) or Game.main.modal_open:
		return
	if e.keycode == KEY_J:
		QuestLog.open()
		get_viewport().set_input_as_handled()
	elif e.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_leave()


func _on_leave() -> void:
	Game.main.goto(back, back_args)


# ---------------------------------------------------------------- drag & drop

func can_drop(s: Slot, data: Dictionary) -> bool:
	if data.from != "equip" and data.from != "pack":
		return false
	var id: int = data.item
	match s.kind:
		"equip", "pack":
			return s.slot_id != data.src and s.item_id == 0 and Game.fits(id, s.slot_id)
		"eye", "trash":
			return true
		"mouth":
			return Game.item(id).food
		"member":
			return s.slot_id < list.size() and _strip_char(s.slot_id) != index
	return false


func drop(s: Slot, data: Dictionary) -> void:
	var c := viewed()
	var id: int = data.item
	var src: int = data.src
	match s.kind:
		"equip", "pack":
			c.items[s.slot_id] = id
			c.items[src] = 0
			log_label.text = "%s: %s moved." % [c.name, Game.item(id).name]
		"eye":
			await Game.main.show_item(id)
		"mouth":
			log_label.text = Game.eat(c, id)
			c.items[src] = 0
		"trash":
			if Game.is_quest_item(id):
				log_label.text = "%s is a quest item (★): it can't be thrown away." % Game.item(id).name
			elif await Game.main.confirm("Do you really want to throw away the %s?" % Game.item(id).name, "Throw away"):
				c.items[src] = 0
				log_label.text = "%s threw away the %s." % [c.name, Game.item(id).name]
		"member":
			var other: Dictionary = list[_strip_char(s.slot_id)]
			var free := Game.free_pack_slot(other)
			if free < 0:
				log_label.text = "%s has no room in the backpack." % other.name
			else:
				other.items[free] = id
				c.items[src] = 0
				log_label.text = "%s gave the %s to %s." % [c.name, Game.item(id).name, other.name]
	refresh()


## Ten pips for an ability's value: filled up to the value, the rest hollow.
class _Pips:
	extends Control
	var value := 0:
		set(v):
			value = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in Game.MAX_ABILITY:
			var p := Vector2(3.5 + i * 7, 4)
			if i < value:
				draw_circle(p, 3, Ui.GOLD)
			else:
				draw_arc(p, 2.5, 0, TAU, 12, Color(0.66, 0.6, 0.47, 0.6), 1.0)


## Faint figure behind the equipment slots (stands in for the "Character Map" picture).
class _Body:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := Color(0.85, 0.7, 0.45, 0.16)
		var o := Vector2(-290, -120)   # draw in screen coordinates
		draw_circle(Vector2(410, 146) + o, 24, col)
		var pts := PackedVector2Array([Vector2(372, 178), Vector2(448, 178), Vector2(440, 290), Vector2(380, 290)])
		for i in pts.size():
			pts[i] += o
		draw_colored_polygon(pts, col)
		draw_line(Vector2(376, 186) + o, Vector2(330, 280) + o, col, 14)
		draw_line(Vector2(444, 186) + o, Vector2(490, 280) + o, col, 14)
		draw_line(Vector2(395, 288) + o, Vector2(400, 420) + o, col, 16)
		draw_line(Vector2(425, 288) + o, Vector2(420, 420) + o, col, 16)
