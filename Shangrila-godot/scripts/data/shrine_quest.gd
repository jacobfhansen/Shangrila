class_name ShrineQuest
extends RefCounted
## What happens at the Drowned Shrine (ShrineArea): the grounds' sigils, the carving that tells
## their order, Old Moss's fish pens, the offering box, and the sunken door with its ways in.
## The dungeon screen calls this like MinesQuest when Game.site == "shrine".
## Quest values: s_sigil_1/2/3, s_order ("known": the carving read), s_door ("open"), s_loud (the
## door was forced: the temple below is warned), s_grp_<key>, s_chest_<key>, s_reached_<lv>;
## marsh_leeches ("done" once the pens are cleared), marsh_chant (Ubba taught it).
## The temple (level 2): s_reign_K / s_reign_J (the west and east carvings read), s_hall ("seen"),
## s_path ("known": the stones' order, from both carvings, Ubba's song or the spirit's memory),
## s_step (the last right stone in the hall), s_washed (how often the water threw them back),
## s_tracks (the sect's broken ward seen), s_remnant ("merged"); marsh_song (Ubba sang it).

const DARK := false   # out under the sky (the temple below is dark: is_dark)
const SIGILS := {"1": 54, "2": 55, "3": 56}   # crown, chain, wave
const ORDER := "123"
const GROUPS := {
	"1N": {"m": [{"key": "reed_stalker", "n": 2}], "intro": "The reeds by the wall part. Two Reed Stalkers unfold from their nest, beaks like spears."},
	"1T": {"m": [{"key": "mire_toad", "n": 1}], "intro": "The mud heaves. Something huge and warty was squatting on the offering box all along: a Mire Toad."},
	"pens": {"m": [{"key": "bog_leech", "n": 5}], "intro": "You wade in. The water boils with fat, ringed bodies."},
	"2A": {"m": [{"key": "drowned", "n": 2}], "intro": "Two shapes rise out of the knee-deep water, pale and swollen, in the rags of priests' robes. The Drowned."},
	"2B": {"m": [{"key": "drowned", "n": 2}, {"key": "bog_leech", "n": 3}], "intro": "Something stands up in the far corner, water pouring off it. Then another. Leeches hang from them like ribbons."},
	# The door was forced or picked: they heard, and they are waiting at the foot of the steps.
	"loud": {"m": [{"key": "drowned", "n": 3}, {"key": "bog_leech", "n": 2}], "intro": "They heard you come in. At the foot of the steps the Drowned are already waiting, three of them, and the water around their legs is alive with leeches."},
}
const WANDERING := [
	[{"key": "bog_leech", "n": 4}],
	[{"key": "reed_stalker", "n": 1}, {"key": "bog_leech", "n": 2}],
	[{"key": "marsh_light", "n": 2}, {"key": "bog_leech", "n": 2}],
	[{"key": "marsh_light", "n": 3}],
]
const WANDERING_TEMPLE := [
	[{"key": "drowned", "n": 2}],
	[{"key": "bog_leech", "n": 4}],
	[{"key": "drowned", "n": 1}, {"key": "bog_leech", "n": 2}],
]
## Ubba's counting rhyme, the children's song of the drowned house: the stones' order.
const SONG := "Crown on his head, rose in his hand,\nfire on her people all over the land,\nchain on his wrists from the lords that he made,\nand down in the water the king is laid."


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


static func wandering(lv: int) -> Array:
	return (WANDERING if lv == 1 else WANDERING_TEMPLE).pick_random()


static func is_dark(lv: int) -> bool:
	return lv == 2


static func has_item(id: int) -> bool:
	return not Game.holder_of(id).is_empty()


static func arrive_line(lv: int, arrived: bool) -> String:
	if lv == 1:
		return "You come up the steps from the causeway, over a fallen wall." if not arrived else "Back in the grounds."
	return "You go down the steps into the drowned temple." if arrived else "Down in the drowned temple."


## True the first time the party comes to a level (and remembers it).
static func first_visit(lv: int) -> bool:
	if q("s_reached_%d" % lv) != "":
		return false
	LehanQuests.apply("q:s_reached_%d=1" % lv)
	return true


