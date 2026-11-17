class_name Checkpoints
extends RefCounted
## Start the story at a later point, for testing by hand. From the title screen ("Start at...")
## or the command line:  godot-4 --path . -- --start=market --host=tikkat
## Each checkpoint sets up the story as if the scenes before it had been played with simple
## choices (the first reply at the shrine, consent given, a silent answer to the employer).

const LIST := [
	["road", "The road to Lehan", "Just after the prologue: the walk, the ambush and the spirit's request."],
	["lehan", "Arriving in Lehan", "At the gate: the walk to the employer, the meeting and the split."],
	["split", "The inn after the split", "The company has split up; nobody will come without a job."],
	["market", "The market square", "After the split, before the crier: the walkable square."],
	["mines", "The Mines", "The mines job is known and the whole company is back together."],
]


static func keys() -> Array:
	return LIST.map(func(e): return e[0])


static func start(key: String, host: String) -> void:
	if not host in PrologueData.ORDER:
		host = "tikkat"
	Game.start_company(host, 0)
	if key == "road":
		Game.main.goto("world", {"road": true})
		return
	Game.story["road_done"] = true
	Game.story["host_control"] = true
	Game.story["consent"] = "given"
	Game.location = "lehan"
	if key == "lehan":
		Game.main.goto("streets")
		return
	# The meeting, played quietly: a silent answer, the default split.
	Game.discover_place("lehan", "hideout")
	LehanData.record("answer=silent")
	LehanData.settle(host)
	Game.story["employer"] = "met"
	var host_name: String = PrologueData.CAST[host].name
	for c in Game.party.duplicate():
		if c.name != host_name:
			Game.party.erase(c)
			Game.roster.append(c)
	match key:
		"split":
			Game.main.goto("inn", {"split": true})
		"market":
			Game.main.goto("streets", {"at": "market", "into": true})
		"mines":
			Game.known.append("mines")
			Game.discover_place("lehan", "smith")
			for c in Game.roster.duplicate():
				for k in ["rejoin", "grudge", "owed"]:
					c.erase(k)
				Game.roster.erase(c)
				Game.party.append(c)
			Game.location = "mines"
			Game.pos = Game.MINES_START
			Game.facing = 0
			Game.main.goto("dungeon")
		_:
			Game.main.goto("town")
