class_name CouncilData
extends RefCounted
## The council house of Lehan: taking the mines job and haggling over the pay (see "The town
## council" in IDEAS.md). The crier's notice puts the council house on the map; the company
## takes the job here, and only then do the Mines appear on the world map.
##
## Haggling runs in rounds. Each round offers the arguments not yet tried; ability checks use the
## best in the party (they speak it), trait arguments are the host's own. A failed argument costs
## the council's patience; at none left they make a final offer. Who is in the party matters:
## Joss's name is known, a Nisk is not trusted, an Aeldroe interests Hale.
##
## State in Game.story.council: {offer, patience, tried: [keys], advance, accepted, met}.

const BASE_OFFER := 150
const ALONE_OFFER := 110
const PATIENCE := 3
const WIN_XP := 0.1   # story experience for each argument won with an ability
const BOLD := 10      # "double it": harder than a normal check, but in reach of a starting talker

const CAST := {
	"brask": {"name": "Mistress Odile Brask", "race": "Human",
		"look": {"skin": "#e8c8a8", "hair": "#a8a8a0", "cloth": "#4a2a3a", "legs": "#2a2026", "hood": true}},
	"hale": {"name": "Master Corvin Hale", "race": "Human",
		"look": {"skin": "#d8b088", "hair": "#2a1e16", "cloth": "#2a4a3a", "legs": "#2a2a2a"}},
	"brannoc": {"name": "Alderman Brannoc", "race": "Human",
		"look": {"skin": "#d0a080", "hair": "#e0e0d8", "cloth": "#6a4a20", "legs": "#3a3020", "beard": true}},
}
## Their seats behind the table, left to right, with a line for the screen.
const SEATS := [
	["brannoc", "Alderman Brannoc", "thirty years on the council"],
	["brask", "Mistress Brask", "keeper of the town's purse"],
	["hale", "Master Hale", "owner of the old workings"],
]


static func cast() -> Dictionary:
	var c := PrologueData.company_cast()
	c.merge(CAST, true)
	c.merge(LehanQuests.cast(), true)
	return c


static func state() -> Dictionary:
	if not Game.story.has("council"):
		Game.story["council"] = {"offer": BASE_OFFER, "patience": PATIENCE, "tried": [], "advance": 0,
			"accepted": false, "met": false}
	return Game.story.council


static func accepted() -> bool:
	if not Game.story.has("council"):
		return "mines" in Game.known   # old saves knew the mines straight from the crier
	return state().accepted


## The cast key of a party member ("" for someone who is not one of the company).
static func key_of(c: Dictionary) -> String:
	for k in PrologueData.ORDER:
		if PrologueData.CAST[k].name == c.name:
			return k
	return ""


static func _in_party(key: String) -> bool:
	for c in Game.party:
		if key_of(c) == key:
			return true
	return false


static func _lisbet_in_party() -> bool:
	for c in Game.party:
		if c.name == LehanQuests.RECRUITS.lisbet.name:
			return true
	return false


static func _race_in_party(race: int) -> bool:
	for c in Game.party:
		if c.race == race:
			return true
	return false


## The party member best at an ability (the host wins ties), as [character, cast key].
static func _best(ability: String) -> Array:
	var best: Dictionary = Game.party[0]
	for c in Game.party:
		if Game.ability(c, ability) > Game.ability(best, ability):
			best = c
	return [best, key_of(best)]


static func _host_traits() -> Array:
	var host: String = Game.story.get("host", "")
	return PrologueData.CAST[host].traits if host != "" else []


static func _say(who: String, t: String) -> Dictionary:
	# A line from a party member, or narration if they are not one of the company.
	return {"s": who, "t": t} if who != "" else {"n": t}


# ---------------------------------------------------------------- the visit

