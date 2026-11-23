class_name MarshData
extends RefCounted
## Who lives in Oggal, the Thuug stilt village on the causeway (MarshVillage), and what they say.
## Quest values (LehanQuests q:key=value): marsh_orrun ("trust" / "wary"), marsh_ubba ("told"),
## marsh_leeches ("asked": Moss's fish pens, the village's favour for the opening chant; done in
## the shrine step), marsh_grath ("won" / "lost"), marsh_wenna (from the road, MarshRoad).

const PEOPLE := {
	"1": {"key": "orrun", "name": "Orrun", "race": "Thuug", "height": 1.8,
		"look": {"skin": "#6a7a4a", "shell": "#4a4030", "cloth": "#5a5040", "legs": "#3a3428"}},
	"2": {"key": "ubba", "name": "Ubba", "race": "Thuug", "height": 1.45,
		"look": {"skin": "#7a8458", "shell": "#5a4a34", "cloth": "#6a4a6a", "hood": true}},
	"3": {"key": "grath", "name": "Grath-Ul", "race": "Thuug", "height": 1.95,
		"look": {"skin": "#5a6a3a", "shell": "#3a3020", "cloth": "#4a3a28", "legs": "#2a2418"}},
	"4": {"key": "pim", "name": "Pim", "race": "Thuug", "height": 1.05,
		"look": {"skin": "#8a9a60", "shell": "#6a5a3a", "cloth": "#8a6a3a"}},
	"5": {"key": "moss", "name": "Old Moss", "race": "Thuug", "height": 1.5,
		"look": {"skin": "#6a7454", "shell": "#4a4032", "cloth": "#4a5a5a", "hat": true}},
}
const HETT := {"name": "Hett", "race": "Thuug",
	"look": {"skin": "#76804e", "shell": "#5a4630", "cloth": "#7a5a3a", "apron": true}}

## Hett's stall (the shop screen with {"shop": "marsh"}): fish, herbs, rope, arrows, and two things
## of marsh iron and shell. Hett buys anything with a price that isn't a quest item.
const TRADER := {"name": "Hett's Stall", "price_mod": 1.0, "buys": "anything",
	"stock": [51, 29, 28, 27, 13, 52, 53], "back": ["village", {"at": "trader"}]}
const TRADER_TALK := [
	"\"Fish, roots, rope. Arrows for the birds. Iron from the bog, shell from the river. What else would anyone need?\"",
	"\"Lehan silver spends here. Lehan manners less so.\"",
	"\"That spear's bog-iron. Dug it out of the peat myself. It'll outlast your grandchildren.\"",
	"\"Going to the drowned house? Then buy rope. Everyone who comes back from there wishes they'd had more rope.\"",
]


static func q(key: String) -> String:
	return LehanQuests.get_q(key)


static func cast() -> Dictionary:
	var c := PrologueData.company_cast()
	c.merge(LehanQuests.cast())
	for k in PEOPLE:
		var p: Dictionary = PEOPLE[k]
		c[p.key] = {"name": p.name, "race": p.race, "look": p.look}
	c["hett"] = HETT
	c["wenna"] = MarshRoad.WENNA
	return c


static func _fx(fx: String) -> Dictionary:
	return {"fx": fx, "wait": 0.1}


static func _host() -> String:
	return Game.story.get("host", "")


## The company member with this cast key, if they are in the party (the host too).
static func _with(key: String) -> Dictionary:
	for c in Game.party:
		if LehanQuests.key_of(c) == key:
			return c
	return {}


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


# ---------------------------------------------------------------- Orrun at the gate

