class_name NorthRoad
extends RefCounted
## The four days from Lehan to Aubermont by the north road: on the first trip, a toll bridge over
## the Aube held by a lord's men who ask everyone where they come from (day 2), and Odo Brakk
## burying a dead traveller by the road (day 3). Same API as MarshRoad, whose effects it uses.
## See "The story onward" in IDEAS.md. Quest values: north_toll ("paid" / "talked" / "forded"),
## north_odo ("helped" / "prayed" / "cold"), north_asked (the toll men heard "Lehan").

## Which scene comes after which day of the first trip (1-based).
const SCENES := {2: "toll_bridge", 3: "gravedigger"}
const TOLL := 3   # silver a head at the bridge

const ODO := {"name": "Odo Brakk", "race": "Human",
	"look": {"skin": "#c89a74", "hair": "#9a9890", "cloth": "#4a4440", "legs": "#3a3430", "beard": true}}
const TOLLMAN := {"name": "Toll Sergeant", "race": "Human",
	"look": {"skin": "#d8b090", "hair": "#3a2a1a", "cloth": "#6a6a70", "legs": "#3a3a40"}}


static func _host() -> String:
	return Game.story.get("host", "")


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


static func _fx(fx: String) -> Dictionary:
	return {"fx": fx, "wait": 0.1}


static func cast() -> Dictionary:
	var c := MarshRoad.cast()
	c["odo"] = ODO
	c["tollman"] = TOLLMAN
	return c


static func scene(key: String) -> Array:
	match key:
		"toll_bridge": return _toll_bridge()
		"gravedigger": return _gravedigger()
	return []


static func apply(fx: String) -> String:
	return MarshRoad.apply(fx)


## Someone in the party of this race ({} if none).
static func _of_race(race: int) -> Dictionary:
	for c in Game.party:
		if c.race == race:
			return c
	return {}