## What happens on entering. Returns the steps up to the first choice (or the whole visit).
static func visit() -> Array:
	var st := state()
	var host: String = Game.story.get("host", "")
	if accepted():
		return _after_job()
	var out: Array = []
	if not st.met:
		st.met = true
		out.append({"n": "A long hall with a smoky fire at one end. Three councillors sit behind a table scarred with knife marks and old wine."})
		out.append({"s": "brask", "t": "You've come about the notice. Good. We were starting to think Lehan had run out of fools."})
		out.append_array(_first_impressions())
		out.append({"s": "brask", "t": "Six miners went up to the old workings and did not come back. Find out what became of them. Bring them home if you can."})
		out.append({"s": "brask", "t": "For that, the council offers %s, paid when you return with news." % _coins(st.offer)})
		if host != "":
			out.append({"i": "Old workings. Sealed long ago, the stone remembers. The spirit listens harder than its host does."})
	else:
		out.append({"s": "brask", "t": "Back again. The offer still stands: %s. Have you thought it over?" % _coins(st.offer)})
		st.patience = maxi(st.patience, 1)
	out.append(haggle_round())
	return out


## Who the council sees in front of them, and what it does to the offer and their patience.
static func _first_impressions() -> Array:
	var st := state()
	var out: Array = []
	if Game.party.size() == 1:
		st.offer = ALONE_OFFER
		out.append({"s": "brannoc", "t": "One? The notice asked for a company, not a wanderer with a sword and an empty purse."})
	if _in_party("joss"):
		st.offer += 20
		out.append({"s": "brannoc", "t": "Joss Harrow. I know that name. The Harrow Company cleared the Blackfen road two winters back."})
		out.append({"s": "joss", "t": "And we'll clear your hills, Alderman. For the right price."})
	if _race_in_party(Game.NISK):
		st.patience -= 1
		out.append({"s": "brannoc", "t": "And a Nisk. Count the candlesticks when they leave, Brask."})
		if _in_party("tikkat"):
			out.append({"s": "tikkat", "t": "Only the silver ones, Alderman. Brass is beneath me."})
	if _race_in_party(Game.THUUG):
		out.append({"s": "brannoc", "t": "A Thuug, too. Well, at least that one will be too slow to run away."})
		if _in_party("ommuk"):
			out.append({"s": "ommuk", "t": "Slow to run, and slow to forget, Alderman."})
	if _race_in_party(Game.AELDROE):
		out.append({"s": "hale", "t": "An Aeldroe. Can you read old marks? The workings have a few. Never mind. Later, perhaps."})
	return out


## One round of haggling: the arguments not tried yet, or the final offer.
static func haggle_round() -> Dictionary:
	var st := state()
	var opts: Array = []
	var host: String = Game.story.get("host", "")
	opts.append({"key": "accept", "t": "We'll take it. %s." % _coins(st.offer)})
	if st.patience > 0:
		var talker: Array = _best("talk")
		var noticer: Array = _best("perception")
		if not "danger" in st.tried:
			opts.append({"key": "danger", "say": talker[1], "tip": "Talk (the best in the party speaks)",
				"t": "Six men gone, and whatever took them is still up there. That's worth more than %s." % _coins(st.offer)})
		if Game.story.get("council_purse", false) and not "purse" in st.tried:
			opts.append({"key": "purse", "tip": "What Lisbet's letter said: no check needed",
				"t": "We know the council has four hundred set aside for the miners. Don't insult us."})
		if not "hale" in st.tried:
			opts.append({"key": "hale", "say": noticer[1], "tip": "Perception (the best in the party speaks)",
				"t": "Master Hale hasn't said a word. It's your family's mine, isn't it? What's really up there?"})
		var traits := _host_traits()
		if not "trait" in st.tried and host != "":
			var o := _trait_option(traits)
			if not o.is_empty():
				o["say"] = host
				opts.append(o)
	opts.append({"key": "leave", "t": "We'll think on it.", "tip": "Leave; the offer stands"})
	for o in opts:
		if o.get("say", host) == "":
			o.erase("say")   # not one of the company: the line is just the choice
		elif not o.has("say"):
			o["say"] = host
		if o.has("say"):
			o["portrait"] = o.say   # shows who speaks the argument
	var prompt := "Choose (1-%d)" % opts.size()
	if st.patience <= 0:
		prompt = "The council's patience is gone. Take the offer, or leave it for now."
	return {"choice": "haggle", "options": opts, "prompt": prompt}


