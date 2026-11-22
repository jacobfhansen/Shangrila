class_name MinesQuest
extends RefCounted
## The council's mines job (J2): what happens on the three levels of the mines (MinesArea), Hal
## Venner in Lehan, and reporting back to the council. See "The mines: levels, grinding and story"
## in IDEAS.md.
##
## The story: six miners broke through Master Hale's grandfather's wall into the jailers' sealed
## galleries. The foreman (Hal's father) and Tobin died at the breach; three are cut off on the
## second level; Saelen, an Aeldroe, followed a calling down to the tomb gate. The jailers' dead
## woke. The Warden at the gate cannot be beaten yet.
##
## Quest values (LehanQuests, all starting "m_"): m_reached_N, m_cart, m_points, m_secret, m_air,
## m_key, m_stores, m_crank, m_lift, m_gate (upper sluice "shut"), m_water ("drained"), m_breach,
## m_survivors ("out"), m_saelen ("home"), m_wards (pillars pressed so far), m_ward ("open"),
## m_seal, m_record, m_warden ("met"), m_grp_<key>, m_chest_<key>, m_trap_<key>, m_note_<key>,
## m_vein_<x>_<y>, m_hal (talked), m_seal_told; mines = "done" once reported.
##
## Effects (besides LehanQuests.apply's): item:ID (a normal item into someone's pack),
## known:place (on the world map), hurtone:N (one character loses up to N hits), lever:ch,
## ward:digit. The dungeon screen itself handles travel:level:how and fight:warden.

const WARD_ORDER := "132"   # chain, seal, eye: "First we bound him, then we sealed him, now we watch."
const ORE_ID := 43

## What is in each chest: items, silver (shared out), and how it is found.
const CHESTS := {
	"1a": {"items": [40], "silver": 0, "text": "A miners' box by the cold fire: a spare lamp, wrapped in sacking against the damp."},
	"1b": {"items": [38], "silver": 6, "text": "Under the kobolds' bedding of rags and bones: a good miner's pick, and a few coins they stole."},
	"1d": {"items": [39, 29], "silver": 10, "text": "Someone's private stash behind the boards: a leather cap, a root against wounds, and a purse."},
	"2g": {"items": [44, 45], "silver": 8, "text": "The foreman's stores: the lift's crank on its hook, a steel sword, a steel cap, and the wage money."},
	"3h": {"items": [46, 47], "silver": 0, "text": "The jailers' armoury: on a rack, still sharp after all this time, an old blade and a shield etched with warding lines. They are cold to the touch."},
	"3j": {"items": [], "silver": 12, "text": "A stone coffer under the racks. Inside, on rotten velvet: a signet ring, a brittle page in an old hand, and old coins."},
}

## The placed monsters: they stay dead once beaten.
const GROUPS := {
	"1k": {"m": [{"key": "kobold", "n": 4}], "intro": "Kobolds! This side gallery is their den, and they don't like visitors."},
	"1r": {"m": [{"key": "rat", "n": 5}], "intro": "The floor moves: a nest of giant rats in the old spoil."},
	"2Y": {"m": [{"key": "lurker", "n": 1}], "intro": "Something long and thin unfolds from the side passage, where it was waiting."},
	"2D": {"m": [{"key": "delver", "n": 2}], "intro": "The wall bursts open in a shower of stones. Delvers, blind and clawed, dug straight at the sound of you."},
	"2W": {"m": [{"key": "gloom_mother", "n": 1}, {"key": "gloomweaver", "n": 3}],
		"intro": "Pale webs fill the gallery. In the middle, big as a pony, the Gloomweaver Mother turns towards your torch."},
	"3O": {"m": [{"key": "oathbound", "n": 3}], "intro": "Three of the jailers' dead step out of their niches, rusted mail rattling. They still keep their oath."},
	"3Q": {"m": [{"key": "oath_archer", "n": 2}, {"key": "oathbound", "n": 1}], "intro": "Bowstrings creak in the dark. Oath-Archers, and one with an axe to keep you busy."},
	"3K": {"m": [{"key": "sworn_knight", "n": 1}, {"key": "oathbound", "n": 2}],
		"intro": "Before the way to the gate stands a Sworn Knight in heavy plate, with two of the oath-bound at its side."},
}

## Speakers in the mines: Hal, the survivors' spokesman and Saelen.
const CAST := {
	"hal": {"name": "Hal Venner", "race": "Human",
		"look": {"skin": "#d8a880", "hair": "#4a3020", "cloth": "#5a4a3a", "legs": "#3a3028"}},
	"dunn": {"name": "Old Dunn", "race": "Human",
		"look": {"skin": "#c89878", "hair": "#a8a098", "cloth": "#4a4038", "legs": "#2a2620", "beard": true}},
	"saelen": {"name": "Saelen", "race": "Aeldroe",
		"look": {"skin": "#dde8f0", "hair": "#c8d8e8", "cloth": "#4a5a6a", "legs": "#2a3440"}},
}


