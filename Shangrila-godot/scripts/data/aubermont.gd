class_name AubermontData
extends RefCounted
## Who is about in Aubermont's river gate district (AubermontStreets), what they say, Corvin's
## shop and the Lamplighter inn. The first pieces of who the sect is: a crest on the Founders'
## statue whose name was chiselled off, a runaway servant, grey cloaks, and Founders' Night.
## Quest values: aub_crest ("seen" / "read"), aub_nan ("told"), aub_feast ("heard"),
## aub_edrin ("met"), aub_wick ("paid"). The old town: aub_house ("known": House Morvane named, by
## "token", "aldric" or "stacks"), aub_token (a reader's token bought), aub_aldric ("joined" /
## "refused"; aub_aldric_told: he knows what the party is after), aub_temple ("told"), aub_singers
## (the temple's singers go up for the feast), aub_odo, aub_hesk ("told"), aub_vault ("heard": the
## iron door in the Morvane cellars), aub_grey ("seen"). See "The story onward" in IDEAS.md.

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
	# The old town.
	"6": {"key": "hesk", "name": "Mother Hesk", "race": "Human", "height": 1.5,
		"look": {"skin": "#d0a888", "hair": "#c8c4bc", "cloth": "#3e3a3a", "legs": "#2a2626", "hood": true}},
	"8": {"key": "odo", "name": "Odo Brakk", "race": "Human", "height": 1.9,
		"look": {"skin": "#c89a74", "hair": "#9a9890", "cloth": "#4a4440", "legs": "#3a3430", "beard": true}},
	"9": {"key": "grey", "name": "A man in grey", "race": "Human", "height": 1.8,
		"look": {"skin": "#d8c0a8", "hair": "#2a2a2a", "cloth": "#5a5c60", "legs": "#3a3c40", "hood": true}},
	# The hill.
	"7": {"key": "watchman", "name": "A hill watchman", "race": "Human", "height": 1.85,
		"look": {"skin": "#d8b494", "hair": "#4a3a2a", "cloth": "#3a4458", "legs": "#22262e"}},
}
const STEWARD := {"name": "Steward Hallam", "race": "Human",
	"look": {"skin": "#d8c4b0", "hair": "#8a8a8a", "cloth": "#141418", "legs": "#0e0e10"}}
const GATEKEEPER := {"name": "The Morvane gatekeeper", "race": "Human",
	"look": {"skin": "#c8a888", "hair": "#2a2420", "cloth": "#2a2a30", "legs": "#1a1a1e", "beard": true}}
const BETT := {"name": "Bett", "race": "Human",
	"look": {"skin": "#e8c0a0", "hair": "#a0602a", "cloth": "#5a4a3a", "legs": "#3a3028", "apron": true}}
const YSOLDE := {"name": "Ysolde Marrin", "race": "Human",
	"look": {"skin": "#d0a080", "hair": "#c8c0b0", "cloth": "#5a3a2a", "legs": "#3a2a20"}}
const ALDRIC := {"name": "Aldric Thorne", "race": "Human",
	"look": {"skin": "#e0c4a8", "hair": "#3a3434", "cloth": "#1e1e24", "legs": "#16161a", "beard": true}}
const AMSEL := {"name": "Sister Amsel", "race": "Human",
	"look": {"skin": "#e8c8b0", "hair": "#2a2020", "cloth": "#5a4a2a", "legs": "#3a3020", "hood": true}}
const ARCHIVIST := {"name": "The Archivist", "race": "Human",
	"look": {"skin": "#e0c8b0", "hair": "#e0e0e0", "cloth": "#2a2a30", "legs": "#1a1a20", "beard": true}}
const TOKEN := 5   # silver for a reader's token at the library
const CORVIN := {"name": "Corvin", "race": "Human",
	"look": {"skin": "#d0a888", "hair": "#8a8a8a", "cloth": "#2e2a2a", "apron": true, "beard": true}}