## The first time the party comes in off the causeway: Orrun bars the way.
static func meet_orrun() -> Array:
	var host := _host()
	var out: Array = [
		{"n": "The causeway passes under a frame of two tall posts hung with bone charms. Beyond it, boardwalks run between reed huts on stilts, and smoke hangs low over the water. A broad Thuug in a coat of shell plates steps out with a spear and plants it across the planks."},
		{"s": "orrun", "t": "Hold. Strangers don't come down the causeway in a crowd. What do you want in Oggal?"},
	]
	var ommuk := _with("ommuk")
	if not ommuk.is_empty():
		out.append({"s": "ommuk", "t": "Orrun. You still hold that gate as if it owes you money."})
		out.append({"s": "orrun", "a": "lowering the spear", "t": "Ommuk? Ommuk of the reed pens! They said you'd gone off to carry swords for Lehan folk. Your friends are welcome, then. Ubba will want to see you."})
		out.append(_fx("q:marsh_orrun=trust"))
		return out
	if q("marsh_wenna") == "friend":
		out.append({"s": host, "t": "Wenna the salt trader sent us. We pulled her cart out of the mud on the causeway."})
		out.append({"s": "orrun", "a": "lowering the spear", "t": "Wenna doesn't send fools, and she doesn't thank people she doesn't like. Come in. Keep to the boards."})
		out.append(_fx("q:marsh_orrun=trust"))
		return out
	var talker := LehanQuests.best("talk")
	var ok_truth := Game.check(talker, "talk", Game.EASY)
	var ok_lie := Game.check(talker, "talk", Game.HARD)
	out.append({"choice": "orrun", "options": [
		{"t": "Tell him the truth: you have come for the old shrine.", "silent": true, "say": host, "ok": ok_truth,
			"checks": [LehanQuests.chk(talker, "talk", Game.EASY)],
			"after": [{"s": host, "t": "We've come for the old shrine out on the water. Something of ours was drowned there, long ago."},
				{"s": "orrun", "t": "The drowned house. Then you're fools." },
				{"s": "orrun", "t": "But honest fools. Come in. Ubba will want to look at you." if ok_truth
					else "Honest, maybe. But I don't like the look of you. Come in, keep to the boards, and know that I'm watching."},
				_fx("q:marsh_orrun=trust" if ok_truth else "q:marsh_orrun=wary")]},
		{"t": "Say you're traders, looking for fish and a roof for the night.", "silent": true, "say": host, "ok": ok_lie,
			"checks": [LehanQuests.chk(talker, "talk", Game.HARD)],
			"after": [{"s": host, "t": "Traders. We want fish, and a roof for the night."},
				{"s": "orrun", "t": "Then Hett has fish, and the guest hut has a roof. Come in." if ok_lie
					else "Traders. With those swords, and no goods. You lie badly, stranger. Come in anyway, the marsh is no place to sleep. But I'm watching you."},
				_fx("q:marsh_orrun=trust" if ok_lie else "q:marsh_orrun=wary")]},
	]})
	return out


static func _orrun() -> Array:
	if q("marsh_orrun") == "wary":
		return [{"s": "orrun", "t": "Keep to the boards, stranger. I'm watching you."},
			{"n": "(Orrun doesn't trust you yet. Helping the village might change that.)"}]
	var out: Array = [{"s": "orrun", "t": "The causeway's quiet, which is how I like it. Mostly."}]
	out.append({"s": "orrun", "t": "A month ago, strangers in grey cloaks came through. Lehan accents, good silver. They asked about the drowned house and went out on the causeway. Fewer came back, and those didn't stop to talk."})
	out.append({"s": "orrun", "t": "And at night, don't follow the lights over the water. Whatever they are, they want you in it."})
	return out


# ---------------------------------------------------------------- Ubba

