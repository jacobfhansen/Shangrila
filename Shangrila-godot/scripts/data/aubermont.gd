class_name AubermontData
extends RefCounted
## Who is about in Aubermont's river gate district (AubermontStreets), what they say, Corvin's
## shop and the Lamplighter inn. The first pieces of who the sect is: a crest on the Founders'
## statue whose name was chiselled off, a runaway servant, grey cloaks, and Founders' Night.
## Quest values: aub_crest ("seen" / "read"), aub_nan ("told"), aub_feast ("heard"),
## aub_edrin ("met"), aub_wick ("paid"). See "The story onward" in IDEAS.md.

const PEOPLE := {
	"1": {"key": "nan", "name": "Nan Grebe", "race": "Human", "height": 1.6,
		"look": {"skin": "#d8b090", "hair": "#7a6a5a", "cloth": "#3a3a44", "legs": "#2a2a30", "apron": true}},
	"2": {"key": "hillguard", "name": "Sergeant Voss", "race": "Human", "height": 1.85,
		"look": {"skin": "#c8a080", "hair": "#2a2420", "cloth": "#4a5464", "legs": "#2a2e36", "beard": true}},
	"3": {"key": "crier", "name": "The Crier", "race": "Human", "height": 1.7,
		"look": {"skin": "#e0b898", "hair": "#4a3020", "cloth": "#5a2a26", "legs": "#2a2020", "hat": true}},
	"4": {"key": "edrin", "name": "Edrin Calloway", "race": "Human", "height": 1.78,
		"look": {"skin": "#e8c8a8", "hair": "#b8803a", "cloth": "#3a4a6a", "legs": "#2a2a3a"}},
	"5": {"key": "wick", "name": "Wick", "race": "Human", "height": 1.25,
		"look": {"skin": "#d8a878", "hair": "#3a2a1a", "cloth": "#4a4036", "legs": "#2a2620", "hood": true}},
}
const CORVIN := {"name": "Corvin", "race": "Human",
	"look": {"skin": "#d0a888", "hair": "#8a8a8a", "cloth": "#2e2a2a", "apron": true, "beard": true}}

## Corvin's shop (the shop screen with {"shop": "aubermont"}): city steel and city prices.
const SHOP := {"name": "Corvin's Arms", "price_mod": 1.2, "buys": "anything", "keeper": "Corvin",
	"stock": [44, 45, 3, 32, 11, 12, 13, 10, 47, 15, 24, 23, 27, 50], "back": ["city", {"at": "shop"}]}
const SHOP_TALK := [
	"\"City steel, city prices. You'll find cheaper in Lehan, and it'll break cheaper too.\"",
	"\"Founders' Night is coming. Every house on the hill wants new swords for its guards, to stand about looking grand. Good for trade.\"",
	"\"Grey cloaks? Don't ask about grey cloaks in my shop. Buy something or go.\"",
	"\"Lockpicks? For the locksmiths' guild, naturally. I don't ask, and neither do they.\"",
]
const INN_NIGHT := 2   # silver a head: city prices


static func q(key: String) -> String:
	return LehanQuests.get_q(key)


static func cast() -> Dictionary:
	var c := NorthRoad.cast()
	for k in PEOPLE:
		var p: Dictionary = PEOPLE[k]
		c[p.key] = {"name": p.name, "race": p.race, "look": p.look}
	c["corvin"] = CORVIN
	return c


static func _fx(fx: String) -> Dictionary:
	return {"fx": fx, "wait": 0.1}


static func _host() -> String:
	return Game.story.get("host", "")


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


static func _of_race(race: int) -> Dictionary:
	for c in Game.party:
		if c.race == race:
			return c
	return {}


static func talk(id: String) -> Array:
	match PEOPLE[id].key:
		"nan": return _nan()
		"hillguard": return _hillguard()
		"crier": return _crier()
		"edrin": return _edrin()
		"wick": return _wick()
	return []


## Arriving through the river gate the first time.
static func arrival() -> Array:
	var out: Array = [
		{"n": "Through the river gate the street climbs at once, narrow and steep, between houses so tall the sky is a grey ribbon overhead. Each storey juts out further than the one below, until the eaves almost touch across the street, and the cobbles stay wet where the light never reaches."},
		{"n": "Lanterns burn at midday. People pass with their heads down. Somewhere above, a shutter closes."},
	]
	if _host() != "":
		out.append({"sp": "These walls weren't here. There was a road, and fields, and a river with nothing on it. They built all this on top of where I was."})
	return out