## Corvin's shop (the shop screen with {"shop": "aubermont"}): city steel and city prices.
const SHOP := {"name": "Corvin's Arms", "price_mod": 1.2, "buys": "anything", "keeper": "Corvin",
	"stock": [44, 45, 3, 32, 11, 12, 13, 10, 47, 15, 24, 23, 27, 50], "back": ["city", {"district": "gate", "at": "shop"}]}
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
	c["aldric"] = ALDRIC
	c["amsel"] = AMSEL
	c["archivist"] = ARCHIVIST
	c["steward"] = STEWARD
	c["gatekeeper"] = GATEKEEPER
	c["bett"] = BETT
	c["ysolde"] = YSOLDE
	return c


## Whether someone from the streets has joined the party (or waits at an inn).
static func gone(key: String) -> bool:
	for c in Game.party + Game.roster:
		if c.get("recruit", "") == key:
			return true
	return false


## Someone joins on the spot: into the party if there is room, otherwise to wait at the Lamplighter.
static func join(key: String) -> String:
	if gone(key):
		return ""
	var r: Dictionary = LehanQuests.RECRUITS[key]
	var c := Game.make_character(r.name, Game.CLASSES.find(r.cls), Game.RACES.find(r.race),
		Game.PORTRAIT_CAST + LehanQuests.ICON_BASE + r.icon, r.abilities)
	c["traits"] = r.traits.duplicate()
	c["recruit"] = key
	if Game.party.size() < Game.MAX_PARTY:
		Game.party.append(c)
		return "(%s joins the party.)" % r.name
	c["inn"] = "aubermont"
	Game.roster.append(c)
	return "(The party is full: %s will wait at the Lamplighter.)" % r.name


## The scene effects: join:KEY, otherwise as MarshRoad.apply. Returns a line for the log, or "".
static func apply(fx: String) -> String:
	if fx.begins_with("join:"):
		return join(fx.substr(5))
	return MarshRoad.apply(fx)


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
		"hesk": return _hesk()
		"odo": return _odo()
		"grey": return _grey()
		"watchman": return _watchman()
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
	elif q("aub_hill") == "":
		out.append({"s": "hillguard", "t": "Still no pass? Then still no hill."})
	if not nisk.is_empty():
		out.append({"s": "hillguard", "a": "eyeing %s" % _first(nisk), "t": "And keep that one where I can see it. Nisk in the city carry a token from the watch-house, or they spend the night in it."})
	if q("aub_hill") != "":
		out.append({"s": "hillguard", "t": "You again. Go on up. Mind your manners on the hill; they notice."})
		return out
	# The ways up: a bribe, a story (hired swords for the Lion's feast), or Aldric's scholar's seal.
	var talker := LehanQuests.best("talk")
	var ok := Game.check(talker, "talk", Game.HARD)
	var up := [{"n": "Voss steps aside, and the iron gate swings open on a street that climbs, wide and clean and quiet, between high walls."},
		{"n": "(The way up the hill is open to you now.)"}]
	var opts: Array = []
	opts.append({"t": "Slip him something for his trouble (15 silver).", "silent": true, "tip": "Needs 15 silver in the party purse",
		"after": [_fx("pay:15"), {"s": "hillguard", "a": "pocketing it without looking", "t": "Deliveries. Of course. I'll remember your faces, so don't make me sorry."}, _fx("q:aub_hill=bribed")] + up})
	opts.append({"t": "Say you're hired swords for the Lion house's feast, come to see the ground.", "silent": true, "say": host, "ok": ok,
		"checks": [LehanQuests.chk(talker, "talk", Game.HARD)],
		"after": ([{"s": host, "t": "The Lion house hired us for Founders' Night. Extra blades at the door. Their captain wants us to walk the ground first."},
			{"s": "hillguard", "t": "The Lions would. They trust nobody, and they're right. Go on, then."}, _fx("q:aub_hill=talked")] + up) if ok
			else [{"s": host, "t": "The Lion house hired us for Founders' Night. Extra blades at the door."},
				{"s": "hillguard", "t": "Did they. Then they'll have given you a token with a lion on it. No? Then no."}]})
	if gone("aldric") and Game.party.any(func(c): return c.get("recruit", "") == "aldric"):
		opts.append({"t": "Let Aldric show his scholar's seal.", "silent": true,
			"after": [{"s": "aldric", "t": "Aldric Thorne, reader to the House of the Wheel's library. These are my assistants."},
				{"s": "hillguard", "t": "Master Thorne. Of course."},
				{"n": "Voss doesn't even look at the seal. He looks at Aldric as if he knows him well."},
				_fx("q:aub_hill=aldric"), _fx("q:aub_aldric_told=1")] + up})
	opts.append({"t": "Leave it.", "silent": true, "after": []})
	out.append({"choice": "hillgate", "options": opts})
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



