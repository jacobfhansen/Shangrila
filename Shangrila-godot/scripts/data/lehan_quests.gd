class_name LehanQuests
extends RefCounted
## The three Lehan quests (see "The Lehan quests" in IDEAS.md): one for each of Lisbet, Skee and
## Boddo. The first one finished, alone, makes the crier cry the mines job; the others stay open.
## Finishing a quest puts its character on the inn's list (with a fee or a talk to muster).
##
## State lives in Game.story.quests: {"lisbet": "carrying" / "delivered" / "done", ...} plus
## per-quest details ("lisbet_tail", "lisbet_seal", ...). Dialogue effects (fx) change it:
##   q:key=value   set a quest value          silver:N   the host gets N silver
##   xp:F          story experience           recruit:key  the character joins the inn's list
##   purse         the council's real budget is known
##   pay:N         the party pays N silver    hurt:N     everyone in the party loses up to N hits
##   place:key     a place in Lehan is found (on the town map)
##   fail:key      a check failed on that quest (sent by the dialogue box; see finish_xp_steps)
##   finish:key    the experience for finishing the quest, less for each failed check
## Quest items (Lisbet's letter, Tam's page, Skee's bag, the glowing shard) follow the quest
## values: after every effect, sync_items hands out or takes back whatever the quests say.

## The new characters: a little better than the starting companions, and harder to win.
const RECRUITS := {
	"lisbet": {"name": "Lisbet Farrow", "race": "Human", "cls": "Thief", "icon": 0,
		"abilities": {"thievery": 3, "stealth": 1, "perception": 1, "talk": 2},
		"traits": ["Deceitful", "Cheerful", "Curious"],
		"look": {"skin": "#f0c8a8", "hair": "#c09040", "cloth": "#7a3a5a", "legs": "#4a3040"}},
	"skee": {"name": "Skee", "race": "Nisk", "cls": "Ranger", "icon": 1,
		"abilities": {"missile": 2, "stealth": 2, "perception": 2, "survival": 1},
		"traits": ["Superstitious", "Curious", "Cautious"],
		"look": {"skin": "#9a8a70", "cloth": "#4a5a3a", "legs": "#3a3028"}},
	"boddo": {"name": "Boddo", "race": "Thuug", "cls": "Warrior", "icon": 2,
		"abilities": {"combat": 3, "toughness": 3, "talk": 0},
		"traits": ["Calm", "Vengeful", "Humble"],
		"look": {"skin": "#7a8a5a", "shell": "#6a5236", "cloth": "#8a7050"}},
	# Won by the mines job (MinesQuest), not a Lehan quest: he joins after the report to the council.
	"hal": {"name": "Hal Venner", "race": "Human", "cls": "Warrior", "icon": 3,
		"abilities": {"combat": 3, "toughness": 2, "survival": 1},
		"traits": ["Brave", "Melancholy", "Loyal"],
		"look": {"skin": "#d8a880", "hair": "#4a3020", "cloth": "#5a4a3a", "legs": "#3a3028"}},
	# Aubermont's old town (AubermontData): the scholar who offers himself (secretly the sect's man),
	# and the gravedigger from the north road.
	"aldric": {"name": "Aldric Thorne", "race": "Human", "cls": "Mage", "icon": 4,
		"abilities": {"magic": 3, "lore": 3, "talk": 2, "perception": 1},
		"traits": ["Deceitful", "Bookish", "Calm"],
		"look": {"skin": "#e0c4a8", "hair": "#3a3434", "cloth": "#1e1e24", "legs": "#16161a", "beard": true}},
	"odo": {"name": "Odo Brakk", "race": "Human", "cls": "Monk", "icon": 5,
		"abilities": {"combat": 3, "toughness": 3, "survival": 1},
		"traits": ["Humble", "Melancholy", "Pious"],
		"look": {"skin": "#c89a74", "hair": "#9a9890", "cloth": "#4a4440", "legs": "#3a3430", "beard": true}},
}
const QUESTS := ["lisbet", "skee", "boddo"]   # the Lehan quests (Hal is won by the mines job)
const ICON_BASE := 10   # portrait icons Game.PORTRAIT_CAST + ICON_BASE + n
const DONE_XP := 0.25   # story experience for finishing a quest
const CHECK_XP := 0.05  # ... and for each obstacle passed with an ability
const FAIL_CUT := 0.1   # each failed check on a quest takes this much off the finishing reward,
const XP_FLOOR := 0.5   # ... down to this much of it


