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
var strip := []      # [{slot, portrait, name, bars}]
var name_label: Label
var cls_label: Label
var race_label: Label
var log_label: Label


func _ready() -> void:
	var args: Dictionary = get_meta("args", {})
	from_party = args.get("party", true)
	list = Game.party if from_party else Game.roster
	index = args.get("index", 0)
	strip_first = index
	Ui.stone_background(self)

	Ui.btn(self, "Leave", Rect2(16, 20, 70, 30), _on_leave, "Back to the inn")
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

	# Statistics (ViewCha 70-94).
	Ui.frame(self, Rect2(8, 92, 228, 378))
	var rows := [["Strength", "str"], ["Dexterity", "dex"], ["Constitution", "con"], ["Intelligence", "int"],
		["Will", "wil"], ["Charisma", "cha"], ["Hits", "hits"], ["Health", "health"], ["Mana", "mana"],
		["Encumbrance", "enc"], ["Armour Class", "ac"], ["To Hit  R / L", "hit"], ["Damage  R / L", "dam"], ["Experience", "xp"]]
	for i in rows.size():
		var y := 100 + i * 26
		Ui.label(self, rows[i][0], Vector2(18, y), 13, Ui.TEXT)
		stat_labels[rows[i][1]] = Ui.label(self, "", Vector2(124, y), 14, Ui.GOLD, 104, HORIZONTAL_ALIGNMENT_RIGHT)

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

	log_label = Ui.label(self, "Drag items between the body, the backpack and other characters.", Vector2(244, 462), 11, Ui.DIM, 390)
	refresh()


func viewed() -> Dictionary:
	return list[index]


func refresh() -> void:
	var c := viewed()
	name_label.text = c.name
	cls_label.text = Game.CLASSES[c.cls]
	race_label.text = Game.RACES[c.race]
	stat_labels["str"].text = str(c.strength)
	stat_labels["dex"].text = str(c.dexterity)
	stat_labels["con"].text = str(c.constitution)
	stat_labels["int"].text = str(c.intelligence)
	stat_labels["wil"].text = str(c.will)
	stat_labels["cha"].text = str(c.charisma)
	stat_labels["hits"].text = "%d / %d" % [c.hits, c.max_hits]
	stat_labels["health"].text = "%d / %d" % [c.health, c.max_health]
	stat_labels["mana"].text = "%d / %d" % [c.magic, c.max_magic]
	var enc := Game.encumbrance(c)
	stat_labels["enc"].text = "%d / %d" % [enc, c.max_encum]
	stat_labels["enc"].add_theme_color_override("font_color", Ui.RED if enc > c.max_encum else Ui.GOLD)
	stat_labels["ac"].text = str(Game.armor_class(c))
	stat_labels["hit"].text = "%d / %d" % [Game.to_hit(c, Game.SLOT_RHAND), Game.to_hit(c, Game.SLOT_LHAND)]
	stat_labels["dam"].text = "%s / %s" % [Game.damage_string(c, Game.SLOT_RHAND), Game.damage_string(c, Game.SLOT_LHAND)]
	stat_labels["xp"].text = str(c.xp)
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


func _on_leave() -> void:
	Game.main.goto("inn")


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
			if await Game.main.confirm("Do you really want to throw away the %s?" % Game.item(id).name, "Throw away"):
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