static func arrival(lv: int) -> Array:
	if lv == 2:
		return _temple_arrival()
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
		"chest": return _chest(t.key, t.done) if lv == 1 else _chest_temple(t.key, t.done)
		"statue": return [{"n": "A statue of a crowned figure, toppled face down in the mud. Long ago someone took a hammer to its face."}]
		"reign": return _reign(t.ch)
		"ward_broken": return _broken_ward()
		"hall": return _hall()
		"stone": return _stone(t)
		"basin": return _basin(t.done)
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
			{"choice": "down", "options": [{"t": "Go down.", "silent": true, "after": [_fx("travel:2:down")]},
				{"t": "Not yet.", "silent": true, "after": []}]}]
	var has_all := SIGILS.values().all(func(id): return has_item(id))
	var strong := LehanQuests.best("toughness")
	var deft := LehanQuests.best("thievery")
	var ok_force := Game.check(strong, "toughness", Game.HARD)
	var ok_pick := Game.ability(deft, "thievery") > 0 and Game.check(deft, "thievery", Game.NORMAL)
	var opened := [_fx("q:s_door=open"), {"n": "(The way down is open: walk into the door to go down.)"}]
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


# ---------------------------------------------------------------- the temple (level 2)

static func _temple_arrival() -> Array:
	var out: Array = [
		{"n": "The steps go down a long way. At the bottom the air is cold and still, and the torchlight comes back off water: the low halls are flooded knee-deep, black and quiet."},
		{"n": "Dressed stone, close-fitted, the work of people who were made to do it well. Carvings on the walls, under a skin of green. Somewhere ahead, water drips into water."},
	]
	if _host() != "":
		out.append({"sp": "Closer. It's here, under all this water. I can feel it the way you feel a word you can't remember."})
	if q("s_loud") != "":
		out.append(_fx("fight:loud"))
	return out


## The carvings of the king's reign. K, the west wall: his glory (the crown, the rose). J, the
## east wall: his fall (the fire, the chain, the water). Both read: the stones' order is known.
static func _reign(ch: String) -> Array:
	var west := ch == "K"
	var reader := LehanQuests.best("lore")
	var looks := [{"n": "Panels cut deep into the wall: a crown over a crowd of kneeling figures; then a rose, and a woman turned away from a man who holds it out."}] if west \
		else [{"n": "Panels cut deep into the wall: flames over a city of thin, tall people; then a chain, a crowned man bound by men in mail; then water, and the man under it."}]
	if q("s_reign_" + ch) != "":
		var out: Array = [looks[0]]
		out.append({"n": "(Read already: %s.)" % ("first the crown, then the rose" if west else "then the fire, then the chain, and last the water")})
		return out
	var ok := Game.ability(reader, "lore") > 0 and Game.check(reader, "lore", Game.NORMAL)
	var read_line := "%s follows the panels with a finger. \"The king crowned, and everyone on their knees. Then the rose: he loved someone, and she would not have him. It reads left to right, like the door upstairs.\"" % _first(reader) if west \
		else "%s reads it slowly. \"After the rose, fire. He burned her people, the tall ones. Then his own lords put him in chains. Then the water.\" A pause. \"It's the same story as the panels upstairs, only more of it.\"" % _first(reader)
	var after: Array = [{"n": read_line}, _fx("q:s_reign_%s=read" % ch), _fx("xp:%s" % LehanQuests.CHECK_XP)]
	var other := "J" if west else "K"
	if q("s_reign_" + other) != "":
		after.append(_fx("q:s_path=known"))
		after.append({"n": "(With both walls read, the whole story is clear: the crown, the rose, the fire, the chain, and then the water.)"})
	else:
		after.append({"n": "(Half of a story. The rest must be carved somewhere else down here.)"})
	if _host() != "" and not west:
		after.append({"sp": "That isn't how it was. It can't be how it was. I don't remember any fire."})
	var out: Array = looks.duplicate()
	out.append({"choice": "reign", "options": [
		{"t": "Read the carvings as a story.", "silent": true, "ok": ok,
			"checks": [LehanQuests.chk(reader, "lore", Game.NORMAL).merged({"needs_skill": true})],
			"after": after if ok else [{"n": "%s squints at the worn figures. Something about a king. The rest has gone soft under the green." % _first(reader)}]},
		{"t": "Leave it.", "silent": true, "after": []},
	]})
	return out