static func state() -> Dictionary:
	if not Game.story.has("quests"):
		Game.story["quests"] = {}
	return Game.story.quests


static func get_q(key: String, default := "") -> String:
	return str(state().get(key, default))


static func done(key: String) -> bool:
	return get_q(key) == "done"


static func any_done() -> bool:
	for k in QUESTS:
		if done(k):
			return true
	return false


## The host alone, before the mines job is cried: the solo part.
static func solo() -> bool:
	return not LehanData.has_job()


static func host_key() -> String:
	return Game.story.get("host", "")


static func host_char() -> Dictionary:
	var host := host_key()
	if host != "":
		var nm: String = PrologueData.CAST[host].name
		for c in Game.party:
			if c.name == nm:
				return c
	return Game.party[0]


static func host_first() -> String:
	var host := host_key()
	return PrologueData.CAST[host].name.split(" ")[0] if host != "" else "friend"


static func host_has(t: String) -> bool:
	var host := host_key()
	return host != "" and t in PrologueData.CAST[host].traits


## The first of these traits the host has ("" if none).
static func host_trait(list: Array) -> String:
	for t in list:
		if host_has(t):
			return t
	return ""


## The best in the party at an ability (the host wins ties), and their cast key ("" if none).
static func best(ability: String) -> Dictionary:
	var b := host_char()
	for c in Game.party:
		if Game.ability(c, ability) > Game.ability(b, ability):
			b = c
	return b


## A check for an option, shown by the dialogue box: the ability as a tag on the option, and who
## rolls, their skill, the bonus (`why` says where it comes from) and the chance as its tooltip.
## Put a list of them in the option's "checks"; a check with "or": true is an alternative to the
## one before it (either will do), otherwise each must be passed in turn.
static func chk(who: Dictionary, ability: String, difficulty: int, bonus := 0, why := "") -> Dictionary:
	return {"who": who, "ability": ability, "diff": difficulty, "bonus": bonus, "why": why}


## The cast key of a party member: one of the company, or a recruit ("" for anyone else).
static func key_of(c: Dictionary) -> String:
	if c.has("recruit"):
		return c.recruit
	for k in PrologueData.ORDER:
		if PrologueData.CAST[k].name == c.name:
			return k
	for k in RECRUITS:
		if RECRUITS[k].name == c.name:
			return k
	return ""


## Once the mines job is cried, the company is expected in the hills: someone grumbles about
## running errands in town (the first companion in the party who isn't the host).
const ERRAND_LINES := {
	"joss": "Six miners missing and a council purse waiting, and we're running errands in town?",
	"maera": "The trail up to those mines gets colder every day we spend in town, you know.",
	"ommuk": "Kindness is never wasted. But the miners are waiting for kindness too.",
	"ithrae": "Interesting. But weren't we meant to be in the hills by now?",
	"tikkat": "Errands! Lovely! Anything that isn't a dark hole full of whatever ate six miners.",
	"lisbet": "Not that I mind, but the council won't keep that offer warm forever.",
	"skee": "Skee likes town. Town has no tunnels. Well. Not many.",
	"boddo": "Hm. The miners. Boddo has not forgotten the miners.",
}


static func errand_comment() -> Array:
	if solo() or Game.mines_entered():   # after a trip into the mines nobody minds
		return []
	var host := host_key()
	for c in Game.party:
		var k := key_of(c)
		if k != "" and k != host and ERRAND_LINES.has(k):
			return [{"s": k, "t": ERRAND_LINES[k]}]
	return []


## What follows any finished quest: the crier steps up, the first time.
static func quest_finished_steps() -> Array:
	if not LehanData.has_job():
		return [{"n": "Across the square, the crier climbs onto the well's edge with a fresh notice in his hand."}]
	return []