# ---------------------------------------------------------------- the townsfolk

static func _nan() -> Array:
	var host := _host()
	var out: Array = []
	if q("aub_nan") == "":
		out.append({"n": "A broad woman with a basket of eels on her hip and hands red from the cold."})
		out.append({"s": "nan", "t": "Eels, fresh this morning. No? Then you're from away. Everyone's from away this month, with Founders' Night coming."})
		out.append({"s": host, "t": "We passed a dead man on the north road. A servant, from the city, by the look of him."})
		out.append({"s": "nan", "a": "lowering her voice", "t": "Then he got further than most. They say a lad ran from one of the hill houses three weeks back. The one with the tower and the key over its gate, the one nobody names. Took nothing, they say. Just ran."})
		out.append({"s": "nan", "t": "And since then the Quiet have been about. Grey cloaks, soft boots. They ask questions down in the old town and nobody answers them, and nobody asks who sent them."})
		if q("north_odo") == "cold":
			out.append({"n": "(A tower and a key: the crest on the scrap of paper in the dead man's pack.)"})
		if host != "":
			out.append({"sp": "A house nobody names. Behind iron. That's where I am."})
		out.append(_fx("q:aub_nan=told"))
	else:
		out.append({"s": "nan", "t": "Keep your voice down about the hill, if you've any sense. And buy an eel."})
	return out


static func _hillguard() -> Array:
	var host := _host()
	var out: Array = []
	var nisk := _of_race(Game.NISK)
	out.append({"s": "hillguard", "t": "The hill gate. Residents, their servants, and those with business. Which are you?"})
	if q("aub_feast") == "":
		out.append({"s": host, "t": "Visitors. We'd hoped to see the great houses."})
		out.append({"s": "hillguard", "t": "Everyone hopes that. Come Founders' Night, nine days from now, the houses open their doors and their cellars, and anyone on a guest list walks up this street in silk. Anyone not on a list stays down here and watches the fireworks."})
		out.append({"s": "hillguard", "t": "Till then, nobody goes up without a pass from a house. Not my rule. I just stand here."})
		out.append(_fx("q:aub_feast=heard"))
		out.append({"n": "(Founders' Night: the hill houses hold a feast, with guest lists. A way up the hill, for anyone who can get on one.)"})
	else:
		out.append({"s": "hillguard", "t": "Still no pass? Then still no hill."})
	if not nisk.is_empty():
		out.append({"s": "hillguard", "a": "eyeing %s" % _first(nisk), "t": "And keep that one where I can see it. Nisk in the city carry a token from the watch-house, or they spend the night in it."})
	return out


static func _crier() -> Array:
	var out: Array = [
		{"s": "crier", "t": "Hear ye! Nine days to Founders' Night, when the five houses that broke the tyrant's crown open their doors to the city! The watch reminds all: curfew at the second bell, lanterns lit at dusk, and no gathering in the old town after dark!"},
		{"s": "crier", "a": "more quietly, for you", "t": "And anyone who knows the whereabouts of a runaway servant of the hill, in a blue coat, will find the reward generous and the questions few. That one's not on the list, mind. I'm paid to say it to strangers."},
	]
	if _host() != "":
		out.append({"sp": "The tyrant's crown. They made a feast of it. Every year, for all these years, they've drunk to my fall."})
	return out