static func cast() -> Dictionary:
	var c := MarketData.cast()
	c.merge(CAST, true)
	c.merge(LehanQuests.cast(), true)
	return c


static func _q(k: String) -> String:
	return LehanQuests.get_q(k)


static func _fx(f: String) -> Dictionary:
	return {"fx": f, "wait": 0.1}


static func _host() -> String:
	return LehanQuests.host_key()


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


## The figure standing at an npc square: the survivors (Old Dunn speaks for them) or Saelen.
static func figure(ch: String) -> Dictionary:
	var who: Dictionary = CAST.dunn if ch == "S" else CAST.saelen
	return {"race": who.race, "look": who.look, "height": 1.7 if ch == "S" else 1.8}


static func lever_down(ch: String) -> bool:
	match ch:
		"l": return _q("m_points") != ""
		"u": return _q("m_gate") == "shut"
		"v": return _q("m_water") == "drained"
	return false


static func has_item(id: int) -> bool:
	return not Game.holder_of(id).is_empty()


static func free_slots() -> int:
	var n := 0
	for c in Game.party:
		for s in range(Game.PACK_FIRST, Game.PACK_LAST + 1):
			if c.items[s] == 0:
				n += 1
	return n


# ---------------------------------------------------------------- effects

static func apply(fx: String) -> void:
	if fx.begins_with("item:"):
		var id := int(fx.substr(5))
		for c in Game.party:
			if Game.pack_add(c, id):
				break
	elif fx.begins_with("known:"):
		var place := fx.substr(6)
		if not place in Game.known:
			Game.known.append(place)
	elif fx.begins_with("hurtone:"):
		var up := Game.party.filter(func(c): return c.hits > 1)
		if not up.is_empty():
			var c: Dictionary = up.pick_random()
			c.hits = maxi(1, c.hits - Game.my_random(1, int(fx.substr(8))))
	elif fx.begins_with("lever:"):
		match fx.substr(6):
			"l": LehanQuests.apply("q:m_points=1")
			"u": LehanQuests.apply("q:m_gate=%s" % ("" if _q("m_gate") == "shut" else "shut"))
	elif fx.begins_with("ward:"):
		var seq := _q("m_wards") + fx.substr(5)
		if WARD_ORDER.begins_with(seq):
			LehanQuests.apply("q:m_wards=" + seq)
			if seq == WARD_ORDER:
				LehanQuests.apply("q:m_ward=open")
		else:
			LehanQuests.apply("q:m_wards=")
	else:
		LehanQuests.apply(fx)


## The mines' quest items, and when the party carries them (see LehanQuests.QUEST_ITEMS).
static func should_carry(id: int) -> bool:
	match id:
		41: return _q("m_key") != "" and _q("m_stores") == ""
		42: return _q("m_crank") != "" and _q("m_lift") == ""
		48: return _q("m_seal") != ""
		49: return _q("m_record") != ""
	return false


# ---------------------------------------------------------------- arriving

## The first time on each level (and the first time into the mines at all).
static func arrival(lv: int) -> Array:
	var out: Array = []
	match lv:
		1:
			out = [
				{"n": "The old workings: low galleries cut long ago, propped with black timbers. Rails run into the dark. The air smells of wet stone and old smoke."},
				{"n": "Fresh boot prints in the dust lead inwards. Six men, walking together. None coming back."},
			]
			if _host() != "":
				out.append({"sp": "Deeper. Whatever pulls at me is much deeper than this."})
		2:
			out = [
				{"n": "The ladder ends in the new diggings: paler rock, fresh pick marks, new timber still smelling of resin. The miners dug fast down here."},
				{"n": "Somewhere water is running. And something big has spun its webs across the far galleries."},
			]
		3:
			out = [
				{"n": "Beyond the breach the rock changes. These are not mine galleries: the walls are fitted stone, the blocks so close a knife wouldn't go between them. It is very cold."},
				{"n": "Niches line the walls, and not all of them are empty."},
			]
			if _host() != "":
				out.append({"sp": "Here. They brought me here. I remember the cold, and the sound of the stones going in, one by one."})
				out.append({"i": "The host's breath smokes in the torchlight. Their hands won't stop shaking, and it isn't only the cold."})
	return out


# ---------------------------------------------------------------- using things