## Whether the spirit can still nudge a check on this quest (once, and only with a host).
static func can_nudge(quest: String) -> bool:
	return host_key() != "" and get_q(quest + "_nudge") == ""


## The host's inner voice when the spirit helps.
static func nudge_line() -> Dictionary:
	var h := host_first()
	var t := host_trait(["Cowardly", "Proud", "Pious", "Curious", "Hot-tempered", "Melancholy"])
	var line: String = {
		"Cowardly": "My hands stop shaking. Something is holding them still. That should frighten me more than it does.",
		"Proud": "I'd have managed without it. But I'll take it.",
		"Pious": "A blessing? Or something else, wearing a blessing's clothes.",
		"Curious": "So that's what it feels like, when it helps. Like a second pair of eyes behind mine.",
		"Hot-tempered": "Calm. Where did that come from? Not from me.",
		"Melancholy": "For a moment I am not alone in here. Strange, how much that helps.",
	}.get(t, "For a moment %s's senses are sharper than their own. Something is helping." % h)
	return {"i": line}


# ---------------------------------------------------------------- effects

static func apply(fx: String) -> void:
	var st := state()
	if fx.begins_with("q:"):
		var kv := fx.substr(2).split("=")
		st[kv[0]] = kv[1]
	elif fx.begins_with("silver:"):
		Game.add_silver(host_char(), int(fx.substr(7)))
	elif fx.begins_with("xp:"):
		Game.story_xp(float(fx.substr(3)))
	elif fx.begins_with("recruit:"):
		_recruit(fx.substr(8))
	elif fx == "purse":
		Game.story["council_purse"] = true
	elif fx.begins_with("pay:"):
		Game.pay(int(fx.substr(4)))
	elif fx.begins_with("hurt:"):
		for c in Game.party:
			c.hits = maxi(1, c.hits - Game.my_random(1, int(fx.substr(5))))
	elif fx.begins_with("place:"):
		Game.discover_place("lehan", fx.substr(6))
	elif fx.begins_with("fail:"):
		var k := fx.substr(5) + "_fails"
		st[k] = str(int(st.get(k, "0")) + 1)
	elif fx.begins_with("finish:"):
		Game.story_xp(DONE_XP * xp_share(fx.substr(7)))
	sync_items()


## Failed checks on a quest so far.
static func fails(key: String) -> int:
	return int(get_q(key + "_fails", "0"))


## How much of the finishing reward a quest pays: all of it, less a tenth for each failed check,
## but never less than half.
static func xp_share(key: String) -> float:
	return maxf(XP_FLOOR, 1.0 - FAIL_CUT * fails(key))


## The end of a quest: its experience, and a line saying how much of it the failures left. The
## line is worked out when it is shown, since a check can still fail in the same scene.
static func finish_xp_steps(key: String) -> Array:
	return [{"fx": "finish:" + key, "wait": 0.1}, {"dyn": func(): return {"n": xp_line(key)}}]


static func xp_line(key: String) -> String:
	var n := fails(key)
	var pct := roundi(xp_share(key) * 100)
	if n == 0:
		return "(Story experience: %d%%, without a single failed try.)" % pct
	const WORDS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
	var count: String = WORDS[n] if n < WORDS.size() else str(n)
	return "(Story experience: %d%%, after %s failed %s.)" % [pct, count, "try" if n == 1 else "tries"]


## The quest items, and when the party carries each one (from the quest values).
const QUEST_ITEMS := {
	34: "Lisbet's letter: from taking the job until it is handed to Rudd",
	35: "Tam's page: taken from the wage book, until Gell pays or burns it",
	36: "Skee's bag: found in the tunnels, until it is given back",
	37: "the glowing shard: from the chamber of the lights, until Skee has it",
	41: "the foreman's key: from the breach in the mines, until the stores are open",
	42: "the lift crank: from the foreman's stores, until it is fitted to the lift",
	48: "the Holm seal: from the jailers' armoury, kept",
	49: "the jailer's record: from the jailers' armoury, kept",
}