## The sect was here first: a ward slab like the ones under Lehan, freshly broken, and boot prints.
static func _broken_ward() -> Array:
	var out: Array = [
		{"n": "A slab of carved stone lies broken in two in the shallows. The same carvings as the ward-stones under Lehan: chains, an eye, a seal. Somebody set it here long ago to keep something in."},
		{"n": "Somebody broke it recently. The edges are clean and pale, not yet green. In the silt around it, boot prints, sharp-edged, a few weeks old at most, and a grey thread caught on the stone."},
		{"n": "City boots, hobnailed in neat rows. Nobody in the marshes wears boots like that, or in Lehan either."},
	]
	if q("marsh_orrun") == "trust":
		out.append({"n": "(Grey cloth. Orrun said the strangers a month ago wore grey.)"})
	if _host() != "":
		out.append({"sp": "They were here. The ones who keep the oath. They came for it, and broke their own ward to get in. But they didn't reach it, did they? I'd know."})
	out.append(_fx("q:s_tracks=seen"))
	return out


static func _chest_temple(k: String, done: bool) -> Array:
	if done:
		return [{"n": "The priest's niche, empty now."}]
	return [{"n": "A niche in the wall where a priest kept the temple's offerings. Behind a fallen slab: a pouch gone stiff with age, full of old silver, and a jar of healing roots sealed with wax."},
		_fx("silver:30"), _fx("item:29"), _fx("item:29"), _fx("item:28"), _fx("q:s_chest_%s=1" % k),
		{"n": "(You take 30 silver, 2 Alman Roots and an Alnon Leaf.)"}]


static func _path_known() -> bool:
	return q("s_path") != ""


## The threshold of the flooded hall: the stones, and the ways to learn their order.
static func _hall() -> Array:
	var out: Array = []
	if q("s_hall") == "":
		out.append({"n": "A long hall, flooded wall to wall. Pillars march away into the dark on either side. Across the water, stepping stones in rows of three, each with a sign cut into its top. At the far end, on a step, a stone basin, and in it a faint light under black water."})
		out.append({"n": "The water between the stones is deep, and something about the stillness says: don't."})
		out.append(_fx("q:s_hall=seen"))
	else:
		out.append({"n": "The flooded hall: rows of stepping stones, each with its sign, and the basin glowing faintly at the far end."})
	var host := _host()
	var opts: Array = []
	if host != "":
		var who: Dictionary = Game.party[0]
		for c in Game.party:
			if LehanQuests.key_of(c) == host:
				who = c
		opts.append({"t": "Let the spirit remember the way.", "silent": true,
			"tip": "The spirit's memory of this place is buried deep, and digging it up will hurt its host.",
			"after": [{"sp": "Let me look. Let me... the crown. Yes. The rose: her. Then..."},
				{"n": "%s's hands go to their temples. Their face is grey." % _first(who)},
				{"sp": "Fire. On the tall ones, on her people. And then the chains, my own lords, and then the water. That's the way across. I wish I hadn't looked."},
				_fx("hurthost:4"), _fx("q:s_path=known"),
				{"n": "(The spirit remembers: the crown, the rose, the fire, the chain.)"}]})
	opts.append({"t": "Go on.", "silent": true, "after": []})
	if not _path_known():
		out.append({"n": "(Each row has one right stone. The carvings in this temple, or someone who knows the old stories, might tell which.)"})
		out.append({"choice": "hall", "options": opts})
	return out


