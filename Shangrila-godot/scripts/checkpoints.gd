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
	["tunnels", "Under Lehan", "Skee's quest taken and the way down found: at the foot of the ladder in the old tunnels."],
	["council", "The council house", "The crier has cried the mines job; the company is still at the inn. At the council's door."],
	["mines", "The Mines, level 1", "The mines job is taken and the whole company is back together, at the entrance."],
	["mines2", "The Mines, level 2", "Level 1 done (its chests, fights and cart): everyone a step stronger, at the foot of the ladder."],
	["mines3", "The Mines, level 3", "Levels 1 and 2 done (the miners out, the lift repaired): everyone two steps stronger, in steel."],
	["marsh", "Oggal, the marsh village", "The mines' levels played and the jailers' record found: arriving at the Thuug village on the causeway."],
	["north", "The north road", "The marsh remnant merged (Insight): at Lehan, with Aubermont on the map and food for the road."],
	["aubermont", "Aubermont, the river gate", "The north road travelled: inside the city's river gate, on the first visit."],
	["temple", "The drowned temple", "Oggal's people met and the shrine grounds done (the pens cleared, the door opened with the chant): at the foot of the steps."],
]

## What each mines level's start counts as already done, on top of the levels before it.
const MINES_DONE := {
	2: ["m_reached_1=1", "m_cart=1", "m_points=1", "m_secret=1", "m_chest_1a=1", "m_chest_1b=1",
		"m_chest_1d=1", "m_grp_1k=1", "m_grp_1r=1", "m_note_1n=1", "m_trap_1p=1"],
	3: ["m_reached_2=1", "m_air=1", "m_breach=1", "m_key=1", "m_stores=1", "m_crank=1", "m_lift=1",
		"m_chest_2g=1", "m_gate=shut", "m_water=drained", "m_survivors=out", "m_grp_2Y=1",
		"m_grp_2D=1", "m_grp_2W=1", "m_note_2n=1", "m_vein_4_5=1"],
}


## The marsh starts: the mines played and the jailers' record found, at the Thuug marshes.
static func _marsh(host: String) -> void:
	start("mines3", host)
	Game.story["marsh_road_done"] = true
	LehanQuests.apply("q:m_record=1")
	LehanQuests.apply("q:m_seal=1")
	LehanQuests.sync_items()
	if not "marsh_shrine" in Game.known:
		Game.known.append("marsh_shrine")
	for k in 4:
		Game.party_add(51)
	Game.location = "marsh_shrine"