# ---------------------------------------------------------------- the old town

static func oldtown_arrival() -> Array:
	var out: Array = [
		{"n": "Through the arch the old town closes in: streets that bend for no reason, houses older and blacker than at the river gate, leaning so far that in places you could step from one window to the one across. Bells somewhere count the hour, one slow stroke after another."},
	]
	if _host() != "":
		out.append({"sp": "Older stone here. Some of it was here before they were. I can feel it under the soot, like a bone under skin."})
	return out


static func _house_line() -> String:
	return "House Morvane" if q("aub_house") != "" else "the house of the tower and the key"


## The Great Library: the Founders' roll, in the closed stacks. A reader's token and Lore, Aldric
## Thorne's help, or the stacks by stealth. Then Aldric offers to come along.
static func library() -> Array:
	var host := _host()
	var reader := LehanQuests.best("lore")
	var sneak := LehanQuests.best("stealth")
	var ok_read := Game.check(reader, "lore", Game.NORMAL)
	var ok_sneak := Game.check(sneak, "stealth", Game.NORMAL)
	var out: Array = []
	if q("aub_house") != "":
		out.append({"n": "The Great Library: a vaulted hall of chained books, lamps on long chains, the scratch of pens. The archivist doesn't look up."})
		if q("aub_aldric") == "" and not gone("aldric"):
			out.append_array(_aldric_offer())
		return out
	out.append({"n": "The Great Library: a hall as long as a street, vaulted like a temple, shelves to the roof and every book on a chain. Lamps hang on chains too, so the light swings slowly when the door opens."})
	out.append({"s": "archivist", "t": "The Founders' rolls? Closed stacks. Readers with a token only. Tokens are %d silver, and the stacks close at the bell." % TOKEN})
	out.append({"n": "At the next desk a scholar in black lifts his head from a book: a thin, neat man with a grey-shot beard and very steady eyes."})
	out.append({"s": "aldric", "t": "The Founders' rolls. Now there's a request you don't hear every day. Aldric Thorne; I've been reading those rolls for twenty years. If you tell me what you're looking for, I can save you the token and the afternoon."})
	if Game.has_insight() and host != "":
		out.append({"sp": "Look at him. Look properly, the way I can now. There's no warmth in that one at all: patience, and deceit, cold as a coin. He wants to know what we want. He wants it very much."})
	var roll := [
		{"n": "The roll is a long strip of vellum, brown at the edges. Four houses, each with its crest and its oath: the ship, the wheel, the lion, the sheaf. And a fifth, the tower and the key:"},
		{"n": "\"House Morvane, Keepers of the Key, to whom the oath and the door were given, to hold until the end of days. Their name to be spoken no more in the city, by their own wish.\""},
		_fx("q:aub_house=known"), _fx("xp:%s" % LehanQuests.CHECK_XP),
	]
	if host != "":
		roll.append({"sp": "Morvane. A Morvane carried my keys. He stood at my door every night of my reign, and then he locked it from the other side."})
	roll.append({"n": "(House Morvane: the jailers of the oath. Their house is on the hill.)"})
	if q("aub_aldric") == "" and not gone("aldric"):
		roll.append_array(_aldric_offer())
	var opts: Array = []
	opts.append({"t": "Buy a reader's token and search the rolls yourselves (%d silver)." % TOKEN, "silent": true, "ok": ok_read,
		"checks": [LehanQuests.chk(reader, "lore", Game.NORMAL)], "tip": "Needs %d silver in the party purse" % TOKEN,
		"after": ([_fx("pay:%d" % TOKEN), _fx("q:aub_token=1"),
			{"s": "aldric", "a": "shrugging, and going back to his book", "t": "As you like."},
			{"n": "In the closed stacks %s works along the shelves for an hour before finding the right press." % _first(reader)}] + roll
			+ [_fx("q:aub_house=token")]) if ok_read
			else [_fx("pay:%d" % TOKEN), _fx("q:aub_token=1"),
				{"n": "%s searches the closed stacks until the bell, among a thousand rolls of tithes and boundaries, and finds nothing about the Founders." % _first(reader)},
				{"n": "(The token is kept. Come back and try again, or take Aldric's help.)"}]})
	opts.append({"t": "Tell Aldric what you're looking for, and let him find it.", "silent": true,
		"after": [{"s": host, "t": "The fifth Founder. The house of the tower and the key."},
			{"s": "aldric", "a": "after the smallest pause", "t": "Ah. Not many ask about them. Wait here."},
			{"n": "He's back in minutes, with the right roll already open at the right place."}] + roll
			+ [_fx("q:aub_house=aldric"), _fx("q:aub_aldric_told=1")]})
	opts.append({"t": "Slip into the closed stacks without a token.", "silent": true, "ok": ok_sneak,
		"checks": [LehanQuests.chk(sneak, "stealth", Game.NORMAL)],
		"after": ([{"n": "While the archivist trims a lamp, %s goes through the gate to the stacks like a shadow and comes back with the Founders' roll under one arm." % _first(sneak)}] + roll
			+ [_fx("q:aub_house=stacks")]) if ok_sneak
			else [{"n": "A board creaks. The archivist's head comes up like a heron's."},
				{"s": "archivist", "t": "Out. Readers with a token only. Out, before I call the watch."},
				{"n": "(Thrown out, for today. A token, or Aldric, might still do it.)"}]})
	opts.append({"t": "Leave the library.", "silent": true, "after": []})
	out.append({"choice": "library", "options": opts})
	return out