## A step onto one of the hall's stones: the right one holds, a wrong one tips and the water
## rises and throws the party back to the threshold.
static func _stone(t: Dictionary) -> Array:
	var sign: String = t.sign
	var nm: String = ShrineArea.SIGN_NAMES[sign]
	if t.right:
		var out: Array = [{"n": "The stone carved with %s holds, steady as a floor." % nm}, _fx("q:s_step=%d" % t.row)]
		if t.row == 4:
			out.append({"n": "Ahead, the last ledge, and the basin."})
		return out
	var washed := int("0" + q("s_washed")) + 1
	return [{"n": "The stone carved with %s tips under your weight. All at once the still water isn't still: it heaves up between the stones, cold as winter, takes everyone off their feet and throws them back across the hall." % nm},
		_fx("hurtone:4"), _fx("q:s_step=0"), _fx("q:s_washed=%d" % washed), _fx("wash"),
		{"n": "(Back at the threshold, soaked, coughing. Each row has one right stone.)"}]


## The basin: the remnant, its memory, and the merge.
static func _basin(done: bool) -> Array:
	if done:
		return [{"n": "The basin's water is clear now. You can see the bottom: plain stone, and nothing on it."}]
	var out: Array = [
		{"n": "The basin is full to the brim with water so black it looks solid. Under the surface, far deeper than the bowl could be, something gives off a pale, slow light, like breath."},
	]
	if _host() != "":
		out.append({"sp": "There. There you are."})
	out.append({"n": "As the host leans over the water, the light rises to meet them, and for a moment the hall is somewhere else."})
	out.append({"n": "A hall of white stone, open to the sky, full of people. A crown of plain iron, heavy and cold. Banners from a dozen beaten armies hung along the walls, and the people below cheering, and meaning it. A king who was good at being king. The realm of Shangrila, and every road in it safe."})
	out.append({"n": "And among the faces, one: a woman of the tall, pale people, nearly as bright as the light coming through the roof. She doesn't cheer. She looks at him the way you look at weather. Then she turns and walks out, and the memory goes with her."})
	if _host() != "":
		out.append({"sp": "I was loved. I was. Everyone loved me. Everyone but her."})
	out.append({"n": "The light goes into the host like a held breath let out. The water in the basin turns clear, all at once, and so does the water across the whole hall."})
	out.append(_fx("remnant"))
	out.append(_fx("q:s_remnant=merged"))
	out.append(_fx("q:marsh=done"))
	if _host() != "":
		out.append({"sp": "And there's more of me still. North. Behind iron, in a house that knows my name. I can feel it pulling, like a tide."})
	out.append(_fx("known:aubermont"))
	out.append(_fx("xp:%s" % LehanQuests.DONE_XP))
	out.append({"n": "(The spirit has merged with its second remnant. Insight: it can see into the people who follow it now. Their nature shows on the character sheet and in conversations, and so does their nerve.)"})
	if _host() != "":
		out.append({"sp": "I can see them. All of you, the way I see my host. Not only what you say: what you are. Don't be afraid. I'll be careful with it."})
	out.append({"n": "(Aubermont, the great city of the north, is on the world map now: four days from Lehan by the north road.)"})
	return out


# ---------------------------------------------------------------- effects

static func apply(fx: String) -> void:
	if fx.begins_with("take:"):
		Game.take_item(int(fx.substr(5)))
	elif fx.begins_with("known:"):
		if not fx.substr(6) in Game.known:
			Game.known.append(fx.substr(6))
	elif fx == "wash":
		Game.pos = ShrineArea.HALL_BACK
		Game.facing = 0
	elif fx.begins_with("hurthost:"):
		var host := _host()
		for c in Game.party:
			if LehanQuests.key_of(c) == host:
				c.hits = maxi(1, c.hits - int(fx.substr(9)))
	elif fx == "remnant":
		Game.story["remnants"] = 2
		Game.story["insight"] = true
	else:
		MarshRoad.apply(fx)


## After a placed group (or the pens) is beaten.
static func won(tag: String) -> void:
	if tag == "pens":
		LehanQuests.apply("q:marsh_leeches=done")
	elif tag == "loud":
		LehanQuests.apply("q:s_grp_2A=1")
	elif tag != "":
		LehanQuests.apply("q:s_grp_%s=1" % tag)