## An argument from the host's own nature (the first trait that has one).
static func _trait_option(traits: Array) -> Dictionary:
	for t in traits:
		match t:
			"Greedy", "Proud":
				return {"key": "trait", "kind": "double", "tags": [t], "tip": "Talk, hard",
					"t": "Double it, or find another fool to send up your hill."}
			"Hot-tempered":
				return {"key": "trait", "kind": "double", "tags": [t], "tip": "Talk, hard",
					"t": "Six men dead and you count coppers? Double it, or go up there yourselves!"}
			"Honest", "Pious", "Generous":
				return {"key": "trait", "kind": "fair", "tags": [t],
					"t": "We'd go for the miners' sake. Pay what's fair, and put something by for their families."}
			"Cowardly":
				return {"key": "trait", "kind": "advance", "tags": [t], "tip": "Talk, easy",
					"t": "Half now. In case we, er, don't come back to collect."}
			"Melancholy":
				return {"key": "trait", "kind": "advance", "tags": [t], "tip": "Talk, easy",
					"t": "Half now. The dead don't spend much, but the living have to buy rope."}
			"Curious":
				return {"key": "trait", "kind": "curious", "tags": [t], "tip": "Lore",
					"t": "What did the miners find up there? Something made them dig where they shouldn't."}
			"Brave":
				return {"key": "trait", "kind": "brave", "tags": [t], "tip": "Talk, easy",
					"t": "We'll go whatever you pay. But we'd go better armed, and that costs."}
	return {}


## What a chosen argument does. Returns the steps that follow it (ending with the next round,
## or with "end" when the company accepts or leaves).
static func resolve(o: Dictionary) -> Array:
	var st := state()
	var out: Array = []
	var key: String = o.key
	if key != "accept" and key != "leave":
		st.tried.append(key)
	match key:
		"accept":
			return _accept()
		"leave":
			out.append({"s": "brask", "t": "Think quickly. The miners won't wait, and neither will the council."})
			out.append({"end": true})
			return out
		"danger":
			var who: Array = _best("talk")
			if Game.check(who[0], "talk", Game.NORMAL):
				st.offer += 30
				Game.story_xp(WIN_XP)
				out.append({"s": "brask", "t": "...True enough. %s, then, and not a piece more." % _coins(st.offer)})
				out.append({"n": "(%s's Talk won the argument. The offer rises to %s.)" % [who[0].name, _coins(st.offer)]})
			else:
				st.patience -= 1
				out.append({"s": "brask", "t": "Danger is why we pay at all. Don't tell me my business."})
				out.append({"n": "(The argument falls flat. The council's patience wears thin.)"})
		"hale":
			out.append_array(_press_hale(_best("perception"), "perception", 0))
		"purse":
			st.offer = maxi(st.offer + 60, 220)
			out.append({"n": "Brask goes very still. Brannoc turns to look at her."})
			out.append({"s": "brask", "t": "...Lisbet Farrow. That girl will hang one day, and I'll buy a good seat."})
			out.append({"s": "brask", "t": "%s. And if you repeat that number outside this room, the offer is gone." % _coins(st.offer)})
			if _lisbet_in_party():
				out.append({"s": "lisbet", "t": "Lovely to see you too, Mistress Brask."})
		"trait":
			out.append_array(_trait_result(o))
	if st.patience <= 0:
		out.append({"s": "brask", "t": "Enough. %s, and that is the council's last word." % _coins(st.offer)})
	out.append(haggle_round())
	return out


## Pressing Hale about the old workings (Perception, or Lore for a Curious host).
static func _press_hale(who: Array, ability: String, bonus: int) -> Array:
	var st := state()
	var out: Array = []
	if Game.check(who[0], ability, Game.NORMAL, bonus):
		st.offer += 40
		Game.story["council_hale_secret"] = true
		Game.story_xp(WIN_XP)
		out.append({"n": "Hale's thumb works at a ring on his finger. He doesn't meet anyone's eye."})
		out.append({"s": "hale", "t": "...My grandfather sealed the lower galleries. Bad air, he said. The miners broke through the old wall last month."})
		out.append({"s": "hale", "t": "I'll add forty of my own. And I'd take it kindly if what you find up there came to me first."})
		out.append({"s": "brannoc", "t": "Sealed galleries. You never mentioned that at the table, Hale."})
		out.append({"n": "(%s saw through Hale. The offer rises to %s.)" % [who[0].name, _coins(st.offer)]})
		var host: String = Game.story.get("host", "")
		if host != "":
			out.append({"i": "Sealed. The word rings like a bell somewhere deep. The spirit knows sealed places."})
	else:
		st.patience -= 1
		out.append({"s": "hale", "t": "Rock and dark and six fools who should have stayed home. What else would be up there?"})
		out.append({"n": "(Hale gives nothing away. The council's patience wears thin.)"})
	return out