## Aldric offers himself. The spirit, with Insight, sees what he is.
static func _aldric_offer() -> Array:
	var host := _host()
	var out: Array = []
	out.append({"n": "Aldric Thorne closes his book."})
	out.append({"s": "aldric", "t": "Whatever you want with the Morvanes, you'll want someone who knows their house: the old plans, the servants' stair, who dines with whom. I know all of it. And I confess I'm curious. Let me come with you."})
	if Game.has_insight() and host != "":
		out.append({"sp": "He's lying about why. I can see it in him, plain as I see my host: Deceitful, patient, calm all the way down. He wants to be near us. Whoever sent him wants him near us."})
	out.append({"choice": "aldric", "options": [
		{"t": "Take him along.", "silent": true, "say": host,
			"after": [{"s": host, "t": "Then come. We could use someone who knows the hill."},
				{"s": "aldric", "t": "Splendid. I'll fetch my coat."}, _fx("q:aub_aldric=joined"), _fx("join:aldric")]},
		{"t": "Take him along, and keep an eye on him.", "silent": true, "say": host,
			"tip": "He'll come. You'll know what he is, and watch him.",
			"after": [{"s": host, "t": "Come along, then."},
				{"n": "%s smiles, and decides never to turn their back on him." % LehanQuests.host_first()},
				_fx("q:aub_aldric=joined"), _fx("q:aub_aldric_watched=1"), _fx("join:aldric")]},
		{"t": "Thank him, and refuse.", "silent": true, "say": host,
			"after": [{"s": host, "t": "Thank you. We'll manage."},
				{"s": "aldric", "a": "without the least sign of disappointment", "t": "Of course. I'm here most days, if you change your mind."},
				_fx("q:aub_aldric=refused")]},
	]})
	return out


