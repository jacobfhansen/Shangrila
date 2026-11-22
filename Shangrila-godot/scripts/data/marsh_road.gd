class_name MarshRoad
extends RefCounted
## The three days from Lehan to the Thuug marshes: on the first trip, salt traders with a cart stuck
## on the causeway road (day 1), and a night camp where something comes for the food (day 2).
## See "The Drowned Shrine" in IDEAS.md. Effects (MarshRoad.apply):
##   item:ID (to the party, stacked), pay:N, hurtone:N, steal:N (up to N rations gone),
##   tired:N (everyone loses N Endurance), q:key=value and xp:N (LehanQuests.apply)

const WENNA := {"name": "Wenna", "race": "Human",
	"look": {"skin": "#d8a880", "hair": "#b8b0a8", "cloth": "#6a5a40", "hood": true}}

## Which scene comes after which day of the first trip (1-based).
const SCENES := {1: "salt_cart", 2: "night_camp"}


static func _host() -> String:
	return Game.story.get("host", "")


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


static func _fx(fx: String) -> Dictionary:
	return {"fx": fx, "wait": 0.1}


## Someone in the party with this cast key, other than the host ({} if not there).
static func _companion(key: String) -> Dictionary:
	for c in Game.party:
		if LehanQuests.key_of(c) == key and key != _host():
			return c
	return {}


static func cast() -> Dictionary:
	var c := PrologueData.company_cast()
	c.merge(LehanQuests.cast())
	c["wenna"] = WENNA
	return c


static func scene(key: String) -> Array:
	match key:
		"salt_cart": return _salt_cart()
		"night_camp": return _night_camp()
	return []


static func _salt_cart() -> Array:
	var strong := LehanQuests.best("toughness")
	var ok := Game.check(strong, "toughness", Game.NORMAL)
	var out: Array = [
		{"n": "Late on the first day the road drops onto the causeway: a raised bank of packed earth and logs through reeds taller than a man. Ahead, a cart sits tilted, one wheel sunk to the hub in black mud."},
		{"s": "wenna", "t": "Don't just stand there gawking. Salt for the marsh villages, and the ox is sulking. Lend a shoulder, or a coin, or get out of my road."},
	]
	var ommuk := _companion("ommuk")
	if not ommuk.is_empty():
		out.append({"s": "ommuk", "t": "Salt for the stilt villages. My people trade fish for it. Without it, the winter catch rots."})
	out.append({"choice": "salt_cart", "options": [
		{"t": "Put your shoulders to the wheel.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(strong, "toughness", Game.NORMAL)],
			"after": ([{"n": "%s braces against the wheel and heaves. The mud lets go with a sucking sound, and the cart rolls up onto the logs." % _first(strong)},
				{"s": "wenna", "t": "Well. Strong backs and good manners. Here, take some fish for the road. And at the village gate, tell Orrun that Wenna sent you. He's less sour with friends of mine."},
				_fx("item:51"), _fx("item:51"), _fx("q:marsh_wenna=friend"), _fx("xp:%s" % LehanQuests.CHECK_XP),
				{"n": "(You get 2 Dried Fish.)"}] if ok
				else [{"n": "%s strains until something in the back goes twang. In the end it takes everyone, the whole afternoon, and the ox." % _first(strong)},
					_fx("hurtone:3"), _fx("tired:10"),
					{"s": "wenna", "t": "Took you long enough. Still, you stayed. Have a fish."},
					_fx("item:51"), _fx("q:marsh_wenna=helped"), {"n": "(You get a Dried Fish. Everyone is tired: −10 Endurance.)"}])},
		{"t": "Buy food from her and go on (6 silver for four dried fish).", "silent": true,
			"after": [_fx("pay:6"), _fx("item:51"), _fx("item:51"), _fx("item:51"), _fx("item:51"),
				{"s": "wenna", "t": "Coin's coin. Mind the soft edges past the second bridge."},
				{"n": "(You pay 6 silver for 4 Dried Fish.)"}],
			"tip": "Needs 6 silver in the party purse"},
		{"t": "Leave her to it.", "silent": true, "after": [
			{"s": "wenna", "t": "Hope the marsh swallows you."}, _fx("q:marsh_wenna=left")]},
	]})
	return out