static func _trait_result(o: Dictionary) -> Array:
	var st := state()
	var out: Array = []
	var host_c: Dictionary = Game.party[0]
	match o.kind:
		"double":
			if Game.check(host_c, "talk", BOLD):
				st.offer += 60
				Game.story_xp(WIN_XP)
				out.append({"n": "A long silence. Brask and Brannoc look at each other."})
				out.append({"s": "brask", "t": "Not double. But %s. You have a nerve, I'll give you that." % _coins(st.offer)})
			else:
				st.patience -= 2
				st.offer = maxi(ALONE_OFFER - 20, st.offer - 20)
				out.append({"s": "brannoc", "t": "Then we'll find another fool. There are plenty in Lehan, and they're cheaper."})
				out.append({"s": "brask", "t": "%s. Less, for the cheek. Don't push us further." % _coins(st.offer)})
		"fair":
			st.offer += 15
			st.patience += 1
			out.append({"n": "Brannoc grunts, and for once he doesn't have an answer ready."})
			out.append({"s": "brask", "t": "...Fifteen more, for the families. And you'll have it in writing."})
		"advance":
			if Game.check(host_c, "talk", Game.EASY):
				st.advance = st.offer / 2
				out.append({"s": "brask", "t": "Half now, half on your return. If you run off with it, Brannoc will hunt you down himself."})
				out.append({"n": "(Half the pay, %s, will be paid when you take the job.)" % _coins(st.advance)})
			else:
				st.patience -= 1
				out.append({"s": "brask", "t": "We pay for results, not for promises."})
		"curious":
			out.append_array(_press_hale(_best("lore"), "lore", 2))
			if not "hale" in st.tried:
				st.tried.append("hale")
		"brave":
			if Game.check(host_c, "talk", Game.EASY):
				st.offer += 20
				out.append({"s": "brannoc", "t": "Ha! Someone with a spine. Give them twenty for steel, Brask."})
			else:
				out.append({"s": "brannoc", "t": "Brave words are cheap. That's why we don't pay for them."})
	return out


static func _accept() -> Array:
	var st := state()
	st.accepted = true
	Game.story["mines_job"] = {"pay": st.offer - st.advance, "advance": st.advance}
	if not "mines" in Game.known:
		Game.known.append("mines")
	var out: Array = [{"s": "brask", "t": "Done, then. The clerk will write it down: %s on your return, with news of the miners." % _coins(st.offer - st.advance)}]
	if st.advance > 0:
		Game.add_silver(Game.party[0], st.advance)
		out.append({"n": "Brask counts out %s onto the table, one coin at a time, as if each one hurts." % _coins(st.advance)})
	out.append({"s": "hale", "t": "The road to the workings leaves by the south gate and climbs north-east into the hills. A day's walk."})
	out.append({"n": "(The Mines are now on the world map.)"})
	out.append({"end": true})
	return out


## Visits after the job is taken. (Reporting back after the mines is not in the game yet.)
static func _after_job() -> Array:
	var job: Dictionary = Game.story.get("mines_job", {"pay": state().offer})
	var out: Array = [{"s": "brask", "t": "You have the council's word: %s when you return with news of the miners." % _coins(job.pay)}]
	if Game.visited.size() > 1:
		out.append({"s": "brannoc", "t": "Back so soon? Unless you've found them, the hills are that way."})
		out.append({"n": "(Reporting back to the council is not in the game yet.)"})
	else:
		out.append({"s": "brannoc", "t": "Well? The hills are that way. Out the south gate."})
	out.append({"end": true})
	return out


static func _coins(silver: int) -> String:
	return "%d silver" % silver
