class_name Journal
extends RefCounted
## What the quest log remembers (see QuestLog, the window, and "The quest log" in IDEAS.md):
## every conversation and scene of a quest, line by line as it was played, so that after a long
## pause you can read back exactly what was said. A DialogueBox with `journal` set to a quest's
## key writes its history here as it goes.
##
## Kept in Game.story.journal: {quest key: [{"place": where, "lines": [bbcode lines]}, ...]}.

const QUESTS := [
	{"key": "mines", "name": "The missing miners"},
	{"key": "lisbet", "name": "Lisbet's letter"},
	{"key": "boddo", "name": "Boddo's debt"},
	{"key": "skee", "name": "Skee's lights"},
]
const STATUS_NAMES := {"current": "Current", "offered": "Not taken yet", "done": "Done"}


static func _all() -> Dictionary:
	if not Game.story.has("journal"):
		Game.story["journal"] = {}
	return Game.story.journal


## A new scene in a quest's record. Returns its list of lines, for the box to add to.
static func begin(quest: String, place: String) -> Array:
	var j := _all()
	if not j.has(quest):
		j[quest] = []
	var lines: Array = []
	j[quest].append({"place": place, "lines": lines})
	return lines


static func scenes(quest: String) -> Array:
	return _all().get(quest, [])


## "current", "offered" (heard of, not taken), "done", or "" (not known yet).
static func status(key: String) -> String:
	if key == "mines":
		if LehanQuests.done("mines"):
			return "done"
		if CouncilData.accepted():
			return "current"
		if LehanData.has_job():
			return "offered"
	else:
		var s := LehanQuests.get_q(key)
		if s == "done":
			return "done"
		if s != "":
			return "current"
	return "offered" if not scenes(key).is_empty() else ""


## The quests to list: current ones first, then those not taken yet, then the finished ones.
static func listed() -> Array:
	var out: Array = []
	for st in ["current", "offered", "done"]:
		for q in QUESTS:
			if status(q.key) == st:
				out.append(q)
	return out


## Which quest a talk with someone in Lehan's streets belongs to ("" for none).
static func quest_of_person(key: String) -> String:
	match key:
		"lisbet", "skee", "boddo":
			return key
		"hal":
			return "mines"
		"crier":
			return "mines" if LehanData.has_job() or LehanQuests.any_done() else ""
		"guard":
			return "lisbet" if LehanQuests.get_q("lisbet") == "carrying" else ""
	return ""
