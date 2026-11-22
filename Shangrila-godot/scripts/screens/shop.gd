extends Control
## Shop - the weapon smith. Buy: drag wares from the shelves into the basket, then pay.
## Sell: the shelves show what the party carries in their packs that a smith deals in (weapons,
## bows, arrows, quivers, armour and shields, and the ore from the mines); click sells one, Shift-click
## the whole stack. Haggle: the best talker in the party tries once a day for better prices both
## ways. Talk: rumours and hints that fit how far the story has come.

const SELL_SHARE := 0.5     # the smith pays half an item's price (the ore: all of it)
const HAGGLE_GOOD := 0.1    # Talk against NORMAL: 10% better prices for the day
const HAGGLE_GREAT := 0.2   # Talk against HARD: 20%

const FLAVOUR := [
	"\"Welcome to the finest smithy in Lehan! Steel for every purse.\"",
	"\"That bardiche? Forged it myself. Splits a helmet like kindling.\"",
	"\"A knife's a tool, a sword's a promise. Buy the one you mean to keep.\"",
]
const BEFORE_JOB := [
	"\"Heard the crier? The mines past the gate have gone quiet. Six miners down there, and nobody's come up.\"",
	"\"The council will pay for anyone who goes after those miners. Talk to them at the council house.\"",
]
const MINES := [
	"\"Going down? Take a lamp. Bad air pools in the new diggings, and a flame shows where it thins.\"",
	"\"The old foremen flooded galleries to keep the water off the seam. Always the top gate first, then the drain. Get that backwards and it all comes back.\"",
	"\"If you find silver-grey ore down there, bring it to me. I pay well for it.\"",
	"\"My grandfather swore the deepest galleries are older than Lehan. Fitted stone. No miner cut that.\"",
]
const AFTER := [
	"\"The marsh-folk? Thuug, out past the causeway, three days' walk. They trade a strange dark iron. Never seen a forge like theirs.\"",
	"\"You brought those miners home. The whole street's talking about it. Steel's a little cheaper for friends of Lehan.\"",
]

var shop: Dictionary
var shop_key := "smith"    # "smith" (Lehan, Game.city.shop) or "marsh" (Hett's stall, MarshData.TRADER)
var back: Array            # [screen, args] for Leave
var selling := false
var basket: Array = []     # [{id, n}]
var basket_slots := []
var basket_counts := []
var basket_box: Control
var shelf: Control
var cost_label: Label
var purse_label: Label
var talk_label: Label
var party_boxes := []
var mode_btn: Button
var haggle_btn: Button
var talk_i := 0


func _ready() -> void:
	shop_key = get_meta("args", {}).get("shop", "smith")
	shop = MarshData.TRADER if shop_key == "marsh" else Game.city.shop
	back = shop.get("back", ["streets", {"at": "smith"}])
	Ui.stone_background(self)
	Ui.btn(self, "Leave", Rect2(12, 20, 50, 30), _leave, "Back outside")
	haggle_btn = Ui.btn(self, "Haggle", Rect2(66, 20, 56, 30), _on_haggle, "")
	Ui.btn(self, "Talk", Rect2(126, 20, 44, 30), _on_talk, "Talk to the smith: news and advice")
	mode_btn = Ui.btn(self, "Sell", Rect2(12, 372, 156, 30), _on_mode, "")

	Ui.frame(self, Rect2(16, 62, 148, 121), Color(0, 0, 0, 0.6), Color("#a07a40"), 2)
	if shop_key == "marsh":
		var por := RacePortrait.new()
		por.race = MarshData.HETT.race
		por.look = MarshData.HETT.look
		add_child(por)
		Ui.place(por, Rect2(46, 66, 88, 113))
	else:
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

	Ui.frame(self, Rect2(176, 20, 330, 292))
	shelf = Control.new()
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shelf)
	Ui.place(shelf, Rect2(0, 0, 640, 480))

	# Basket (Shop 131-155).
	basket_box = Control.new()
	basket_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(basket_box)
	Ui.place(basket_box, Rect2(0, 0, 640, 480))
	var area := Slot.make(basket_box, Rect2(176, 320, 330, 150), -1, "basket", self)
	area.set_border(Color("#a07a40"), 2)
	Ui.label(basket_box, "Basket", Vector2(186, 324), 14, Ui.GOLD)
	for i in 6:
		var s := Slot.make(basket_box, Rect2(188 + i * 52, 348, 44, 44), i, "basket", self)
		s.hint = "Click to put one back"
		s.clicked.connect(_on_basket_click)
		basket_slots.append(s)
		basket_counts.append(Ui.label(basket_box, "", Vector2(188 + i * 52, 394), 12, Ui.TEXT, 44, HORIZONTAL_ALIGNMENT_CENTER))
	cost_label = Ui.label(basket_box, "", Vector2(188, 416), 12, Ui.TEXT, 210)
	Ui.btn(basket_box, "Clear", Rect2(404, 412, 46, 48), _on_clear, "Empty the basket")
	Ui.btn(basket_box, "Pay", Rect2(454, 412, 46, 48), _on_pay, "Buy everything in the basket")
	purse_label = Ui.label(self, "", Vector2(188, 436), 12, Ui.TEXT, 210)

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
	_build_shelves()
	refresh()


