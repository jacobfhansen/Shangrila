class_name ShrineQuest
extends RefCounted
## What happens at the Drowned Shrine (ShrineArea): the grounds' sigils, the carving that tells
## their order, Old Moss's fish pens, the offering box, and the sunken door with its ways in.
## The dungeon screen calls this like MinesQuest when Game.site == "shrine".
## Quest values: s_sigil_1/2/3, s_order ("known": the carving read), s_door ("open"), s_loud (the
## door was forced: the temple below is warned), s_grp_<key>, s_chest_<key>, s_reached_<lv>;
## marsh_leeches ("done" once the pens are cleared), marsh_chant (Ubba taught it).

const DARK := false   # out under the sky
const SIGILS := {"1": 54, "2": 55, "3": 56}   # crown, chain, wave
const ORDER := "123"
const GROUPS := {
	"1N": {"m": [{"key": "reed_stalker", "n": 2}], "intro": "The reeds by the wall part. Two Reed Stalkers unfold from their nest, beaks like spears."},
	"1T": {"m": [{"key": "mire_toad", "n": 1}], "intro": "The mud heaves. Something huge and warty was squatting on the offering box all along: a Mire Toad."},
	"pens": {"m": [{"key": "bog_leech", "n": 5}], "intro": "You wade in. The water boils with fat, ringed bodies."},
}
const WANDERING := [
	[{"key": "bog_leech", "n": 4}],
	[{"key": "reed_stalker", "n": 1}, {"key": "bog_leech", "n": 2}],
	[{"key": "marsh_light", "n": 2}, {"key": "bog_leech", "n": 2}],
	[{"key": "marsh_light", "n": 3}],
]


static func q(k: String) -> String:
	return LehanQuests.get_q(k)


static func _fx(fx: String) -> Dictionary:
	return {"fx": fx, "wait": 0.1}


static func _host() -> String:
	return Game.story.get("host", "")


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


static func cast() -> Dictionary:
	return MarshData.cast()


static func wandering(_lv: int) -> Array:
	return WANDERING.pick_random()


static func has_item(id: int) -> bool:
	return not Game.holder_of(id).is_empty()


static func arrive_line(lv: int, arrived: bool) -> String:
	if lv == 1:
		return "You come up the steps from the causeway, over a fallen wall." if not arrived else "Back in the grounds."
	return "Down in the drowned temple."


## True the first time the party comes to a level (and remembers it).
static func first_visit(lv: int) -> bool:
	if q("s_reached_%d" % lv) != "":
		return false
	LehanQuests.apply("q:s_reached_%d=1" % lv)
	return true


static func arrival(lv: int) -> Array:
	if lv != 1:
		return []
	var out: Array = [
		{"n": "The causeway ends at a ring of broken walls, green with ivy, standing up out of the water. Inside, flagstones slick with mud, pools black as ink, reeds taller than a man. Statues lie where they fell, faces worn away."},
		{"n": "Somewhere in the middle, behind a low inner wall, is the way down. Nobody has lived here for a very long time. Something has, though: the mud is full of tracks."},
	]
	if _host() != "":
		out.append({"sp": "I built this. No: I had it built. I remember standing where the water is now, watching them carry stone."})
	return out


# ---------------------------------------------------------------- the scenes

static func scene(lv: int, t: Dictionary) -> Array:
	match t.kind:
		"carving": return _carving()
		"sigil": return _sigil(t.ch)
		"pens": return _pens()
		"shrine_door": return _door()
		"chest": return _chest(t.key, t.done)
		"statue": return [{"n": "A statue of a crowned figure, toppled face down in the mud. Long ago someone took a hammer to its face."}]
	return []