## The Temple of the Hours: Sister Amsel. The Morvanes pay for the bells; the temple's singers go
## up the hill for the Founders' Night feast.
static func temple() -> Array:
	var host := _host()
	var out: Array = [
		{"n": "Inside, the temple is all height and shadow. Above the altar a great clock turns, slow as a millstone, and every hour its bell shakes dust out of the vault. A priestess in ochre is trimming candles."},
	]
	if q("aub_temple") == "":
		out.append({"s": "amsel", "t": "Welcome to the Hours. Light a candle for someone, if you like; it costs nothing, though the box by the door is grateful."})
		out.append({"s": host, "t": "The clock and the bells: someone rich must pay for all this."})
		out.append({"s": "amsel", "t": "%s. They have for three hundred years. Their steward brings the purse every quarter-day. The old lord himself hasn't been seen since the spring; gone south on some business, they say." % ("House Morvane" if q("aub_house") != "" else "The house of the tower and the key, on the hill")})
		out.append({"s": "amsel", "t": "And every Founders' Night our choir goes up the hill to sing at their feast. Twelve voices, in hoods, through the servants' gate. I'm always short of voices. The fever took two this winter."})
		out.append(_fx("q:aub_temple=told"))
		out.append(_fx("q:aub_singers=heard"))
		out.append({"n": "(The temple's choir sings at the Morvane feast on Founders' Night, and Sister Amsel is short of voices. A way up the hill, and through the servants' gate.)"})
		if host != "":
			out.append({"sp": "Gone south. In the spring. When the shrine by the road was found, and a company was paid to pull it down."})
	else:
		out.append({"s": "amsel", "t": "Back again? The choir practises at dusk, if you have a voice. I mean that."})
	return out


static func _hesk() -> Array:
	var host := _host()
	var out: Array = []
	var knows := q("north_odo") != "" or q("aub_odo") != ""
	if q("aub_hesk") == "":
		out.append({"n": "An old woman sits on the well's edge with her hands in her lap, watching the arch as if someone might come through it."})
		out.append({"s": "hesk", "t": "Have you come up the north road? My boy went that way, three weeks gone. Pell. Tall, in a blue coat. He was a footman on the hill. He didn't say goodbye."})
		if knows:
			out.append({"s": host, "t": "There was a man in a blue coat on the north road. A gravedigger found him. He was buried properly, with words said."})
			out.append({"n": "For a long time she says nothing at all."})
			out.append({"s": "hesk", "t": "He was frightened. He came home in the night, white as milk, and said there was something in the cellars. Behind the iron door, the one with no keyhole. The steward goes down with something on a chain round his neck that isn't a key."})
			out.append({"s": "hesk", "t": "Pell said it whispered. Through the iron. In a voice like the old king's face on the coins, he said, as if a coin could talk. Then he ran. And they sent the grey ones after him."})
			if host != "":
				out.append({"sp": "It whispered. Of course it did. It was calling. I'd have called too."})
			out.append(_fx("q:aub_hesk=told"))
			out.append(_fx("q:aub_vault=heard"))
			out.append({"n": "(Below the Morvane house: an iron door with no keyhole, opened with something the steward wears on a chain.)"})
		else:
			out.append({"s": host, "t": "We haven't seen him. We'll keep an eye out."})
			out.append({"s": "hesk", "t": "Thank you. Everyone says that."})
	else:
		out.append({"s": "hesk", "t": "Words said over him. That's something. That's more than the hill ever gave him."})
	return out


