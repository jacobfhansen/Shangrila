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
##   purse         the council's real budget is known      nudge   the spirit's one nudge is spent

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
}
const ICON_BASE := 10   # portrait icons Game.PORTRAIT_CAST + ICON_BASE + n
const DONE_XP := 0.25   # story experience for finishing a quest
const CHECK_XP := 0.05  # ... and for each obstacle passed with an ability


static func state() -> Dictionary:
	if not Game.story.has("quests"):
		Game.story["quests"] = {}
	return Game.story.quests


static func get_q(key: String, default := "") -> String:
	return str(state().get(key, default))


static func done(key: String) -> bool:
	return get_q(key) == "done"


static func any_done() -> bool:
	for k in RECRUITS:
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
	return [{"fx": "join", "wait": 0.1}]
