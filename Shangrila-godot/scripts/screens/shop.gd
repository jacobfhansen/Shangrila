extends Control
## Shop - drag items from the shelves into the basket, then pay.

const TALK := [
	"\"Welcome to the finest smithy in Lehan! Steel for every purse.\"",
	"\"Heading for the mines? Then you'll want something sharper than that.\"",
	"\"That bardiche? Forged it myself. Splits a helmet like kindling.\"",
	"\"The mines past the gate go deeper than anyone has mapped.\"",
]

var shop: Dictionary
var basket: Array = []     # [{id, n}]
var basket_slots := []
var basket_counts := []
var cost_label: Label
var purse_label: Label
var talk_label: Label
var party_boxes := []
var talk_i := 0


func _ready() -> void:
	shop = Game.city.shop
	Ui.stone_background(self)
	Ui.btn(self, "Leave", Rect2(12, 20, 50, 30), func(): Game.main.goto("streets", {"at": "smith"}), "Back out into the street")
	Ui.btn(self, "Haggle", Rect2(66, 20, 56, 30), _on_haggle, "Try to get a better price")
	Ui.btn(self, "Talk", Rect2(126, 20, 44, 30), _on_talk, "Talk to the smith")
	Ui.btn(self, "Sell ore", Rect2(12, 372, 156, 30), _on_sell_ore, "The smith buys the ore from the mines' new diggings")

	Ui.frame(self, Rect2(16, 62, 148, 121), Color(0, 0, 0, 0.6), Color("#a07a40"), 2)
	Ui.image(self, "The_Enemy", Rect2(20, 66, 140, 113))
	Ui.title(self, shop.name, Vector2(16, 188), 17, 148, HORIZONTAL_ALIGNMENT_CENTER)
	var p := Ui.parchment(self, Rect2(12, 216, 156, 150))
	talk_label = Label.new()
	talk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk_label.add_theme_color_override("font_color", Ui.INK)
	talk_label.add_theme_font_size_override("font_size", 12)
	talk_label.text = "Drag the wares you want into the basket, then press Pay."
	p.add_child(talk_label)
	Ui.place(talk_label, Rect2(10, 8, 136, 134))

	# Shelves: 3 x 4 (Shop 15-26).
	Ui.frame(self, Rect2(176, 20, 330, 292))
	var stock: Array = shop.stock
	for i in stock.size():
		var x := 186 + (i % 3) * 106
		var y := 30 + (i / 3) * 70
		var s := Slot.make(self, Rect2(x + 33, y, 40, 40), i, "shop", self)
		s.draggable = true
		s.item_id = stock[i]
		s.hint = "Drag into the basket to buy"
		var it := Game.item(stock[i])
		Ui.label(self, it.name, Vector2(x, y + 40), 11, Ui.TEXT, 106, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.label(self, Game.money_string(_price(stock[i])), Vector2(x, y + 54), 10, Ui.GOLD, 106, HORIZONTAL_ALIGNMENT_CENTER)

	# Basket (Shop 131-155).
	var area := Slot.make(self, Rect2(176, 320, 330, 150), -1, "basket", self)
	area.set_border(Color("#a07a40"), 2)
	Ui.label(self, "Basket", Vector2(186, 324), 14, Ui.GOLD)
	for i in 6:
		var s := Slot.make(self, Rect2(188 + i * 52, 348, 44, 44), i, "basket", self)
		s.hint = "Click to put one back"
		s.clicked.connect(_on_basket_click)
		basket_slots.append(s)
		basket_counts.append(Ui.label(self, "", Vector2(188 + i * 52, 394), 12, Ui.TEXT, 44, HORIZONTAL_ALIGNMENT_CENTER))
	cost_label = Ui.label(self, "", Vector2(188, 416), 12, Ui.TEXT, 210)
	purse_label = Ui.label(self, "", Vector2(188, 436), 12, Ui.TEXT, 210)
	Ui.btn(self, "Clear", Rect2(404, 412, 46, 48), _on_clear, "Empty the basket")
	Ui.btn(self, "Pay", Rect2(454, 412, 46, 48), _on_pay, "Buy everything in the basket")

	# Party and their purses (Shop 3-14, 113-130).
	for i in Game.party.size():
		var y := 16 + i * 76
		var c: Dictionary = Game.party[i]
		Ui.label(self, c.name, Vector2(518, y), 13, Ui.TEXT, 116)
		var por := Portrait.new()
		add_child(por)
		Ui.place(por, Rect2(518, y + 20, 40, 40))
		var lab := Ui.label(self, "", Vector2(566, y + 18), 11, Ui.TEXT, 70)
		party_boxes.append(lab)
		por.index = c.icon
	if Game.party.is_empty():
		Ui.label(self, "No party!\nMuster one\nat the inn.", Vector2(518, 20), 13, Ui.DIM)
	refresh()


func _price(id: int) -> int:
	return roundi(Game.item(id).price * float(shop.price_mod))


func _sum() -> int:
	var t := 0
	for b in basket:
		t += _price(b.id) * b.n
	return t


func refresh() -> void:
	for i in 6:
		if i < basket.size():
			basket_slots[i].item_id = basket[i].id
			basket_counts[i].text = "x%d" % basket[i].n
		else:
			basket_slots[i].item_id = 0
			basket_counts[i].text = ""
	cost_label.text = "Total cost:  " + Game.money_string(_sum())
	var purse := Game.party_silver()
	purse_label.text = "Party money: " + Game.money_string(purse)
	cost_label.add_theme_color_override("font_color", Ui.RED if _sum() > purse else Ui.TEXT)
	for i in party_boxes.size():
		var c: Dictionary = Game.party[i]
		party_boxes[i].text = "%d silver" % c.silver


func can_drop(s: Slot, data: Dictionary) -> bool:
	if s.kind != "basket" or data.from != "shop":
		return false
	for b in basket:
		if b.id == data.item:
			return true
	return basket.size() < 6


func drop(_s: Slot, data: Dictionary) -> void:
	for b in basket:
		if b.id == data.item:
			b.n += 1
			refresh()
			return
	basket.append({"id": data.item, "n": 1})
	refresh()


func _on_basket_click(s: Slot) -> void:
	if s.slot_id >= basket.size():
		return
	basket[s.slot_id].n -= 1
	if basket[s.slot_id].n <= 0:
		basket.remove_at(s.slot_id)
	refresh()


func _on_clear() -> void:
	basket.clear()
	refresh()


func _on_pay() -> void:
	if basket.is_empty():
		return
	if Game.party.is_empty():
		await Game.main.message("You have no party to carry the goods.")
		return
	var sum := _sum()
	if Game.party_silver() < sum:
		await Game.main.message("You can't afford that!")
		return
	var count := 0
	for b in basket:
		count += b.n
	var room := 0
	for c in Game.party:
		for k in range(Game.PACK_FIRST, Game.PACK_LAST + 1):
			if c.items[k] == 0:
				room += 1
	if room < count:
		await Game.main.message("Your backpacks are too full to carry all that.")
		return
	Game.pay(sum)
	for b in basket:
		for n in b.n:
			for c in Game.party:
				var k := Game.free_pack_slot(c)
				if k >= 0:
					c.items[k] = b.id
					break
	basket.clear()
	talk_label.text = "\"Pleasure doing business! The goods are in your backpacks.\""
	refresh()


## The smith buys Silver-Grey Ore from the mines (MinesQuest.ORE_ID) at its price, paid to whoever carries it.
func _on_sell_ore() -> void:
	var n := 0
	var paid := 0
	for c in Game.party:
		for k in range(1, 31):
			if c.items[k] == MinesQuest.ORE_ID:
				c.items[k] = 0
				var price := _price(MinesQuest.ORE_ID)
				Game.add_silver(c, price)
				n += 1
				paid += price
	if n == 0:
		talk_label.text = "\"Ore? Bring me some from those new diggings in the mines, and I'll pay a fair price.\""
	else:
		talk_label.text = "The smith weighs the ore in a big hand and whistles.\n\n\"Good stuff. %d silver for the lot.\"" % paid
	refresh()


func _on_talk() -> void:
	talk_label.text = TALK[talk_i % TALK.size()]
	talk_i += 1


func _on_haggle() -> void:
	var best := -99
	var who := ""
	for c in Game.party:
		if Game.ability(c, "talk") > best:
			best = Game.ability(c, "talk")
			who = c.name
	if who == "":
		talk_label.text = "\"Haggle with whom? You are alone.\""
	else:
		talk_label.text = "%s tries to haggle (Talk %d).\n\n\"My prices are fair, friend. Take it or leave it.\"" % [who, best]


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE and not Game.main.modal_open:
		get_viewport().set_input_as_handled()
		Game.main.goto("streets", {"at": "smith"})