static func _night_camp() -> Array:
	var watcher := LehanQuests.best("perception")
	var woodsman := LehanQuests.best("survival")
	var ok_w := Game.check(watcher, "perception", Game.NORMAL)
	var ok_s := Game.ability(woodsman, "survival") > 0 and Game.check(woodsman, "survival", Game.NORMAL)
	return [
		{"n": "The second night you camp on a dry hummock off the causeway. Frogs, then silence. Then a wet rustle in the reeds, very close to where the packs lie."},
		{"choice": "night_camp", "options": [
			{"t": "Keep a watch, and catch whatever it is.", "silent": true, "ok": ok_w, "checks": [LehanQuests.chk(watcher, "perception", Game.NORMAL)],
				"after": [{"n": "%s sees it first: a sleek, whiskered marsh otter, long as a man's arm, nosing at the food sack. A thrown boot, and it's gone in a swirl of black water." % _first(watcher)},
					_fx("xp:%s" % LehanQuests.CHECK_XP), {"n": "(The food is safe.)"}] if ok_w
					else [{"n": "%s stares into the dark until the reeds swim. The rustling stops. In the morning the food sack is torn open." % _first(watcher)},
						_fx("steal:3")]},
			{"t": "Hang the packs from the old willow, out of reach.", "silent": true, "ok": ok_s,
				"checks": [LehanQuests.chk(woodsman, "survival", Game.NORMAL).merged({"needs_skill": true})],
				"after": [{"n": "%s slings a rope over a branch and hauls the packs up. Something snuffles around the willow half the night, and leaves hungry." % _first(woodsman)},
					_fx("xp:%s" % LehanQuests.CHECK_XP), {"n": "(The food is safe.)"}] if ok_s
					else [{"n": "The branch is rotten. It cracks at midnight and drops everything into the reeds. What you can find in the morning is wet and nibbled."},
						_fx("steal:2")]},
			{"t": "We're too tired. Sleep, and hope.", "silent": true,
				"after": [{"n": "You sleep like the dead. So, it seems, does nobody else in the marsh: in the morning the food sack has been dragged off into the reeds."},
					_fx("steal:4")]},
		]},
	]


## The scene effects (see the top of the file). Returns a line for the log, or "".
static func apply(fx: String) -> String:
	if fx.begins_with("item:"):
		Game.party_add(int(fx.substr(5)))
	elif fx.begins_with("pay:"):
		if not Game.pay(int(fx.substr(4))):
			return "(The purse is too light: she shrugs and hands the fish over anyway, for what you have.)"
	elif fx.begins_with("hurtone:"):
		var up := Game.party.filter(func(c): return c.hits > 1)
		if not up.is_empty():
			var c: Dictionary = up.pick_random()
			c.hits = maxi(1, c.hits - Game.my_random(1, int(fx.substr(8))))
	elif fx.begins_with("tired:"):
		for c in Game.party:
			c.health = maxi(0, c.health - int(fx.substr(6)))
	elif fx.begins_with("steal:"):
		var n := int(fx.substr(6))
		var gone := 0
		for id in Game.RATIONS:
			for c in Game.party:
				for s in range(Game.PACK_FIRST, Game.PACK_LAST + 1):
					while gone < n and c.items[s] == id:
						Game.take_from(c, s)
						gone += 1
		return "(%s.)" % ("Nothing was lost: there was no food to steal" if gone == 0
			else "%d ration%s gone" % [gone, "" if gone == 1 else "s"])
	else:
		LehanQuests.apply(fx)
	return ""