# ---------------------------------------------------------------- prices

## Today's haggled deal: 0, HAGGLE_GOOD or HAGGLE_GREAT (-1: tried today and failed).
func _deal() -> float:
	var h: Dictionary = Game.story.get(_haggle_key(), {})
	if int(h.get("day", -1)) != Game.day:
		return 0.0
	return maxf(0.0, float(h.get("deal", 0.0)))


func _haggled_today() -> bool:
	return int(Game.story.get(_haggle_key(), {}).get("day", -1)) == Game.day


func _haggle_key() -> String:
	return "haggle" if shop_key == "smith" else "haggle_" + shop_key


func _leave() -> void:
	Game.main.goto(back[0], back[1])


## "the smith" / "Hett", for the texts.
func _who() -> String:
	return "Hett" if shop_key == "marsh" else "the smith"


func _price(id: int) -> int:
	return maxi(1, roundi(Game.item(id).price * float(shop.price_mod) * (1.0 - _deal())))


## What the smith pays for one.
func _sell_price(id: int) -> int:
	var share := 1.0 if id == MinesQuest.ORE_ID else SELL_SHARE
	return maxi(1, floori(Game.item(id).price * share * (1.0 + _deal())))


## A smith deals in weapons, bows and arrows, quivers, armour and shields, and the ore; a trader
## ("buys": "anything") in anything with a price.
func buys(id: int) -> bool:
	var it := Game.item(id)
	if it.is_empty() or it.get("quest", false) or it.price <= 0:
		return false
	if shop.get("buys", "") == "anything":
		return true
	return id == MinesQuest.ORE_ID or id == 38 or it.weapon or it.gun or it.misil or it.quiver \
		or (it.armor and it.defense > 0)


func _sum() -> int:
	var t := 0
	for b in basket:
		t += _price(b.id) * b.n
	return t


# ---------------------------------------------------------------- shelves

## The kinds the party could sell, from the packs only (what is worn or held stays put):
## [{id, n}] in pack order.
func _sellable() -> Array:
	var out := []
	for c in Game.party:
		for s in range(Game.PACK_FIRST, Game.PACK_LAST + 1):
			var id: int = c.items[s]
			if not buys(id):
				continue
			var found := false
			for e in out:
				if e.id == id:
					e.n += Game.qty(c, s)
					found = true
			if not found:
				out.append({"id": id, "n": Game.qty(c, s)})
	return out


func _build_shelves() -> void:
	for ch in shelf.get_children():
		ch.queue_free()
	basket_box.visible = not selling
	var list: Array = []
	if selling:
		list = _sellable()
		Ui.label(shelf, "What %s will buy from your packs" % _who(), Vector2(176, 296), 11, Ui.DIM, 330, HORIZONTAL_ALIGNMENT_CENTER)
		if list.is_empty():
			Ui.label(shelf, "Nothing in your packs that " + _who() + " deals in.\n(Worn and held things stay where they are: take them off first.)",
				Vector2(190, 120), 12, Ui.TEXT, 300, HORIZONTAL_ALIGNMENT_CENTER).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		for id in shop.stock:
			list.append({"id": id, "n": 1})
	for i in mini(list.size(), 12):
		var e: Dictionary = list[i]
		var x := 186 + (i % 3) * 106
		var y := 30 + (i / 3) * 70
		var s := Slot.make(shelf, Rect2(x + 33, y, 40, 40), i, "sell" if selling else "shop", self)
		s.item_id = e.id
		var it := Game.item(e.id)
		if selling:
			s.count = e.n
			s.hint = "Click to sell one, Shift-click to sell all %d" % e.n if e.n > 1 else "Click to sell it"
			s.clicked.connect(_on_sell_click.bind(e.id))
		else:
			s.draggable = true
			s.hint = "Drag into the basket to buy"
		Ui.label(shelf, it.name, Vector2(x, y + 40), 11, Ui.TEXT, 106, HORIZONTAL_ALIGNMENT_CENTER)
		Ui.label(shelf, Game.money_string(_sell_price(e.id) if selling else _price(e.id)), Vector2(x, y + 54), 10,
			Ui.GOLD, 106, HORIZONTAL_ALIGNMENT_CENTER)


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
	purse_label.position.y = 436 if not selling else 330
	cost_label.add_theme_color_override("font_color", Ui.RED if _sum() > purse else Ui.TEXT)
	for i in party_boxes.size():
		var c: Dictionary = Game.party[i]
		party_boxes[i].text = "%d silver" % c.silver
	mode_btn.text = "Buy" if selling else "Sell"
	mode_btn.tooltip_text = "Back to the smith's wares" if selling \
		else ("Sell things from your packs" if shop.get("buys", "") == "anything" else "Sell weapons, armour, arrows and ore from your packs")
	var who := LehanQuests.best("talk")
	if _haggled_today():
		haggle_btn.disabled = true
		haggle_btn.tooltip_text = "Already haggled today (%s). Come back tomorrow." % (
			"%d%% better prices" % roundi(_deal() * 100) if _deal() > 0 else "no luck")
	else:
		haggle_btn.disabled = who.is_empty()
		haggle_btn.tooltip_text = "" if who.is_empty() else \
			"Haggle for better prices today, buying and selling. %s talks (Talk %d): %d%% chance of 10%% off, %d%% of 20%%. Once a day." % [
				who.name.split(" ")[0], Game.ability(who, "talk"), Game.chance(who, "talk", Game.NORMAL),
				Game.chance(who, "talk", Game.HARD)]
	haggle_btn.tooltip_text = Ui.tip(haggle_btn.tooltip_text)
	mode_btn.tooltip_text = Ui.tip(mode_btn.tooltip_text)