static func _toll_bridge() -> Array:
	var host := _host()
	var price := TOLL * Game.party.size()
	var talker := LehanQuests.best("talk")
	var ok_talk := Game.check(talker, "talk", Game.NORMAL)
	var woods := LehanQuests.best("survival")
	var ok_ford := Game.check(woods, "survival", Game.NORMAL)
	var thuug := _of_race(Game.THUUG)
	var out: Array = [
		{"n": "On the second day the road comes down to the Aube, wide and brown and fast with snowmelt. A stone bridge crosses it, and on the bridge a pole across the road, a hut, and four men in grey-blue livery with halberds."},
		{"s": "tollman", "t": "Bridge toll. %d a head, by order of the House. And where are you coming from?" % TOLL},
	]
	var opts: Array = []
	opts.append({"t": "Pay the toll (%d silver)." % price, "silent": true, "tip": "Needs %d silver in the party purse" % price,
		"after": [{"s": host, "t": "From the south. Here's your silver."},
			{"s": "tollman", "t": "The south. Lehan way?"},
			{"s": host, "t": "That way, yes."},
			{"n": "The sergeant looks at each of them in turn, as if fixing their faces in his memory, before he lifts the pole."},
			_fx("pay:%d" % price), _fx("q:north_toll=paid"), _fx("q:north_asked=1")]})
	opts.append({"t": "Talk your way across: you're pilgrims, bound for the temples of Aubermont.", "silent": true, "say": host,
		"ok": ok_talk, "checks": [LehanQuests.chk(talker, "talk", Game.NORMAL)],
		"after": ([{"s": host, "t": "Pilgrims, from the coast villages. We carry nothing but our prayers for the temples in the old town."},
			{"s": "tollman", "t": "Pilgrims don't usually wear that much steel. But the House doesn't tax prayers. Go on, then."},
			{"n": "As the pole goes up, one of the guards mutters to another: \"Not from Lehan, then. That's what they want to know about, the grey ones. Anyone from Lehan, anyone asking after old shrines.\""},
			_fx("q:north_toll=talked"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok_talk
			else [{"s": host, "t": "Pilgrims, from the coast villages. We carry nothing but our prayers for the temples in the old town."},
				{"s": "tollman", "t": "Pilgrims. With swords. From the south, I'd say, by the boots: Lehan way. Double toll for liars, or turn round."},
				{"n": "(It will have to be the toll, double, or the river.)"},
				{"choice": "toll_again", "options": [
					{"t": "Pay double (%d silver)." % (price * 2), "silent": true,
						"after": [_fx("pay:%d" % (price * 2)), _fx("q:north_toll=paid"), _fx("q:north_asked=1"),
							{"n": "The sergeant takes the silver and writes something on a slate. He doesn't say what."}]},
					_ford_option(thuug, woods, ok_ford),
				]}])})
	opts.append(_ford_option(thuug, woods, ok_ford))
	out.append({"choice": "toll_bridge", "options": opts})
	return out


## Crossing the Aube without the bridge: a Thuug swims a rope across (they swim well, if slowly),
## or the best at Survival finds a ford.
static func _ford_option(thuug: Dictionary, woods: Dictionary, ok_ford: bool) -> Dictionary:
	if not thuug.is_empty():
		var nm := _first(thuug)
		return {"t": "Cross upstream, out of sight: %s swims a rope across." % nm, "silent": true,
			"tip": "Thuugs swim well, if slowly, and hold their breath a long time.",
			"after": [{"n": "A mile upstream, behind a bend, %s ties the rope round the middle and walks into the river, and keeps walking until the brown water closes over the shell. A long while later a head comes up on the far bank, unhurried." % nm},
				{"n": "The others cross hand over hand on the rope, soaked to the neck and cursing the cold. The toll men never see a thing."},
				_fx("tired:5"), _fx("q:north_toll=forded"), _fx("xp:%s" % LehanQuests.CHECK_XP),
				{"n": "(Everyone is cold and wet: −5 Endurance. No toll, and nobody asked where you came from.)"}]}
	return {"t": "Look for a ford upstream, out of sight of the bridge.", "silent": true, "ok": ok_ford,
		"checks": [LehanQuests.chk(woods, "survival", Game.NORMAL)],
		"after": ([{"n": "%s reads the river: the riffles, the colour of the water over gravel. A mile upstream it spreads wide and shallow, and the party wades across waist-deep." % _first(woods)},
			_fx("tired:5"), _fx("q:north_toll=forded"), _fx("xp:%s" % LehanQuests.CHECK_XP),
			{"n": "(Cold and wet: −5 Endurance. No toll, and nobody asked where you came from.)"}] if ok_ford
			else [{"n": "The ford %s picks is deeper than it looked. Halfway across the current takes someone's feet, and it's a scramble to haul them out." % _first(woods)},
				_fx("hurtone:4"), _fx("tired:10"), _fx("q:north_toll=forded"),
				{"n": "(Everyone is soaked and worn out: −10 Endurance. But you're across, and unseen.)"}])}


static func _gravedigger() -> Array:
	var host := _host()
	var strong := LehanQuests.best("toughness")
	var ok_dig := Game.check(strong, "toughness", Game.NORMAL)
	var pious := {}
	for c in Game.party:
		if "Pious" in c.get("traits", []):
			pious = c
			break
	var news: Array = [
		{"s": "odo", "t": "Aubermont. Four hills, ten thousand chimneys, and the great houses up top behind their own wall, looking down on the rest of us. I bury the poor in the old town. There's always work."},
		{"s": "odo", "t": "This one came from there. A servant, by his hands. Ran from somewhere, I'd say, with nothing in his pack but a crust and fear. Men in grey cloaks have been asking questions down in the old town. About shrines in the south, of all things."},
		{"s": "odo", "t": "If you're going in, find me among the graves behind the Temple of the Hours. Somebody will need burying by then, and I'll have time to talk."},
	]
	var out: Array = [
		{"n": "On the third day, at a bend where the road climbs out of the river valley, a big grey-haired man is digging a grave in the verge. Beside it, under a cloak, lies a shape the size of a man."},
		{"s": "odo", "a": "without stopping", "t": "Found him in the ditch this morning. No name. Doesn't matter to the ground. You can walk on; most do."},
	]
	var opts: Array = []
	opts.append({"t": "Take a spade and help him dig.", "silent": true, "ok": ok_dig,
		"checks": [LehanQuests.chk(strong, "toughness", Game.NORMAL)],
		"after": ([{"n": "%s takes the second spade. The ground is stony, but between them the grave is deep and square by noon." % _first(strong)},
			{"s": "odo", "t": "You dig like a soldier. I was one. Odo Brakk. I walk the roads and bury what I find."}] + news
			+ [_fx("q:north_odo=helped"), _fx("xp:%s" % LehanQuests.CHECK_XP)]) if ok_dig
			else [{"n": "%s digs until the blisters burst, and the grave is still shallow when the light starts to go. Odo finishes it alone, without a word of complaint." % _first(strong)},
				_fx("tired:10"),
				{"s": "odo", "t": "Thank you for trying. Odo Brakk. I walk the roads and bury what I find."}] + news
				+ [_fx("q:north_odo=helped")]})
	if not pious.is_empty():
		var pk := LehanQuests.key_of(pious)
		opts.append({"t": "%s says the words for the dead." % _first(pious), "silent": true,
			"after": [{"s": pk, "t": "Whoever you were, the road is done. Rest now."} if pk != "" else {"n": "%s says the old words over the grave, low and steady." % _first(pious)},
				{"s": "odo", "a": "leaning on the spade", "t": "Nobody's said words over one of mine in a long while. Thank you. Odo Brakk."}] + news
				+ [_fx("q:north_odo=prayed"), _fx("xp:%s" % LehanQuests.CHECK_XP)]})
	opts.append({"t": "Search the dead man's pack first.", "silent": true,
		"after": [{"n": "In the pack: a heel of bread gone green, eight silver pieces sewn into the lining, and a scrap of paper with a crest drawn on it, a tower and a key, and nothing else."},
			_fx("silver:8"), _fx("q:north_odo=cold"),
			{"s": "odo", "t": "He won't need it, I suppose. Neither will I want your company. Go on."},
			{"n": "(You find 8 silver and a scrap of paper with a crest: a tower and a key.)"}]})
	opts.append({"t": "Walk on.", "silent": true, "after": [{"s": "odo", "t": "Most do."}]})
	if host != "":
		out.append({"sp": "Another body by the road. They're everywhere, once you start counting. Were they always?"})
	out.append({"choice": "gravedigger", "options": opts})
	return out


## The first sight of Aubermont, added to the arrival summary on the first trip.
static func first_sight() -> String:
	return "Aubermont: walls of soot-black stone climbing four hills above the mouth of the Aube. Spires and steep roofs crowd together under a low grey sky, and ten thousand chimneys smoke. On the highest hill, behind a second wall, the great houses look down on it all."
