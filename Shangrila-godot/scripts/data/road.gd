class_name RoadData
extends RefCounted
## The road from the shrine to Lehan: chatter, the brigands' ambush (the first fight), and the
## moment the spirit takes full hold of its host. Lines are given to preferred speakers; if the
## preferred one is the host, the next in the list speaks instead.

const BRIGAND := {"name": "Brigand", "race": "Human",
	"look": {"skin": "#c09070", "hair": "#2a2018", "cloth": "#3a3028", "hood": true}}

## The ambush itself.
const AMBUSH := [{"key": "brigand", "n": 3}]


static func _pick(prefer: Array, host: String) -> String:
	for k in prefer:
		if k != host:
			return k
	return prefer[0]


static func _name(key: String) -> String:
	return PrologueData.CAST[key].name


## Everything up to the moment steel is drawn.
static func before(host: String) -> Array:
	var h := _name(host)
	var asker := _pick(["ommuk", "maera", "joss"], host)
	var joker := _pick(["tikkat", "joss", "ommuk"], host)
	var lead := _pick(["joss", "maera", "ommuk"], host)
	return [
		{"n": "The road to Lehan winds down through wet fields. The company walks in a loose line, tools over their shoulders."},
		{"s": lead, "t": "Easiest silver we've earned all year. Smash a rock, get paid."},
		{"s": _pick(["tikkat", "ommuk", "maera"], host), "t": "Easiest? My arms are still shaking."},
		{"i": "%s's legs carry them along the road. Through those eyes the spirit drinks in everything: the fields, the sky, the faces. All of it new. None of it new." % h},
		{"s": asker, "t": "%s, you've been quiet since the shrine." % h},
		{"choice": "road", "speakers": true, "prompt": "Choose a reply (1-3)", "options": [
			{"t": "Just tired. Bad night.", "say": host,
				"after": [{"s": asker, "t": "Hm."}, {"n": "%s does not look convinced." % _name(asker)}]},
			{"t": "Leave it.", "say": host,
				"after": [{"n": "Nobody pushes. But the sideways glances keep coming."}]},
			{"t": "(Look at the sky, and say nothing.)", "silent": true,
				"after": [{"s": joker, "t": "Great. Now %s's gone strange too." % h}]},
		]},
		{"s": _pick(["maera", "ithrae", "ommuk"], host), "a": "quietly", "t": "Has anyone noticed %s hasn't blinked in a while?" % h},
		{"s": joker, "t": "Don't. Don't say things like that on an empty road."},
		{"n": "Where the road dips between two thorn hedges, a bird bursts from the brush. Then it is very quiet."},
		{"s": "brigand", "a": "stepping out onto the road", "t": "That's far enough. Purses on the road, and nobody gets hurt. Much."},
		{"s": lead, "t": "Five of us, three of you. Bad sums, friend."},
		{"s": "brigand", "t": "There's always more of us than you can see."},
		{"n": "Steel comes out on both sides."},
		{"i": "The spirit cannot move %s's sword arm. Not yet. But it can lend a little sureness to a blow, or turn one aside." % h},
	]


## After the fight. `used` counts the spirit's help: {"bless": n, "ward": n}.
static func after(host: String, result: String, used: Dictionary) -> Array:
	var h := _name(host)
	var steps := []
	if result == "lost":
		steps.append({"n": "The brigands strip the fallen company of coin and vanish into the hedges. Hours later, bruised and poorer, the company picks itself up out of the ditch."})
	else:
		steps.append({"n": "The last brigand breaks and runs into the hedges. The road is quiet again."})
	if used.get("ward", 0) > 0:
		steps.append({"s": _pick(["maera", "ommuk", "ithrae"], host), "t": "Did anyone else see that? The blows didn't want to touch %s. They just... turned." % h})
	elif used.get("bless", 0) > 0:
		steps.append({"s": _pick(["joss", "maera", "tikkat"], host), "t": "Where did %s learn to fight like that?" % h})
	else:
		steps.append({"s": _pick(["tikkat", "ommuk", "joss"], host), "t": "Lucky. We were lucky."})
	steps.append({"i": "Something settles inside %s, like a hand closing around a sword hilt. The spirit has found its grip." % h})
	steps.append({"n": "(From now on the spirit has full control of %s. The others still act on their own.)" % h})
	steps.append({"n": "By evening the walls of Lehan rise out of the fields."})
	return steps