## The scene for using a thing (from the square in front of it), or for stepping onto one.
static func scene(lv: int, t: Dictionary) -> Array:
	var k: String = t.kind
	var key: String = t.key
	match k:
		"chest": return _chest(key, t.done)
		"lever": return _lever(t.ch)
		"cart": return _cart()
		"air": return _air()
		"door": return _door()
		"water": return _water()
		"ward": return [{"n": "A slab of fitted stone fills the passage, carved edge to edge with warding script. There is no handle, no keyhole, no hinge. Somewhere nearby, something must open it."}]
		"npc": return _survivors() if t.ch == "S" else _saelen()
		"warden": return _warden()
		"vein": return _vein(t.cell)
		"pillar": return _pillar(t.ch)
		"words": return _words()
		"note": return _note(key)
		"trap": return _trap(key)
		"breach": return _breach()
		"lift": return lift(lv)
	return []


static func _chest(key: String, done: bool) -> Array:
	if done:
		return [{"n": "Empty now."}]
	var ch: Dictionary = CHESTS[key]
	var items: Array = ch.items
	if key == "3j":
		items = []   # the seal and the record are quest items, handed out by the quest values
	if free_slots() < items.size():
		return [{"n": ch.text}, {"n": "(There is no room in anyone's pack. Make room first, then come back.)"}]
	var out: Array = [{"n": ch.text}]
	for id in items:
		out.append(_fx("item:%d" % id))
	if ch.silver > 0:
		out.append(_fx("silver:%d" % ch.silver))
	var names: Array = items.map(func(id): return Game.item(id).name)
	if key == "3j":
		names = ["the Holm Seal", "the Jailer's Record"]
		out.append(_fx("q:m_seal=1"))
		out.append(_fx("q:m_record=1"))
		out.append(_fx("known:marsh_shrine"))
	if key == "2g":
		out.append(_fx("q:m_crank=1"))
		names.push_front("the Lift Crank")
	if ch.silver > 0:
		names.append("%d silver" % ch.silver)
	out.append(_fx("q:m_chest_" + key + "=1"))
	out.append({"n": "(You take %s.)" % _and(names)})
	if key == "3j":
		out.append({"n": "The page is a jailer's record. Most of it has crumbled, but one passage can still be read. (Read it from the pack: the Jailer's Record.)"})
		if _host() != "":
			out.append({"sp": "The marshes. Another piece of me, drowned in black water. I can almost feel it from here."})
		out.append({"n": "(The Drowned Shrine in the Thuug marshes is now on the world map.)"})
	if key == "3h" and _host() != "":
		out.append({"i": "The host would rather not touch them. The cold of that steel goes deeper than the fingers."})
	return out


static func _and(list: Array) -> String:
	if list.size() <= 1:
		return "".join(list)
	return ", ".join(list.slice(0, -1)) + " and " + list[-1]


static func _lever(ch: String) -> Array:
	match ch:
		"l":
			if _q("m_points") != "":
				return [{"n": "The points lever is over. Somewhere off towards the shaft, the rails are set for the side track."}]
			return [{"n": "An iron lever by the rails, rusted in its slot: the points for the cart track."},
				{"choice": "points", "options": [
					{"t": "Throw the lever over.", "silent": true, "after": [_fx("lever:l"),
						{"n": "It fights you, then goes over with a clank that echoes down the galleries. Somewhere, a rail point shifts."}]},
					{"t": "Leave it.", "silent": true, "after": []},
				]}]
		"u":
			var shut := _q("m_gate") == "shut"
			return [{"n": "A big wheel on the wall, chained to a sluice gate somewhere above: the upper gate, letting water in from the old workings." if not shut
					else "The upper sluice gate's wheel, turned shut. No more water is coming in from above."},
				{"choice": "gate", "options": [
					{"t": "Turn the wheel: %s the upper gate." % ("open" if shut else "close"), "silent": true, "after": [_fx("lever:u"),
						{"n": "The chain grinds. Far above, something heavy %s." % ("lifts, and water begins to run again" if shut else "drops into place, and the sound of running water fades")}]},
					{"t": "Leave it.", "silent": true, "after": []},
				]}]
		"v":
			if _q("m_water") == "drained":
				return [{"n": "The drain lever, pulled down. The flooded passage is empty now, apart from the mud."}]
			var after: Array
			if _q("m_gate") == "shut":
				after = [_fx("q:m_water=drained"),
					{"n": "With a gurgle like a giant drinking, the flooded passage drains away. With the upper gate shut, nothing comes in to fill it again."},
					{"n": "(The flooded passage is open.)"}]
			else:
				after = [{"n": "The water drains away with a long gurgle... and then comes roaring back through the upper gate, until the passage is full again."},
					{"i": "Something has to be shut first."}]
			return [{"n": "A long iron lever by the flooded passage: the drain."},
				{"choice": "drain", "options": [
					{"t": "Pull the drain lever.", "silent": true, "after": after},
					{"t": "Leave it.", "silent": true, "after": []},
				]}]
	return []