static func _odo() -> Array:
	var host := _host()
	var met := q("north_odo")
	var out: Array = []
	if met == "cold":
		out.append({"n": "Odo Brakk is digging. He sees who it is and goes on digging."})
		out.append({"s": "odo", "t": "Rob anyone today? No? Then go away and keep it that way."})
		return out
	if met == "":
		out.append({"n": "A big grey-haired man is digging a grave between the leaning stones."})
		out.append({"s": "odo", "t": "Odo Brakk. I bury the ones nobody claims. There's always work in Aubermont."})
		out.append(_fx("q:north_odo=met"))
		return out
	if q("aub_odo") == "":
		out.append({"n": "Odo Brakk leans on his spade among the stones and nods as if he'd expected you."})
		out.append({"s": "odo", "t": "You found me. Good. I asked about our man from the road. Pell, his name was, a Morvane footman. His mother lives by the well. Somebody ought to tell her; I haven't had the heart."})
		out.append({"s": "odo", "t": "And the grey ones, the Quiet: they bury nobody, but they come here at night and stand about the old stones, the oldest ones, from before the city. Looking for something. I don't ask."})
		out.append(_fx("q:aub_odo=told"))
	if not gone("odo"):
		var talker := LehanQuests.best("talk")
		var pious := Game.party.any(func(c): return "Pious" in c.get("traits", []))
		var ok := pious or Game.check(talker, "talk", Game.NORMAL)
		out.append({"s": "odo", "t": "I've buried enough strangers this year. I wouldn't mind walking with some live ones for a while."})
		var ask: Dictionary = {"t": "Ask him to come with you.", "silent": true, "say": host,
			"after": ([{"s": host, "t": "Then walk with us. We could use a strong back, and someone who knows the dead."},
				{"s": "odo", "t": "The dead will keep. They're good at it."}, _fx("q:aub_odo=joined"), _fx("join:odo")]) if ok
				else [{"s": host, "t": "Then walk with us."},
					{"s": "odo", "t": "Not today. Ask me again when I know what you're about."}]}
		if not pious:
			ask["ok"] = ok
			ask["checks"] = [LehanQuests.chk(talker, "talk", Game.NORMAL)]
		out.append({"choice": "odo", "options": [ask, {"t": "Not now.", "silent": true, "after": [{"s": "odo", "t": "I'll be here. I usually am."}]}]})
	return out


## One of the Quiet, watching from the dead-end alley.
static func _grey() -> Array:
	var host := _host()
	var looker := LehanQuests.best("perception")
	var out: Array = [
		{"n": "A man in a grey cloak stands at the alley's end with his back to the wall, doing nothing. Soft boots. A face you would forget at once."},
		{"s": "grey", "t": "Just taking the air."},
	]
	if q("aub_aldric_told") != "":
		out.append({"n": "His eyes go over each of you, one by one, as if checking faces against a list he's been given."})
	if Game.has_insight() and host != "":
		out.append({"sp": "One of them. One of mine, once, or his great-great-grandfather was. He's watching us. He knew we'd come this way."})
	elif Game.check(looker, "perception", Game.NORMAL):
		out.append({"n": "%s notices the grey thread on his sleeve, the same as on the broken ward in the drowned temple." % _first(looker)})
	out.append(_fx("q:aub_grey=seen"))
	return out



# ---------------------------------------------------------------- the hill

static func hill_arrival() -> Array:
	var out: Array = [
		{"n": "Above the gate the city changes. The street is wide and swept, the houses stand back behind iron, and the quiet is so complete you can hear the river far below. Five great houses face each other across an avenue: four of pale stone with their crests over their gates, and one that is black."},
		{"n": "Behind the black house an old tower rises, far older than the house, with one window lit near the top."},
	]
	if _host() != "":
		out.append({"sp": "There. In there. I can feel it the way you feel heat on your face with your eyes shut. So close. A wall and a door and an iron lock, and then me."})
	return out