static func _carving() -> Array:
	var reader := LehanQuests.best("lore")
	if q("s_order") == "known":
		return [{"n": "Three panels: the crown, the chain, the waves. A king crowned, a king bound, a king drowned."}]
	var ok := Game.ability(reader, "lore") > 0 and Game.check(reader, "lore", Game.NORMAL)
	return [
		{"n": "Panels carved into the wall, half hidden under ivy: a crown, a chain, waves. Under each, small figures, the last of them under a line of water."},
		{"choice": "carving", "options": [
			{"t": "Read the panels as a story.", "silent": true, "ok": ok,
				"checks": [LehanQuests.chk(reader, "lore", Game.NORMAL).merged({"needs_skill": true})],
				"after": [{"n": "%s traces the old lines. \"It's an order. First the crown: a king made. Then the chain: the king bound by his own lords. Then the water: the king drowned. Crown, chain, wave.\"" % _first(reader)},
					_fx("q:s_order=known"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
					else [{"n": "%s stares at the panels until the ivy seems to move. Old, worn, and whatever they mean, it won't come." % _first(reader)}]},
			{"t": "Leave it.", "silent": true, "after": []},
		]},
	]


static func _sigil(ch: String) -> Array:
	var id: int = SIGILS[ch]
	var nm: String = Game.item(id).name
	match ch:
		"1":
			return [{"n": "In the lap of a broken statue lies a disc of dark stone, as wide as a hand, carved with a crown."},
				_fx("item:%d" % id), _fx("q:s_sigil_1=1"), {"n": "(You take the %s.)" % nm}]
		"2":
			var looker := LehanQuests.best("perception")
			if Game.check(looker, "perception", Game.NORMAL):
				return [{"n": "%s stops, knee-deep. Something round and dark under the water, too regular for a stone. A disc, carved with a chain." % _first(looker)},
					_fx("item:%d" % id), _fx("q:s_sigil_2=1"), _fx("xp:%s" % LehanQuests.CHECK_XP), {"n": "(You take the %s.)" % nm}]
			return [{"n": "Something glints under the shallow water, and then the mud swirls up and it's gone."},
				{"n": "(Perception: %s didn't find it this time. Step back here, or search with Examine, to look again.)" % _first(looker)}]
		"3":
			return [{"n": "In the trampled nest, among fish bones and a broken spear, lies a disc of dark stone carved with waves."},
				_fx("item:%d" % id), _fx("q:s_sigil_3=1"), {"n": "(You take the %s.)" % nm}]
	return []


static func _pens() -> Array:
	var woods := LehanQuests.best("survival")
	var ok := Game.ability(woods, "survival") > 0 and Game.check(woods, "survival", Game.NORMAL)
	var out: Array = [{"n": "Old Moss's fish pens: rings of wicker fencing in warm, still water against the wall. Dead fish float belly-up. Between them slide leeches as long as your arm."}]
	out.append({"choice": "pens", "options": [
		{"t": "Wade in and kill them.", "silent": true, "after": [_fx("fight:pens")]},
		{"t": "Smoke them out with burning reeds.", "silent": true, "ok": ok,
			"checks": [LehanQuests.chk(woods, "survival", Game.NORMAL).merged({"needs_skill": true})],
			"after": [{"n": "%s builds a smudge of green reeds upwind and fans it low over the water. The leeches writhe, let go of the fish, and slither away over the wall into the marsh." % _first(woods)},
				_fx("q:marsh_leeches=done"), _fx("xp:%s" % LehanQuests.CHECK_XP),
				{"n": "(The pens are clear. Old Moss and Ubba will want to hear.)"}] if ok
				else [{"n": "The reeds are too wet. They smoulder, the smoke goes everywhere but over the water, and the leeches don't care."}]},
		{"t": "Leave them.", "silent": true, "after": []},
	]})
	return out


static func _chest(k: String, done: bool) -> Array:
	if done:
		return [{"n": "The offering box, empty now."}]
	return [{"n": "An old offering box of grey stone, its lid pushed half off by roots. Inside, under silt: green coins and a bundle of herbs sealed in wax."},
		_fx("silver:12"), _fx("item:28"), _fx("item:28"), _fx("q:s_chest_%s=1" % k),
		{"n": "(You take 12 silver and 2 Alnon Leaves.)"}]


static func _door() -> Array:
	if q("s_door") != "":
		return [{"n": "The sunken door stands open. Steps go down into the dark, and the air that comes up smells of old water."},
			{"n": "(The drowned temple below is the next part of the marsh to be built.)"}]
	var has_all := SIGILS.values().all(func(id): return has_item(id))
	var strong := LehanQuests.best("toughness")
	var deft := LehanQuests.best("thievery")
	var ok_force := Game.check(strong, "toughness", Game.HARD)
	var ok_pick := Game.ability(deft, "thievery") > 0 and Game.check(deft, "thievery", Game.NORMAL)
	var opened := [_fx("q:s_door=open"), {"n": "(The way down is open.)"}]
	if _host() != "":
		opened.append({"sp": "Down there. I can feel it, like a tooth that aches. Another piece of me."})
	var out: Array = [{"n": "Set into the inner wall, a door of dark stone, sunk a step below the flagstones. Three round sockets in a row, empty. No handle, no hinge, but an old lock plate, green with age."}]
	var opts: Array = []
	if has_all:
		if q("s_order") == "known":
			opts.append({"t": "Set the sigils in: crown, chain, wave.", "silent": true,
				"after": [{"n": "Crown, chain, wave. Each disc settles into its socket with a click. Deep in the wall, something heavy turns over, and the door sinks into the floor, quiet as water."},
					_fx("take:54"), _fx("take:55"), _fx("take:56")] + opened})
		else:
			for order in ["123", "321", "213"]:
				var names: Array = []
				for ch in order:
					names.append({"1": "crown", "2": "chain", "3": "wave"}[ch])
				var right: bool = order == ORDER
				opts.append({"t": "Set the sigils in: %s." % ", ".join(names), "silent": true,
					"tip": "The order matters. Something here may tell it.",
					"after": ([{"n": "Each disc settles into its socket with a click. Deep in the wall, something heavy turns over, and the door sinks into the floor, quiet as water."},
						_fx("take:54"), _fx("take:55"), _fx("take:56")] + opened) if right
						else [{"n": "The last disc goes in, and a cold jolt throws everyone back from the door. The discs spit out of their sockets into the mud."},
							_fx("hurt:2"), {"n": "(Wrong order. The sigils lie by the door; you pick them up again.)"}]})
	if q("marsh_chant") != "":
		opts.append({"t": "Sing Ubba's chant.", "silent": true,
			"after": [{"n": "The old words come out strange in a stranger's mouth, but the door knows them. The sockets fill with a pale light, and the door sinks into the floor without a sound."}] + opened})
	opts.append({"t": "Force it open.", "silent": true, "ok": ok_force, "checks": [LehanQuests.chk(strong, "toughness", Game.HARD)],
		"tip": "It would open, but not quietly.",
		"after": ([{"n": "%s wedges a spear shaft into the seam and heaves. Stone grinds on stone with a scream that sends birds up from every reed bed, and the door lurches down a hand's width, then another, and drops." % _first(strong)},
			_fx("q:s_loud=1"), {"n": "(Whatever waits below heard that.)"}] + opened) if ok_force
			else [{"n": "%s heaves until something in the shoulder pops. The door doesn't move." % _first(strong)}, _fx("hurtone:3")]})
	if Game.ability(deft, "thievery") > 0:
		opts.append({"t": "Work the old lock.", "silent": true, "ok": ok_pick,
			"checks": [LehanQuests.chk(deft, "thievery", Game.NORMAL).merged({"needs_skill": true})],
			"tip": "Old locks complain.",
			"after": ([{"n": "%s finds the keyhole under the green and feels for the wards. The mechanism gives with a shriek of old bronze that echoes off the walls, and the door sinks." % _first(deft)},
				_fx("q:s_loud=1"), {"n": "(Loud. Whatever waits below heard that.)"}] + opened) if ok_pick
				else [{"n": "The lock is choked with silt. %s's pick bends and comes out empty." % _first(deft)}]})
	if not has_all and q("marsh_chant") == "":
		out.append({"n": "(Three sockets: something must fit them. Or someone might know another way.)"})
	opts.append({"t": "Leave it.", "silent": true, "after": []})
	out.append({"choice": "door", "options": opts})
	return out


# ---------------------------------------------------------------- effects

static func apply(fx: String) -> void:
	if fx.begins_with("take:"):
		Game.take_item(int(fx.substr(5)))
	else:
		MarshRoad.apply(fx)


## After a placed group (or the pens) is beaten.
static func won(tag: String) -> void:
	if tag == "pens":
		LehanQuests.apply("q:marsh_leeches=done")
	elif tag != "":
		LehanQuests.apply("q:s_grp_%s=1" % tag)