## After the marsh: the remnant merged (Insight), at Lehan with Aubermont on the map and bread.
static func _north(host: String) -> void:
	_marsh(host)
	Game.story["marsh_arrived"] = true
	for k in ["marsh_orrun=trust", "marsh_ubba=told", "marsh_leeches=done", "marsh_chant=1", "s_reached_1=1",
			"s_reached_2=1", "s_door=open", "s_path=known", "s_step=4", "s_remnant=merged", "marsh=done"]:
		LehanQuests.apply("q:" + k)
	Game.story["remnants"] = 2
	Game.story["insight"] = true
	if not "aubermont" in Game.known:
		Game.known.append("aubermont")
	for c in Game.party:
		Game.gain_xp(c, Game.raise_unit(c) * 2)
	for k in 12:
		Game.party_add(50)
	Game.to_mines()
	Game.location = "lehan"


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
		"tunnels":
			for f in ["skee=going", "skee_way=1"]:
				LehanQuests.apply("q:" + f)
			Game.discover_place("lehan", "tannery")
			Game.main.goto("tunnels")
		"council":
			Game.story["job_notice"] = true
			Game.discover_place("lehan", "council")
			Game.discover_place("lehan", "smith")
			Game.main.goto("streets", {"at": "council", "into": true})
		"marsh":
			_marsh(host)
			Game.main.goto("village")
		"north":
			_north(host)
			Game.main.goto("world")
		"aubermont":
			_north(host)
			Game.story["north_road_done"] = true
			Game.story["aubermont_seen"] = true
			Game.day += 4
			Game.location = "aubermont"
			Game.main.goto("city")
		"temple":
			_marsh(host)
			Game.story["marsh_arrived"] = true
			for k in ["marsh_orrun=trust", "marsh_ubba=told", "marsh_leeches=done", "marsh_chant=1", "s_reached_1=1",
					"s_door=open", "s_order=known", "s_sigil_1=1", "s_sigil_2=1", "s_sigil_3=1", "s_grp_1N=1", "s_grp_1T=1",
					"s_chest_1c=1"]:
				LehanQuests.apply("q:" + k)
			for c in Game.party:
				Game.gain_xp(c, Game.raise_unit(c))
			Game.site = "shrine"
			Game.mine_level = 2
			var at: Array = ShrineArea.arrive_near(2, "<")
			Game.pos = at[0]
			Game.facing = at[1]
			Game.main.goto("dungeon", {"arrived": "down"})
		"mines", "mines2", "mines3":
			Game.story["job_notice"] = true
			Game.discover_place("lehan", "council")
			var cs := CouncilData.state()
			cs.accepted = true
			cs.met = true
			Game.story["mines_job"] = {"pay": cs.offer, "advance": 0}
			Game.known.append("mines")
			Game.discover_place("lehan", "smith")
			for c in Game.roster.duplicate():
				for k in ["rejoin", "grudge", "owed"]:
					c.erase(k)
				Game.roster.erase(c)
				Game.party.append(c)
			Game.location = "mines"
			var lv: int = {"mines": 1, "mines2": 2, "mines3": 3}[key]
			_mines_done(lv)
			Game.mine_level = lv
			if lv == 1:
				Game.pos = MinesArea.START
				Game.facing = MinesArea.START_FACING
			else:
				var at: Array = MinesArea.arrive_near(lv, "<")
				Game.pos = at[0]
				Game.facing = at[1]
			Game.main.goto("dungeon")
		_:
			Game.main.goto("town")


## The mines levels before `lv` played: their quest values, their gear and silver, and the company
## grown with them, each step a raise in everyone's best fighting ability and in Toughness (what
## the fights and the puzzles on a level are worth), plus a little experience left to spend.
static func _mines_done(lv: int) -> void:
	if lv < 2:
		return
	Game.story["mines_entered"] = true
	for l in range(2, lv + 1):
		for f in MINES_DONE[l]:
			LehanQuests.apply("q:" + f)
	# Level 1's chests: the lamp, the pick, a leather cap, a root, and 16 silver.
	for id in [40, 38, 29]:
		Game.give_item(id)
	_wear(39, Game.SLOT_HEAD)
	var silver := 16
	if lv >= 3:
		# The foreman's stores: a steel sword and cap for whoever fights best with a blade.
		_wear(44, Game.SLOT_RHAND)
		_wear(45, Game.SLOT_HEAD)
		silver += 8
	Game.add_silver(Game.party[0], silver)
	for c in Game.party:
		for step in lv - 1:
			for k in [Game.best_fighting(c), "toughness"]:
				Game.gain_xp(c, maxi(0, Game.raise_cost(c, k)))
				Game.raise_ability(c, k)
		Game.gain_xp(c, Game.raise_unit(c) / 2)
		c.hits = c.max_hits
		c.magic = c.max_magic


## Puts an item on the party member it suits best: a weapon in the hand of the best blade, a cap
## on the first head that is bare or wears something weaker. What it replaces goes in their pack.
static func _wear(id: int, slot: int) -> void:
	var it := Game.item(id)
	var best: Dictionary = {}
	for c in Game.party:
		if slot == Game.SLOT_RHAND:
			if Game.best_fighting(c) != "combat":
				continue
			if best.is_empty() or Game.ability(c, "combat") > Game.ability(best, "combat"):
				best = c
		else:
			var now: int = c.items[slot]
			if now == 0 or Game.item(now).defense < it.defense:
				if best.is_empty() or best.items[slot] != 0 and now == 0:
					best = c
	if best.is_empty():
		Game.give_item(id)
		return
	var old: int = best.items[slot]
	Game.set_slot(best, slot, id)
	if old != 0:
		Game.pack_add(best, old)