## The Morvane gate. The gatekeeper; watching the gate shows the steward and what he wears on a chain.
static func morvane_gate() -> Array:
	var host := _host()
	var looker := LehanQuests.best("perception")
	var ok := Game.check(looker, "perception", Game.NORMAL)
	var out: Array = [
		{"n": "A double gate of black iron, studded, set deep in the black wall. Over it, the tower and the key, carved and not painted, so old the edges have gone soft. There's no bell, only a grille at head height."},
	]
	if q("aub_gate") == "":
		if q("aub_aldric_told") != "":
			out.append({"s": "gatekeeper", "a": "through the grille", "t": "Ah. You'll be the ones asking after old rolls in the library. We were told you might come by. The house isn't receiving."})
			if host != "":
				out.append({"sp": "Told. Aldric told them. Of course he did."})
		else:
			out.append({"s": "gatekeeper", "a": "through the grille", "t": "The house isn't receiving. Petitions to the steward, in writing, through the temple. Good day."})
		out.append(_fx("q:aub_gate=refused"))
	else:
		out.append({"n": "The grille stays shut."})
	if q("aub_chain") == "":
		out.append({"choice": "morvane", "options": [
			{"t": "Wait across the avenue and watch the gate.", "silent": true, "ok": ok,
				"checks": [LehanQuests.chk(looker, "perception", Game.NORMAL)],
				"after": ([{"n": "An hour passes. Then the gate opens a crack and a tall, grey man in black comes out, two guards behind him: the steward. On a chain round his neck, outside his coat where everyone can see it, hangs a disc of black stone as wide as a palm."},
					{"n": "%s gets a good look as he passes: it's carved in rings of lines and circles, like the ward-stones in the tunnels under Lehan and in the drowned temple, and right in the middle, a tiny crown." % _first(looker)},
					_fx("q:aub_chain=seen"), _fx("xp:%s" % LehanQuests.CHECK_XP),
					{"n": "(Steward Hallam wears the vault's key: a ward-stone disc on a chain, not a key at all. It will open the door with no keyhole.)"}]
					+ ([{"sp": "That stone. They cut it from my own wards. It's my key, and he wears it on his neck like a dog's tag."}] if host != "" else [])) if ok
					else [{"n": "An hour passes. The gate opens once and shuts again behind somebody in black, too quickly to see more than a glint of something round on a chain."},
						{"n": "(Try again another time.)"}]},
			{"t": "Walk on.", "silent": true, "after": []},
		]})
	return out


## The servants' gate in the side lane: Bett from the kitchens.
static func servants_gate() -> Array:
	var host := _host()
	var talker := LehanQuests.best("talk")
	var ok := Game.check(talker, "talk", Game.NORMAL)
	var out: Array = [
		{"n": "A low wooden door in the black wall, for coal and carts and people who don't count. It opens as you reach it, and a girl backs out with a bucket of ashes, sees you, and nearly drops it."},
		{"s": "bett", "t": "Oh! You gave me a fright. Deliveries round the front. No, deliveries are here. What are you delivering?"},
	]
	if q("aub_servants") != "":
		out.append({"s": "bett", "t": "You again. I can't stop, Cook'll skin me. Second bell, the choir, the guards' cider. I never told you nothing."})
		return out
	var told := [
		{"s": "bett", "a": "glancing back at the door", "t": "Founders' Night? Worst night of the year. Two hundred guests, and the temple choir in at the second bell through this very door, and every guard in the house in the kitchen at midnight for the cider, steward or no steward."},
		{"s": "bett", "t": "And the steward going up and down to the old tower's cellar all night like a man with a sore tooth. There's a door down there nobody else goes near. Pell said..."},
		{"n": "She stops, and her face closes."},
		{"s": "bett", "t": "Pell was a footman. He's gone. Cellar's got an old grating to the drains under the tower, Cook says, all rusted, nobody's opened it in a hundred years. That's all I know. I never told you nothing."},
		_fx("q:aub_servants=told"),
		{"n": "(Founders' Night at House Morvane: the choir comes in at the second bell through the servants' gate; the guards are in the kitchen at midnight; the vault is under the old tower, and an old grating leads from that cellar to the drains.)"},
	]
	out.append({"choice": "servants", "options": [
		{"t": "Chat with her about the house, friendly.", "silent": true, "ok": ok,
			"checks": [LehanQuests.chk(talker, "talk", Game.NORMAL)],
			"after": told if ok else [{"s": "bett", "t": "I'm not to talk to people at the gate. Sorry."}, {"n": "(She hurries off. Another day, or a coin, might do it.)"}]},
		{"t": "Press a few coins into her hand (3 silver).", "silent": true, "tip": "Needs 3 silver in the party purse",
			"after": [_fx("pay:3"), {"s": "bett", "t": "Oh. Well. Just for a minute, then."}] + told},
		{"t": "Move on.", "silent": true, "after": []},
	]})
	return out