static func _should_carry(id: int) -> bool:
	match id:
		34: return get_q("lisbet") == "carrying"
		35: return get_q("boddo") == "found" and get_q("boddo_page") != ""
		36: return get_q("skee_bag") != "" and get_q("skee_ask_bag") == "" and not done("skee")
		37: return get_q("skee") == "seen" and get_q("skee_ask_stone") == ""
	return MinesQuest.should_carry(id)


## Hands out the quest items the quests call for, and takes back those they no longer need.
static func sync_items() -> void:
	if Game.party.is_empty() and Game.roster.is_empty():
		return
	for id in QUEST_ITEMS:
		var has := not Game.holder_of(id).is_empty()
		var want := _should_carry(id)
		if want and not has and not Game.party.is_empty():
			Game.give_item(id, host_char())
		elif has and not want:
			Game.take_item(id)


## The character joins the inn's list, waiting to be mustered.
static func _recruit(key: String) -> void:
	var r: Dictionary = RECRUITS[key]
	for c in Game.roster + Game.party:
		if c.name == r.name:
			return
	var c := Game.make_character(r.name, Game.CLASSES.find(r.cls), Game.RACES.find(r.race),
		Game.PORTRAIT_CAST + ICON_BASE + r.icon, r.abilities)
	c["traits"] = r.traits.duplicate()
	c["recruit"] = key
	c["rejoin"] = "recruit"
	c["fee"] = int(get_q(key + "_fee", "0"))
	Game.roster.append(c)


## A recruit's portrait look by icon (or {} if the icon is not a recruit's).
static func look_for_icon(icon: int) -> Dictionary:
	for k in RECRUITS:
		if Game.PORTRAIT_CAST + ICON_BASE + RECRUITS[k].icon == icon:
			return RECRUITS[k]
	return {}


## The recruits as DialogueBox cast.
static func cast() -> Dictionary:
	var c := {}
	for k in RECRUITS:
		c[k] = {"name": RECRUITS[k].name, "race": RECRUITS[k].race, "look": RECRUITS[k].look}
	return c


## Whether a person in the square has left it (to the inn's list).
static func gone_from_square(key: String) -> bool:
	if key == "hal":   # in the square once the mines job is taken, until he joins
		return not CouncilData.accepted() or done(key)
	return RECRUITS.has(key) and done(key)


## Mustering a recruit at the inn: a short talk, and the fee if they want one.
## Effects as LehanData.rejoin_talk: "pay:N", "join", "notyet".
static func muster_talk(c: Dictionary, purse: int) -> Array:
	var k: String = c.recruit
	var fee: int = c.get("fee", 0)
	var host := host_key()
	match k:
		"lisbet":
			var opener := "%d silver, and my picks are yours. Fair price, for someone who carried a letter so nicely." % fee \
				if fee <= LisbetQuest.FEE_GOOD else "%d silver. You know why it's not %d." % [fee, LisbetQuest.FEE_GOOD]
			var pay_after: Array = [{"n": "%s counts the coins. Not enough." % host_first()}, {"fx": "notyet", "wait": 0.1}] if purse < fee \
				else [{"fx": "pay:%d" % fee, "wait": 0.1}, {"s": k, "t": "Lovely. Where are we going, and what does it pay?"}, {"fx": "join", "wait": 0.1}]
			return [
				{"s": k, "t": opener},
				{"choice": "muster", "options": [
					{"t": "Here. (%d silver)" % fee, "say": host, "after": pay_after},
					{"t": "Not now.", "say": host, "after": [{"s": k, "t": "I'll be here. I usually am."}, {"fx": "notyet", "wait": 0.1}]},
				]},
			]
		"skee":
			return [{"s": k, "t": "Skee is ready. Skee has packed. Twice."}, {"fx": "join", "wait": 0.1}]
		"hal":
			return [{"s": k, "t": "For my father. Lead on."}, {"fx": "join", "wait": 0.1}]
		"boddo":
			var line := "Boddo carries. Where are we going?" if get_q("boddo_way") != "self" \
				else "You paid Boddo's debt. Boddo goes where you go."
			return [{"s": k, "t": line}, {"fx": "join", "wait": 0.1}]
	return [{"fx": "join", "wait": 0.1}]