func _on_mode() -> void:
	selling = not selling
	talk_label.text = "Click something to sell one; Shift-click sells all of that kind." if selling \
		else "Drag the wares you want into the basket, then press Pay."
	_build_shelves()
	refresh()


# ---------------------------------------------------------------- buying

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
	# Try it on copies first: everything must fit (onto stacks, or into free slots).
	var copies: Array = Game.party.duplicate(true)
	for b in basket:
		for n in b.n:
			if Game.party_add(b.id, copies).is_empty():
				await Game.main.message("Your backpacks are too full to carry all that.")
				return
	Game.pay(sum)
	for b in basket:
		for n in b.n:
			Game.party_add(b.id)
	basket.clear()
	talk_label.text = "\"Pleasure doing business! The goods are in your backpacks.\""
	refresh()


# ---------------------------------------------------------------- selling

## Sells one (or with Shift, every one in the party's packs) of a kind; whoever carried it is paid.
func _on_sell_click(_s: Slot, id: int) -> void:
	var all := Input.is_key_pressed(KEY_SHIFT)
	var n := 0
	var paid := 0
	for c in Game.party:
		for s in range(Game.PACK_FIRST, Game.PACK_LAST + 1):
			while c.items[s] == id and (all or n == 0):
				Game.take_from(c, s)
				Game.add_silver(c, _sell_price(id))
				paid += _sell_price(id)
				n += 1
	if n == 0:
		return
	var nm: String = Game.item(id).name
	if id == MinesQuest.ORE_ID and shop_key == "smith":
		talk_label.text = "The smith weighs the ore in a big hand and whistles.\n\n\"Good stuff. %d silver.\"" % paid
	else:
		talk_label.text = "\"%s. I can use that.\"\n\n(Sold %s for %d silver.)" % [
			"Fair enough" if n == 1 else "A fair pile", nm if n == 1 else "%d %s" % [n, nm], paid]
	_build_shelves()
	refresh()


# ---------------------------------------------------------------- talk

func _on_talk() -> void:
	if shop_key == "marsh":
		talk_label.text = MarshData.TRADER_TALK[talk_i % MarshData.TRADER_TALK.size()]
		talk_i += 1
		return
	var lines: Array = FLAVOUR.duplicate()
	if LehanQuests.get_q("mines") == "done" or not Game.holder_of(49).is_empty():
		lines = AFTER + lines
	elif Game.story.has("mines_job"):
		lines = MINES + lines
	else:
		lines = BEFORE_JOB + lines
	talk_label.text = lines[talk_i % lines.size()]
	talk_i += 1


func _on_haggle() -> void:
	var who := LehanQuests.best("talk")
	if who.is_empty() or _haggled_today():
		return
	var first: String = who.name.split(" ")[0]
	var deal := -1.0
	if Game.check(who, "talk", Game.HARD):
		deal = HAGGLE_GREAT
		talk_label.text = "%s talks prices with %s until both are laughing, and the hands go up.\n\n\"Fine! Twenty off, today, for you.\"" % [first, _who()]
	elif Game.check(who, "talk", Game.NORMAL):
		deal = HAGGLE_GOOD
		talk_label.text = "%s haggles hard.\n\n\"All right, all right. Ten off today, and I'll pay a little better too.\"" % first
	else:
		talk_label.text = "%s tries to haggle.\n\n\"My prices are fair, friend. Take it or leave it. And don't try that again today.\"" % first
	Game.story["haggle"] = {"day": Game.day, "deal": deal}
	_build_shelves()
	refresh()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE and not Game.main.modal_open:
		get_viewport().set_input_as_handled()
		_leave()