static func _ubba() -> Array:
	var host := _host()
	var out: Array = []
	var ommuk := _with("ommuk")
	if q("marsh_ubba") == "":
		out.append({"n": "An old Thuug woman sits outside her hut, mending a net with fingers that know the work without her."})
		if not ommuk.is_empty():
			out.append({"s": "ubba", "t": "Little Ommuk. All grown, and gone wandering with strangers. Your mother would have boxed your ears."})
			out.append({"s": "ommuk", "t": "She did, before I left. Twice."})
		out.append({"s": "ubba", "t": "So. You want to hear about the drowned house. Everyone who comes this far does."})
		out.append({"s": "ubba", "t": "My grandmother had it from hers. A king came down from the hills, crowned in iron. He made our people carry stone out into the marsh, year after year, to build him a house on the water. Those who dropped their stones, he dropped into the water after them."})
		if host != "":
			out.append({"sp": "Iron on my brow. Stone going down into black water, one block after another. I remember the weight of it. I remember not caring."})
		out.append({"s": "ubba", "t": "Then his own lords turned on him. They took something out of the hills and drowned it in his house, and sealed the door. Since then the water there has never cleared."})
		out.append({"s": "ubba", "t": "There is a door under the house that answers to the old chant. My grandmother taught it to me. But the chant is for friends of Oggal."})
		out.append(_fx("q:marsh_ubba=told"))
	if q("marsh_leeches") == "":
		out.append({"s": host, "t": "How does one become a friend of Oggal?"})
		out.append({"s": "ubba", "t": "By being one. Leeches have got into Old Moss's fish pens, big as eels, and the children go hungry. Clear them, and we will talk about chants."})
		out.append(_fx("q:marsh_leeches=asked"))
		out.append({"n": "(Old Moss by the boat knows where the pens are: in the shrine grounds, out along the causeway east.)"})
	elif q("marsh_leeches") == "asked":
		out.append({"s": "ubba", "t": "The leeches are still in Moss's pens. Friends of Oggal, I said."})
	elif q("marsh_chant") == "":
		out.append({"s": "ubba", "t": "You cleared the pens. The children are eating tonight. Come, then: I will teach you the chant."})
		out.append({"n": "She sings it three times, low, a tune that rises and falls like water over stones, and makes you sing it back until she stops wincing."})
		out.append(_fx("q:marsh_chant=1"))
		out.append({"n": "(You know the old chant. Sing it at the sunken door.)"})
	else:
		out.append({"s": "ubba", "t": "Sing it slowly at the door. It is older than the stones."})
	if q("s_remnant") != "":
		out.append({"s": "ubba", "t": "Moss went out to his pens this morning and came back running. The water by the drowned house is clear, he says. Clear to the bottom, for the first time since my grandmother's grandmother."})
		out.append({"s": "ubba", "a": "looking at the host for a long moment", "t": "Whatever you took out of there, I hope you know what to do with it."})
	elif q("s_hall") != "" and q("s_path") == "" and q("marsh_song") == "":
		out.append_array(_song_ask(ommuk))
	elif q("marsh_song") != "":
		out.append({"s": "ubba", "t": "Crown, rose, fire, chain, and the water. Mind your feet on those stones."})
	if ommuk.is_empty() and Game.party.any(func(c): return "Pious" in c.get("traits", [])) and q("marsh_ubba") != "":
		out.append({"s": "ubba", "t": "One of you prays, I can tell. Good. Pray hard out there."})
	return out


## After the party has seen the flooded hall: Ubba knows a children's rhyme about the drowned
## house that tells the stones' order. Friends of Oggal (or Ommuk) just get it; others must ask well.
static func _song_ask(ommuk: Dictionary) -> Array:
	var host := _host()
	var sing: Array = [
		{"s": "ubba", "a": "after a long look", "t": "Stones with signs on them, in a hall of water. Hm. The children have a rhyme for skipping, older than any of them. Nobody remembers what it is about. Listen."},
		{"n": "She sings it in the flat sing-song of a skipping game:\n\n%s" % ShrineQuest.SONG},
		_fx("q:marsh_song=1"), _fx("q:s_path=known"),
		{"n": "(Ubba's rhyme: crown, rose, fire, chain, and the water.)"},
	]
	if host != "":
		sing.append({"sp": "Children skip to it. They skip to what I did."})
	var out: Array = [{"s": host, "t": "Down in the temple there's a hall full of water, and stepping stones with signs cut into them. Do the old stories say anything about them?"}]
	if not ommuk.is_empty() or q("marsh_leeches") == "done":
		out.append_array(sing)
		return out
	var talker := LehanQuests.best("talk")
	var ok := Game.check(talker, "talk", Game.NORMAL)
	out.append({"s": "ubba", "t": "And why would I tell strangers what the drowned house wants? You haven't done one thing for Oggal."})
	out.append({"choice": "song", "options": [
		{"t": "Ask her for the sake of whatever is down there: it should not stay there.", "silent": true, "say": host, "ok": ok,
			"checks": [LehanQuests.chk(talker, "talk", Game.NORMAL)],
			"after": ([{"s": host, "t": "Whatever is in that basin has poisoned your water for longer than anyone can remember. Help us take it out."}] + sing) if ok
				else [{"s": host, "t": "Whatever is in that basin has poisoned your water for longer than anyone can remember. Help us take it out."},
					{"s": "ubba", "t": "Pretty words. Clear Moss's pens, and then we'll talk about songs."}]},
		{"t": "Leave it for now.", "silent": true, "after": []},
	]})
	return out