static func _edrin() -> Array:
	var host := _host()
	var out: Array = []
	if q("aub_edrin") == "":
		out.append({"n": "A young man with copper hair sits on the fountain's rim with a battered lute, playing for nobody. The tune is slow and strange, older than the lute, older than the city: it climbs and falls back like someone almost saying a name."})
		if host != "":
			out.append({"sp": "That tune. I know that tune. Why do I know it? Make him stop. No: don't. Let him play it again."})
			out.append({"n": "The host's hands are shaking, and doesn't know why."})
		out.append({"s": "edrin", "t": "You stopped to listen. Nobody stops. Edrin Calloway, minstrel, at your service, for whatever coin you think a song is worth."})
		out.append({"s": host, "t": "What is that tune?"})
		out.append({"s": "edrin", "t": "My grandmother's, and her grandmother's before that, back and back. It has no name and no words. My family says it was made for someone, a long time ago, by someone who lost her. That's all anyone remembers."})
		out.append({"s": "edrin", "t": "I play here most days. Come back if you want to hear it again. Or if you need a minstrel, though I can't think why anyone would."})
		out.append(_fx("q:aub_edrin=met"))
	else:
		out.append({"n": "Edrin is playing the old tune again. It goes on climbing and falling back, never quite arriving."})
		out.append({"s": "edrin", "t": "Back for more? It doesn't get any happier, I'm afraid."})
		if host != "":
			out.append({"sp": "Someone who lost her. Somebody lost her, and I- no."})
	return out


static func _wick() -> Array:
	var host := _host()
	var out: Array = []
	var guide: Array = [
		{"s": "wick", "t": "Right. You're at the river gate, where everything comes in. West through the arch is the old town: temples, the great library, and the poor, and the graves behind the Temple of the Hours."},
		{"s": "wick", "t": "North is the hill, the five houses and their friends, behind the wall. You'll not get up there. Nobody does, except on Founders' Night."},
		{"s": "wick", "t": "And under it all there's Below: cellars and old drains, all the way up under the hill, they say. That's Sasska's. You don't go Below without Sasska knowing, and you don't come back up without paying her."},
		_fx("q:aub_wick=paid"),
	]
	if q("aub_wick") == "":
		out.append({"n": "A boy of ten or so in a hood too big for him falls into step beside you."})
		out.append({"s": "wick", "t": "Strangers! You'll want a guide. Aubermont's four hills and a thousand alleys, and you'll be robbed in half of them. Wick knows them all. One silver, and I'll tell you how the city lies."})
		out.append({"choice": "wick", "options": [
			{"t": "Pay him a silver.", "silent": true, "tip": "Needs 1 silver in the party purse",
				"after": [_fx("pay:1"), {"s": "wick", "a": "biting the coin", "t": "Real. Good."}] + guide},
			{"t": "No, thanks.", "silent": true, "after": [{"s": "wick", "t": "Your loss. Mind your purses."}]},
		]})
	else:
		out.append({"s": "wick", "t": "Lost already? Old town west, the hill north, Below underneath. That one's free."})
	return out


## The Founders' statue: five lords round a broken crown; one name chiselled off the plinth.
static func founders() -> Array:
	var host := _host()
	var reader := LehanQuests.best("lore")
	var ok := Game.ability(reader, "lore") > 0 and Game.check(reader, "lore", Game.NORMAL)
	var out: Array = [
		{"n": "A dry fountain, and on it five lords in stone, swords point-down, standing in a ring round a crown that lies broken at their feet. Round the plinth, five crests: a ship, a wheel, a lion, a sheaf of wheat, and a tower with a key."},
		{"n": "Under four of the crests are names. Under the tower and the key, the stone has been chiselled smooth, carefully, a long time ago."},
	]
	if host != "":
		out.append({"sp": "Five of them. My lords. I gave them their swords. I remember their faces, nearly. Not one of these is a good likeness."})
	out.append(_fx("q:aub_crest=seen"))
	if q("aub_crest") != "read":
		out.append({"choice": "founders", "options": [
			{"t": "Study the crests and what is left of the inscription.", "silent": true, "ok": ok,
				"checks": [LehanQuests.chk(reader, "lore", Game.NORMAL).merged({"needs_skill": true})],
				"after": [{"n": "%s runs a finger over the smoothed stone and finds the ghost of a line the chisel missed: \"...who keep the key, and the oath, and the door.\"" % _first(reader)},
					{"s": host, "t": "A family that took its own name off the city's monument. Keeping an oath doesn't need a name, I suppose. Only a door."},
					_fx("q:aub_crest=read"), _fx("xp:%s" % LehanQuests.CHECK_XP),
					{"n": "(The house of the tower and the key: they keep \"the key, and the oath, and the door\". The jailers' oath.)"}] if ok
					else [{"n": "%s stares at the smoothed stone, but whatever was there is gone." % _first(reader)}]},
			{"t": "Walk on.", "silent": true, "after": []},
		]})
	return out