## The drain grate at the end of the lane: Below reaches up under the hill, and Sasska's mark.
static func drain() -> Array:
	var out: Array = [
		{"n": "An iron grate in the cobbles, each bar as thick as a wrist, set into a frame sunk in lead. Warm air comes up through it, smelling of the river and of something worse. Far down, water runs."},
		{"n": "Scratched into the kerb beside it, small and fresh, a mark in chalk: three claws."},
		_fx("q:aub_drain=seen"),
	]
	if q("aub_wick") != "":
		out.append({"n": "(Three claws: Sasska's mark. Below, Wick said, goes all the way up under the hill.)"})
	else:
		out.append({"n": "(Someone small uses these drains, and marks them.)"})
	if q("aub_servants") != "":
		out.append({"n": "(Bett said an old grating runs from the tower cellar down to the drains. From below, then.)"})
	return out


## The Lion house: Ysolde Marrin, champion, guest of the Lions, who despises the Morvanes.
static func lion_gate() -> Array:
	var host := _host()
	var out: Array = []
	if q("aub_ysolde") == "":
		out.append({"n": "Through the bars of the Lion gate: a yard of raked sand, and in it a woman with white-grey hair, alone, going through the forms of a long sword, slow and exact, as if every cut were a word in a sentence she knows by heart."})
		out.append({"n": "She finishes the form before she looks round."})
		out.append({"s": "ysolde", "t": "You've been standing at the Morvane gate. Everyone on the avenue saw. Nobody stands at that gate."})
		out.append({"s": host, "t": "Nobody answers it either."})
		out.append({"s": "ysolde", "a": "with something close to a smile", "t": "No. Ysolde Marrin. I'm the Lions' guest, which is to say their ornament; they like a famous sword at the table. Three hundred years the Morvanes have had a seat at every table in this city, and never once drawn steel for it. Whatever they keep behind that wall, they keep it badly hidden."})
		out.append({"s": "ysolde", "t": "If you find something rotten in that house, come and tell me. The Lions' table has empty chairs on Founders' Night, and I choose who sits in some of them."})
		out.append(_fx("q:aub_ysolde=met"))
		out.append(_fx("q:aub_invite=offered"))
		out.append({"n": "(Ysolde Marrin can seat guests at the Lion house's feast: a way to be on the hill on Founders' Night, in silk.)"})
		if host != "":
			out.append({"sp": "That one has fought real wars. You can see it in how she stands. She'd be worth ten of Aldric."})
	else:
		out.append({"n": "Ysolde Marrin is in the yard again, cutting the air in slow, exact strokes."})
		out.append({"s": "ysolde", "t": "Found anything rotten yet? Come back when you have."})
	return out


static func noble_gate() -> Array:
	return [{"n": "An iron gate under a crest: a ship, or a wheel, or a sheaf of wheat. Beyond it, a raked drive and a house of pale stone with every shutter closed. A guard on the other side watches you until you move on."}]


static func _watchman() -> Array:
	var nisk := _of_race(Game.NISK)
	var out: Array = [
		{"s": "watchman", "t": "Business on the hill? Then go about it, and keep to the avenue. The houses don't like people in the lanes."},
	]
	if not nisk.is_empty():
		out.append({"s": "watchman", "a": "staring at %s" % _first(nisk), "t": "And that one stays where I can see it."})
	if q("aub_drain") != "":
		out.append({"s": "watchman", "t": "Rats in the drains up here, big as dogs. Don't go poking at the grates."})
	return out