# ---------------------------------------------------------------- Grath-Ul, Pim and Old Moss

static func _grath() -> Array:
	if q("marsh_grath") == "won":
		return [{"s": "grath", "t": "Ha! The one who threw me. Twenty years, and a stranger. Best day I've had in ages."}]
	if q("marsh_grath") == "lost":
		return [{"s": "grath", "t": "Back for another throw? Come back when you've eaten more fish."}]
	var strong := LehanQuests.best("toughness")
	var ok := Game.check(strong, "toughness", Game.HARD)
	return [
		{"n": "The biggest Thuug you have ever seen is sitting on an upturned boat, yawning."},
		{"s": "grath", "t": "Grath-Ul. Twenty years, nobody in the marsh has thrown me. I am so bored. You. The big one. Wrestle?"},
		{"choice": "grath", "options": [
			{"t": "%s takes him on." % _first(strong), "silent": true, "ok": ok, "checks": [LehanQuests.chk(strong, "toughness", Game.HARD)],
				"after": ([{"n": "They lock arms. The boardwalk groans. For a long moment nothing moves; then %s twists, and Grath-Ul goes over with a crash that shakes every hut in Oggal." % _first(strong)},
					{"s": "grath", "a": "laughing flat on his back", "t": "Ha! HA! Twenty years! Tell everyone! No, I'll tell everyone!"},
					_fx("q:marsh_grath=won"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
					else [{"n": "%s gets a grip, and then the sky and the water change places. Grath-Ul is very apologetic, and very pleased." % _first(strong)},
						_fx("hurtone:3"), _fx("q:marsh_grath=lost"),
						{"s": "grath", "t": "Good try! Again some day."}])},
			{"t": "Not today.", "silent": true, "after": [{"s": "grath", "t": "Nobody ever wants to. Sigh."}]},
		]},
	]


static func _pim() -> Array:
	var lines := [
		"Don't follow the lights over the water! Mother says they want you in it, and then you're a light too.",
		"When the water rises the bell in the drowned house rings. Under the water. You can hear it from the boats.",
		"The grey people paid me a copper to show them the stepping stones. They didn't say thank you.",
		"Are you going to the drowned house? Can I come? No? Nobody ever lets me.",
	]
	var i := int(Game.story.get("pim_i", 0))
	Game.story["pim_i"] = i + 1
	return [{"s": "pim", "t": lines[i % lines.size()]}]


static func _moss() -> Array:
	match q("marsh_leeches"):
		"asked", "":
			if q("marsh_leeches") == "" and q("marsh_ubba") == "":
				return [{"s": "moss", "t": "Fish don't bite. Something's eating them first. Talk to Ubba, she decides who helps with what around here."}]
			return [{"s": "moss", "t": "The pens are inside the old shrine's walls, south-west, where the water's warm. Leeches long as your arm. They take the fish and they take fingers."},
				{"n": "(The fish pens are in the shrine grounds, out along the causeway east.)"}]
		"done":
			return [{"s": "moss", "t": "Fish in the pens again. Fish in the pot. You'll eat with us tonight, and every night you like."}]
	return []


## The conversation with the person on map digit `id`.
static func talk(id: String) -> Array:
	match PEOPLE[id].key:
		"orrun": return _orrun()
		"ubba": return _ubba()
		"grath": return _grath()
		"pim": return _pim()
		"moss": return _moss()
	return []