static func _cart() -> Array:
	if _q("m_points") != "":
		return [{"n": "With the points thrown over, the cart only needs a push. It trundles off down the side track and bangs into the buffers. The way to the shaft is clear."},
			_fx("q:m_cart=1")]
	var strong := LehanQuests.best("toughness")
	var deft := LehanQuests.best("thievery")
	var ok_push := Game.check(strong, "toughness", Game.HARD)
	var ok_brake := Game.ability(deft, "thievery") > 0 and Game.check(deft, "thievery", Game.NORMAL)
	return [
		{"n": "An ore cart, loaded with rock, stands jammed across the rails where they turn towards the shaft. Its wheels are locked against a rail point. It won't move."},
		{"choice": "cart", "options": [
			{"t": "Put your shoulders to it and push.", "silent": true, "ok": ok_push, "checks": [LehanQuests.chk(strong, "toughness", Game.HARD)],
				"after": [{"n": "%s heaves, the wheels jump the point, and the cart lurches aside." % _first(strong)}, _fx("q:m_cart=1"),
					_fx("xp:%s" % LehanQuests.CHECK_XP)] if ok_push
					else [{"n": "%s strains until their eyes water. The cart doesn't move an inch." % _first(strong)}]},
			{"t": "Work the brake and the jammed wheel free.", "silent": true, "ok": ok_brake,
				"checks": [LehanQuests.chk(deft, "thievery", Game.NORMAL).merged({"needs_skill": true})],
				"after": [{"n": "%s finds the catch under the rust and teases the wheel off the point. The cart rolls aside." % _first(deft)},
					_fx("q:m_cart=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok_brake
					else [{"n": "The brake is rusted solid. Nothing gives."}]},
			{"t": "Leave it for now.", "silent": true, "tip": "The rails must be switched somewhere...", "after": []},
		]},
	]


static func _air() -> Array:
	if has_item(40):
		return [{"n": "The lamp's flame shrinks, then turns blue: bad air ahead, heavy and still. But the flame shows where it thins, close to the floor along the left wall."},
			{"n": "Bent low, you follow the line of good air, and at the far end you find an old air-door, jammed shut. Propped open, it lets fresh air flow through."},
			_fx("q:m_air=1"), {"n": "(The passage is clear.)"}]
	var tracker := LehanQuests.best("survival")
	var strong := LehanQuests.best("toughness")
	var ok_s := Game.check(tracker, "survival", Game.NORMAL)
	var ok_t := Game.check(strong, "toughness", Game.NORMAL)
	return [
		{"n": "The passage ahead smells wrong: sweetish, stale. The torch burns low and blue. Two steps in, heads begin to swim. Bad air."},
		{"choice": "air", "options": [
			{"t": "Feel for a draught, and follow the good air.", "silent": true, "ok": ok_s, "checks": [LehanQuests.chk(tracker, "survival", Game.NORMAL)],
				"after": [{"n": "%s wets a finger, finds the faint draught along the floor, and leads you through to an old air-door. Propped open, it clears the passage." % _first(tracker)},
					_fx("q:m_air=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok_s
					else [{"n": "There is no draught to find. You back out, coughing."}, _fx("hurt:2")]},
			{"t": "Hold your breath and run for it.", "silent": true, "ok": ok_t, "checks": [LehanQuests.chk(strong, "toughness", Game.NORMAL)],
				"tip": "Everyone loses a few hits either way.",
				"after": [{"n": "Lungs bursting, you stumble through to the far end, where %s kicks open an old air-door. Fresh air pours in." % _first(strong)},
					_fx("hurt:3"), _fx("q:m_air=1")] if ok_t
					else [{"n": "Halfway in, someone falls to their knees. You drag each other back out, gasping."}, _fx("hurt:4")]},
			{"t": "Turn back.", "silent": true, "tip": "A miner's lamp would show where the air is good.", "after": []},
		]},
	]


static func _door() -> Array:
	if has_item(41):
		return [{"n": "A stout plank door with iron straps: the foreman's stores. The foreman's key turns in the lock."},
			_fx("q:m_stores=1"), {"n": "(The door is open.)"}]
	var deft := LehanQuests.best("thievery")
	var strong := LehanQuests.best("toughness")
	var ok_pick := Game.ability(deft, "thievery") > 0 and Game.check(deft, "thievery", Game.HARD)
	var ok_force := Game.check(strong, "toughness", Game.HARD)
	return [
		{"n": "A stout plank door with iron straps, locked. A board nailed beside it says STORES, and under it, smaller: KEY WITH VENNER."},
		{"choice": "door", "options": [
			{"t": "Pick the lock.", "silent": true, "ok": ok_pick, "checks": [LehanQuests.chk(deft, "thievery", Game.HARD).merged({"needs_skill": true})],
				"after": [{"n": "A good lock, but %s is better. It clicks open." % _first(deft)}, _fx("q:m_stores=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok_pick
					else [{"n": "The lock is too good. A pick snaps in it."}]},
			{"t": "Break it down.", "silent": true, "ok": ok_force, "checks": [LehanQuests.chk(strong, "toughness", Game.HARD)],
				"after": [{"n": "On the third blow the straps tear out of the frame." }, _fx("q:m_stores=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok_force
					else [{"n": "The door shudders and holds. Someone will have bruises tomorrow."}, _fx("hurtone:2")]},
			{"t": "Leave it.", "silent": true, "tip": "The foreman had the key.", "after": []},
		]},
	]


static func _water() -> Array:
	return [{"n": "The passage dips and disappears under black, still water, right up to the roof. It's far too deep and too cold to swim, and nobody weak could ever get through it."},
		{"i": "Sluices. Somewhere there must be a way to let this out."}]


static func _vein(cell: Vector2i) -> Array:
	if not has_item(38):
		return [{"n": "A seam of ore glitters in the rock: silver-grey, with flecks of something brighter. You'd need a pick to get any of it out."}]
	if free_slots() < 1:
		return [{"n": "A seam of ore glitters in the rock. (There is no room in anyone's pack for it.)"}]
	return [{"n": "With the miner's pick, a good lump of the glittering ore comes away from the seam. It is heavy."},
		_fx("item:%d" % ORE_ID), _fx("q:m_vein_%d_%d=1" % [cell.x, cell.y]),
		{"n": "(You take some Silver-Grey Ore. The smith in Lehan pays well for it.)"}]


static func _pillar(ch: String) -> Array:
	var what: String = {"1": "a chain, carved link by link", "2": "an open eye", "3": "a round seal, cut across"}[ch]
	if _q("m_ward") == "open":
		return [{"n": "A pillar carved with %s. The carving is dark now; the ward door stands open." % what}]
	var seq := _q("m_wards")
	var next := seq + ch
	var after: Array
	if WARD_ORDER.begins_with(next):
		if next == WARD_ORDER:
			after = [{"n": "The carving glows, and the glow runs along the floor to the east. With a grinding sigh, the ward door slides into the stone."},
				_fx("ward:" + ch), {"n": "(The ward door is open.)"}]
		else:
			after = [{"n": "Under your hand the carving begins to glow, a faint cold blue, and stays lit."}, _fx("ward:" + ch)]
	else:
		after = [{"n": "A cold jolt runs up your arm and through everyone near the pillars. Every carving that was glowing goes dark."},
			_fx("ward:" + ch), _fx("hurt:2")]
	var lit := "" if seq == "" else " (%s glowing so far.)" % ("One carving is" if seq.length() == 1 else "Two carvings are")
	return [{"n": "A pillar set into the wall, carved with %s.%s" % [what, lit]},
		{"choice": "pillar", "options": [
			{"t": "Lay a hand on the carving.", "silent": true, "after": after},
			{"t": "Leave it.", "silent": true, "after": []},
		]}]


static func _words() -> Array:
	var scholar := LehanQuests.best("lore")
	var ok := Game.check(scholar, "lore", Game.NORMAL)
	var out: Array = [{"n": "Words are cut into the wall in the same old script as the ward door, worn but deep."}]
	if _q("m_words") != "":
		out.append({"n": "\"First we bound him. Then we sealed him. Now, for ever, we keep watch.\""})
		return out
	out.append({"choice": "words", "options": [
		{"t": "Read the inscription.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(scholar, "lore", Game.NORMAL)],
			"after": [{"n": "%s reads it out slowly: \"First we bound him. Then we sealed him. Now, for ever, we keep watch.\"" % _first(scholar)},
				_fx("q:m_words=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
				else [{"n": "Nobody can read the old script. Among the letters you make out a carved chain, a seal and an eye, but not what is said of them."}]},
		{"t": "Leave it.", "silent": true, "after": []},
	]})
	return out


static func _note(key: String) -> Array:
	var out: Array = [_fx("q:m_note_%s=1" % key)]
	match key:
		"1n":
			out.append_array([{"n": "Chalked on a timber, in a big careful hand: \"Down past the old wall on two. Seam's rich. Back by Saturday. V.\""},
				{"n": "Below it, smaller, in another hand: \"Venner says the stash is behind the boards, NE. Don't tell Tobin.\""}])
		"2n":
			out.append_array([{"n": "A miner's tally board, nailed to the wall. Under the tallies someone has scratched, angrily:"},
				{"n": "\"SHUT THE TOP GATE FIRST, THEN PULL THE DRAIN. Or you'll flood us all again, Tobin, you fool.\""}])
	return out


static func _trap(key: String) -> Array:
	var eyes := LehanQuests.best("perception")
	var ok := Game.check(eyes, "perception", Game.NORMAL)
	var out: Array = [_fx("q:m_trap_%s=1" % key)]
	if key == "1p":
		if ok:
			out.append({"n": "%s stops you: the boards ahead are rotten, laid over an old pit. You edge around it." % _first(eyes)})
			out.append(_fx("xp:%s" % LehanQuests.CHECK_XP))
		else:
			out.append({"n": "The boards give way with a crack! Someone drops into an old pit before the others haul them out."})
			out.append(_fx("hurtone:4"))
			out.append(_fx("fail:mines"))
	else:
		if ok:
			out.append({"n": "%s spots the slightly raised stone in the floor, and the holes in the wall beside it. Everyone steps over it." % _first(eyes)})
			out.append(_fx("xp:%s" % LehanQuests.CHECK_XP))
		else:
			out.append({"n": "A stone sinks under a foot. Darts hiss out of the wall!"})
			out.append(_fx("hurt:3"))
			out.append(_fx("fail:mines"))
	return out


static func _breach() -> Array:
	var out: Array = [
		{"n": "Here the new gallery ends in a wall of fitted stone, and the wall has been broken through. Beyond the hole, steps lead down into a cold that doesn't belong in any mine."},
		{"n": "Two men lie in the rubble. One is young, still holding his pick. The other is older and broad, with a foreman's ring of keys on his belt. His face looks a lot like Hal's."},
		{"n": "Whatever killed them didn't use teeth. The wounds are clean, like old steel."},
		_fx("q:m_breach=1"),
		_fx("q:m_key=1"),
		{"n": "(You take the foreman's key from his belt, and the names scratched on the pick handles: Venner, and Tobin.)"},
	]
	if _host() != "":
		out.append({"sp": "They opened the door. They didn't know whose door it was."})
	return out


static func _survivors() -> Array:
	if _q("m_survivors") == "out":
		return []
	var out: Array = [
		{"n": "Behind a barricade of timber and ore sacks, three filthy, hollow-eyed men raise their picks, then lower them, staring at your torch."},
		{"s": "dunn", "t": "Folk! Real folk! Nine days we've been sat here. The spiders took the gallery, and the water took the other way."},
		{"s": "dunn", "t": "The foreman and Tobin broke the old wall. Something came out of the cold, in armour, and they fell. Young Hal ran for help. Did he make it?"},
		{"s": "dunn", "t": "And Saelen... the Aeldroe lass, she walked down through the breach with her eyes open, humming, and never answered when we shouted."},
		{"choice": "dunn", "options": [
			{"t": "Hal made it. The way out is clear now. Go home.", "say": _host(), "after": [
				{"s": "dunn", "t": "Then we go. Gods bless you. We'll tell the council you came."},
				_fx("q:m_survivors=out"),
				{"n": "Leaning on each other, the three miners shuffle off towards the shaft and the light."},
				{"n": "(The survivors are on their way home.)"}]},
		]},
	]
	return out


static func _saelen() -> Array:
	if _q("m_saelen") == "home":
		return []
	var mage := LehanQuests.best("magic")
	var talker := LehanQuests.best("talk")
	var ok_m := Game.ability(mage, "magic") > 0 and Game.check(mage, "magic", Game.NORMAL)
	var ok_t := Game.check(talker, "talk", Game.NORMAL)
	var home: Array = [
		{"s": "saelen", "t": "Where... It was calling. Somewhere below. It was so sad, and so angry, and it knew my name."},
		{"n": "She shivers, and for a moment you can see the stone behind her through her shoulder. Then she is solid again."},
		{"s": "saelen", "t": "I want to go home."},
		_fx("q:m_saelen=home"),
		{"n": "(Saelen heads up towards the breach, and home. She knows the way back up.)"},
	]
	if _host() != "ithrae":
		for c in Game.party:
			if LehanQuests.key_of(c) == "ithrae":
				home.insert(1, {"s": "ithrae", "t": "She faded. Just for a heartbeat. I've seen elders do that, but never one so young."})
	var opts: Array = []
	opts.append({"t": "Break the hold of the calling.", "silent": true, "ok": ok_m,
		"checks": [LehanQuests.chk(mage, "magic", Game.NORMAL).merged({"needs_skill": true})],
		"after": ([{"n": "%s lays a hand on her brow and pushes against something cold and old. It lets go." % _first(mage)},
			_fx("xp:%s" % LehanQuests.CHECK_XP)] + home) if ok_m
			else [{"n": "%s reaches for the calling and is pushed back, hard, by something much bigger." % _first(mage)}]})
	opts.append({"t": "Call her back: speak of home, the light, her people.", "silent": true, "ok": ok_t,
		"checks": [LehanQuests.chk(talker, "talk", Game.NORMAL)],
		"after": ([{"n": "%s talks to her, quietly, of sun on water and bread in the morning. Slowly her eyes find a face." % _first(talker)},
			_fx("xp:%s" % LehanQuests.CHECK_XP)] + home) if ok_t
			else [{"n": "She doesn't hear a word. The humming goes on."}]})
	if _host() != "":
		opts.append({"t": "Let the spirit answer the calling.", "tags": ["Spirit"], "silent": true, "tip": "No check. The spirit knows that voice.",
			"after": [{"sp": "Hush. Not her. You will have me, in time. Let her go."},
				{"n": "The humming stops in the middle of a note."}, {"i": "The host feels something below them turn over in its sleep, and listen."}] + home})
	opts.append({"t": "Pick her up and carry her out.", "silent": true, "tip": "Always works, but it isn't kind.",
		"after": [{"n": "She weighs almost nothing. Halfway back to the breach she wakes, weeping, and walks the rest herself."}] + home})
	return [
		{"n": "A young Aeldroe woman in miner's clothes stands facing the dark passage to the north. Her eyes are open. She is humming, very softly, a tune none of you knows."},
		{"choice": "saelen", "options": opts},
	]


static func _warden() -> Array:
	var out: Array = []
	if _q("m_warden") == "":
		out.append({"n": "The passage opens into a hall. At its end, a great gate of dark bronze and iron, banded and sealed. Before it stands a tall shape in plate armour, motionless, a long blade grounded at its feet."})
		out.append({"n": "In the slit of its helm two points of cold light kindle, and turn towards you."})
		if _host() != "":
			out.append({"sp": "The gate. I am behind that gate. All of me that is left."})
	else:
		out.append({"n": "The Warden stands before the gate, waiting, as it has waited for longer than Lehan has stood."})
		out.append({"i": "It can't be beaten. Not like this. Not yet."})
	out.append({"choice": "warden", "options": [
		{"t": "Attack the Warden.", "silent": true, "tip": "It guards the gate." if _q("m_warden") == "" else "You know how that went.",
			"after": [_fx("fight:warden")]},
		{"t": "Back away.", "silent": true, "after": [{"n": "You step back into the dark. The cold lights follow you, then go out."}]},
	]})
	return out


## After running from the Warden the first time: the hard lesson.
static func warden_after() -> Array:
	var out: Array = [_fx("q:m_warden=met")]
	out.append({"n": "Back in the passage, nobody speaks for a while. Every blow landed, and not one of them did anything."})
	if _host() != "":
		out.append({"sp": "Iron and oath. They made it to hold me, and no blade of theirs can touch it. Not while I am in pieces."})
		out.append({"sp": "Then I must not be in pieces. There are others of me, sleeping. Find them, and come back stronger."})
	out.append({"n": "(The Warden can't be beaten yet. Grow stronger elsewhere, and find out how to pass it.)"})
	return out


# ---------------------------------------------------------------- the lift

## The lift: broken until the crank is fitted (on the first level), then it goes to every level
## already reached.
static func lift(lv: int) -> Array:
	if _q("m_lift") == "":
		if lv != 1:
			return [{"n": "The lift shaft. The cage is far above, at the top. Its rope hangs slack."}]
		if not has_item(42):
			return [{"n": "The lift: a cage on a rope, over a shaft that drops away into the dark. The winding drum has no crank. Without one, it won't move."}]
		return [{"n": "The lift's winding drum has a square socket. The crank from the foreman's stores fits it exactly."},
			_fx("q:m_lift=1"), {"n": "(The lift works. It goes to every level you have reached.)"}]
	var opts: Array = []
	for to in range(1, MinesArea.MAPS.size() + 1):
		if to == lv or (to > 1 and _q("m_reached_%d" % to) == ""):
			continue
		opts.append({"t": "Ride to level %d: %s." % [to, MinesArea.NAMES[to - 1].to_lower()], "silent": true,
			"after": [{"n": "The cage creaks and sways as the rope pays out."}, _fx("travel:%d:lift" % to)]})
	opts.append({"t": "Stay here.", "silent": true, "after": []})
	return [{"n": "The lift cage, hanging ready."}, {"choice": "lift", "options": opts}]


# ---------------------------------------------------------------- Hal Venner, in Lehan

static func hal_talk() -> Array:
	var host := _host()
	if _q("mines") == "done":
		return [{"s": "hal", "t": "You brought them home. I'm at the inn when you need a sword."}]
	if _q("m_hal") != "":
		var out: Array = [{"s": "hal", "t": "Any news from below?"}]
		if _q("m_breach") != "":
			out.append({"s": host, "t": "We found your father, Hal. At the breach. I'm sorry."})
			out.append({"s": "hal", "t": "...I knew. I saw. I just needed someone else to say it."})
		else:
			out.append({"s": "hal", "t": "The lamp at the old camp, the stash behind the boards, the key on father's belt. Remember."})
		return out
	return [
		{"s": "hal", "t": "You're the ones the council hired? I'm Hal Venner. My father is the foreman up there. Was. Is."},
		{"s": "hal", "t": "I went in after them, nine days ago. The new diggings, on the second level. They'd broken through an old wall, and something came out of the cold. In armour. I saw father fall."},
		{"s": "hal", "t": "I ran. I'm not proud of it."},
		{"choice": "hal", "options": [
			{"t": "You ran for help. That's why we're here.", "say": host, "after": [
				{"s": "hal", "t": "...Thank you. Then let me help, at least with what I know."}, _fx("q:m_hal=1")] + _hal_hints()},
			{"t": "Tell us what's down there.", "say": host, "after": [_fx("q:m_hal=1")] + _hal_hints()},
		]},
	]


static func _hal_hints() -> Array:
	return [
		{"s": "hal", "t": "There's a spare lamp at the old camp on the first level. Take it: the second level has pockets of bad air, and the flame shows them."},
		{"s": "hal", "t": "Father kept a stash behind loose boards somewhere north-east on the first level. And the stores on two are locked. He had the key."},
		{"s": "hal", "t": "They flooded the low gallery on two to keep the water off the seam. There are sluices. Mind the order."},
		{"s": "hal", "t": "Find them. And when you know what happened, come back to the council. I'll be there to hear it."},
	]


# ---------------------------------------------------------------- reporting back

## Reporting back to the council (CouncilData calls this once the job is taken).
static func report() -> Array:
	var job: Dictionary = Game.story.get("mines_job", {"pay": CouncilData.state().offer})
	if _q("mines") == "done":
		return [{"s": "brask", "t": "The council remembers what you did in the mines. Lehan owes you."}, {"end": true}]
	var missing: Array = []
	if _q("m_survivors") != "out":
		missing.append("Three of the miners may still be alive down there. Where are they?")
	if _q("m_breach") == "":
		missing.append("And the foreman? What became of Venner and the others?")
	if _q("m_saelen") != "home":
		missing.append("The Aeldroe girl, Saelen. Her mother is at the door every day.")
	if not missing.is_empty():
		var out: Array = [{"s": "brask", "t": "You have the council's word: %d silver when you return with news of the miners." % job.pay}]
		if Game.mines_entered():
			out.append({"s": "brannoc", "t": "You've been up there. Good. But we need the whole story, not half of it."})
			for m in missing:
				out.append({"s": "brannoc", "t": m})
		else:
			out.append({"s": "brannoc", "t": "Well? The hills are that way. Out the south gate."})
		out.append({"end": true})
		return out
	var out: Array = [
		{"n": "Hal Venner is waiting outside the council house, and follows you in. Old Dunn and the other two survivors are there already, washed and fed, and Saelen sits by the fire with a blanket round her shoulders."},
		{"s": "brask", "t": "The miners say you found them. Tell the council the rest."},
		{"s": _host(), "t": "The foreman and Tobin died at the breach. They broke through into old galleries, older than Lehan, guarded by things that should have stayed dead."},
		{"s": "hal", "t": "...Thank you for telling it straight."},
		{"s": "brask", "t": "%d silver, as agreed. The council keeps its word." % job.pay},
		_fx("silver:%d" % job.pay),
	]
	if _q("m_warden") != "":
		out.append({"s": _host(), "t": "There is something else down there. A gate, and a guardian before it that no blade can touch."})
		out.append({"s": "brannoc", "t": "Then nobody goes below the diggings. The council will put a guard on the shaft."})
	if _q("m_seal") != "":
		out.append({"choice": "seal", "options": [
			{"t": "Show the council the seal from the sealed galleries.", "say": _host(), "after": [_fx("q:m_seal_told=1"),
				{"n": "Master Hale goes white."},
				{"s": "hale", "t": "That's the Holm mark. The tower and the chain. My grandfather laid that wall as a mason. The Holms paid him, and swore him to silence. He told me it was bad air they were hiding."},
				{"s": "brannoc", "t": "The Holms? Garreth Holm's family? Put that away, before anyone else sees it."},
				{"i": "The Holms. One of Lehan's old families. Whatever they swore to keep down there, they kept it for a very long time."}]},
			{"t": "Keep the seal to yourself, for now.", "say": _host(), "silent": true, "after": [
				{"i": "Not here. Not in front of Hale, whose grandfather built that wall."}]},
		]})
	out.append_array([
		{"s": "hal", "t": "My father would want someone to finish what he started. If your company has room for a sword, I'll be at the inn."},
		_fx("recruit:hal"),
		_fx("q:hal=done"),
		_fx("q:mines=done"),
	])
	out.append_array(LehanQuests.finish_xp_steps("mines"))
	out.append({"n": "(Hal Venner is on the inn's list. The mines are still there for the brave: monsters keep coming up from below.)"})
	out.append({"end": true})
	return out
