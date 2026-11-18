class_name LisbetQuest
extends RefCounted
## Lisbet's letter, the first Lehan quest (see LehanQuests and IDEAS.md). Lisbet asks the host to
## carry a sealed letter down the gate road to Sergeant Rudd: nobody may follow, nobody may open
## it. On the gate road someone does follow (her little brother Pip); at the gate the host may
## open the letter. It is a test, and every host passes it in their own way. The letter tells
## what the council has really set aside for the missing miners, which helps at the council.
##
## Checks are rolled when a scene is built, so each option already holds its own outcome.
## Quest values: lisbet = carrying / delivered / done; lisbet_tail = spotted / lost / caught /
## followed; lisbet_seal = whole / read / broken; lisbet_pay; lisbet_fee; lisbet_nudge.

const PAY := 5
const HAGGLED_PAY := 7
const FEE_GOOD := 20
const FEE_BAD := 40
const PURSE := 400


static func _host() -> String:
	return LehanQuests.host_key()


static func _say(t: String) -> Dictionary:
	return {"s": _host(), "t": t}


## Talking to Lisbet in the square.
static func talk() -> Array:
	match LehanQuests.get_q("lisbet"):
		"":
			return _offer()
		"carrying":
			return [{"s": "lisbet", "t": "Rudd's at the south gate, down the gate road. Go on. The letter won't walk there by itself."}]
		"delivered":
			return _return()
	return []


static func _offer() -> Array:
	var h := LehanQuests.host_first()
	var take := func(pay: int) -> Array:
		return [{"fx": "q:lisbet=carrying", "wait": 0.1}, {"fx": "q:lisbet_pay=%d" % pay, "wait": 0.1},
			{"n": "(Carry the letter to Sergeant Rudd at the south gate, down the gate road. Lisbet pays %d silver.)" % pay}]
	var opts: Array = []
	opts.append({"t": "Five silver for a walk? Done.", "say": _host(),
		"after": [{"s": "lisbet", "t": "Off you go. And don't dawdle by the well. Odo talks enough for two."}] + take.call(PAY)})
	var curious := LehanQuests.host_trait(["Curious"])
	opts.append({"t": "What's in it?", "say": _host(), "tags": [curious] if curious != "" else [],
		"after": [{"s": "lisbet", "t": "Words. Expensive ones. That's why it's sealed, and that's why I'm paying you and not reading it out by the well."}] + take.call(PAY)})
	var greedy := LehanQuests.host_trait(["Greedy"])
	if greedy != "":
		var won := Game.check(LehanQuests.host_char(), "talk", Game.NORMAL)
		var after: Array = [{"s": "lisbet", "t": "Seven. And you're a bandit, %s." % h}, {"fx": "xp:%s" % LehanQuests.CHECK_XP, "wait": 0.1}] + take.call(HAGGLED_PAY) if won \
			else [{"s": "lisbet", "t": "Five, or I find a cheaper pair of legs. Lehan is full of legs."}] + take.call(PAY)
		opts.append({"t": "For a sealed letter? Ten.", "say": _host(), "tags": [greedy],
			"ok": won, "checks": [LehanQuests.chk(LehanQuests.host_char(), "talk", Game.NORMAL)], "after": after})
	opts.append({"t": "Not now.", "say": _host(),
		"after": [{"s": "lisbet", "t": "Suit yourself. The letter can wait. I can't, but the letter can."}]})
	return [
		{"s": "lisbet", "t": "New face. Or an old face that's been on the road. Looking for work, or for gossip?"},
		_say("Depends what it pays."),
		{"s": "lisbet", "t": "Work, then. I have a letter that wants carrying to Sergeant Rudd at the south gate. Down the gate road, you can't miss him. He's the one leaning."},
		{"s": "lisbet", "t": "Two rules. Nobody follows you. Nobody opens it. Five silver when Rudd tells me it came clean."},
		{"i": "Light paper. But the spirit feels its host weigh it, and it weighs more than paper should."},
	] + LehanQuests.errand_comment() + [
		{"choice": "lisbet", "options": opts},
	]


# ---------------------------------------------------------------- the gate road

## True when walking onto the gate road with the letter, the first time.
static func tail_due(cell: Vector2i) -> bool:
	return LehanQuests.get_q("lisbet") == "carrying" and LehanQuests.get_q("lisbet_tail") == "" and cell.x == 11 \
		and cell.y >= 12 and cell.y <= 14


static func tail_scene() -> Array:
	var host := _host()
	var me := LehanQuests.host_char()
	var opts: Array = []
	var seen := Game.check(me, "perception", Game.NORMAL)
	opts.append({"t": "Turn round and look properly.", "ok": seen, "checks": [LehanQuests.chk(me, "perception", Game.NORMAL)], "silent": true,
		"after": _tail_look(seen, false)})
	var hid := Game.check(me, "stealth", Game.NORMAL)
	opts.append({"t": "Duck into a doorway and let them pass.", "ok": hid, "checks": [LehanQuests.chk(me, "stealth", Game.NORMAL)], "silent": true,
		"after": [{"n": "A boy in a cap too big for him hurries past the doorway, looking left and right... and loses the trail. He kicks a stone and slouches back towards the square."},
			{"fx": "q:lisbet_tail=lost", "wait": 0.1}, {"fx": "xp:%s" % LehanQuests.CHECK_XP, "wait": 0.1}] if hid \
			else [{"n": "A boy in a cap too big for him stops right in front of the doorway, and grins."},
				{"n": "\"Nice try.\""}, {"n": "He falls back again, a careful dozen steps behind."},
				{"fx": "q:lisbet_tail=followed", "wait": 0.1}]})
	var called := Game.check(me, "talk", Game.NORMAL)
	opts.append({"t": "Sergeant! This lad's been dogging me since the square!", "say": host, "ok": called, "checks": [LehanQuests.chk(me, "talk", Game.NORMAL)],
		"after": [{"n": "The sergeant at the gate pushes off the wall and collars a boy in a big cap. The boy twists free, quick as an eel, and runs back the way he came."},
			{"fx": "q:lisbet_tail=caught", "wait": 0.1}, {"fx": "xp:%s" % LehanQuests.CHECK_XP, "wait": 0.1}] if called \
			else [{"n": "The sergeant looks over, shrugs, and goes back to picking his teeth. The footsteps keep their distance."},
				{"fx": "q:lisbet_tail=followed", "wait": 0.1}]})
	if LehanQuests.can_nudge("lisbet"):
		var sharp := Game.check(me, "perception", Game.NORMAL, 4)
		opts.append({"t": "Let the spirit listen for the footsteps.", "tags": ["Spirit"], "silent": true,
			"ok": sharp, "checks": [LehanQuests.chk(me, "perception", Game.NORMAL, 4, "the spirit's help")], "tip": "The spirit can help once on this quest.",
			"after": [{"fx": "q:lisbet_nudge=used", "wait": 0.1}, LehanQuests.nudge_line()] + _tail_look(sharp, true)})
	opts.append({"t": "Ignore it and walk on.", "silent": true,
		"after": [{"n": "The footsteps follow, all the way down the gate road."}, {"fx": "q:lisbet_tail=followed", "wait": 0.1}]})
	return [
		{"n": "Halfway down the gate road, the host's ears catch it: footsteps behind, that stop when theirs stop."},
		{"i": "Someone's following. Lisbet said nobody should."},
		{"choice": "tail", "options": opts, "prompt": "What do you do? (1-%d)" % opts.size()},
	]


static func _tail_look(seen: bool, helped: bool) -> Array:
	if seen:
		return [{"n": "A boy in a cap too big for him, pretending to study a doorway. When he sees he's been spotted, he goes red to the ears."},
			_say("Run along. And tell whoever sent you that I saw you."),
			{"n": "The boy runs, back towards the square."},
			{"fx": "q:lisbet_tail=spotted", "wait": 0.1}] + ([] if helped else [{"fx": "xp:%s" % LehanQuests.CHECK_XP, "wait": 0.1}])
	return [{"n": "Carts, a woman with a basket, a dog asleep in a doorway. Nobody, it seems. The footsteps start again as soon as you walk on."},
		{"fx": "q:lisbet_tail=followed", "wait": 0.1}]


# ---------------------------------------------------------------- Sergeant Rudd

## Talking to the sergeant with the letter: open it or not, then hand it over.
static func deliver() -> Array:
	var me := LehanQuests.host_char()
	var opts: Array = []
	opts.append({"t": "Hand it over as it is.", "silent": true, "after": [{"fx": "q:lisbet_seal=whole", "wait": 0.1}] + _rudd("whole")})
	var nosy := LehanQuests.host_trait(["Curious", "Deceitful", "Greedy"])
	var ok := Game.check(me, "thievery", Game.NORMAL)
	opts.append({"t": "Open it first. Carefully.", "tags": [nosy] if nosy != "" else [], "ok": ok, "checks": [LehanQuests.chk(me, "thievery", Game.NORMAL)], "tip": "To lift the seal and put it back unseen.",
		"silent": true, "after": _open(ok, false)})
	if LehanQuests.can_nudge("lisbet"):
		var steady := Game.check(me, "thievery", Game.NORMAL, 4)
		opts.append({"t": "Open it, and let the spirit steady your fingers.", "tags": ["Spirit"], "silent": true,
			"ok": steady, "checks": [LehanQuests.chk(me, "thievery", Game.NORMAL, 4, "the spirit's help")], "tip": "The spirit can help once on this quest.",
			"after": [{"fx": "q:lisbet_nudge=used", "wait": 0.1}, LehanQuests.nudge_line()] + _open(steady, true)})
	return [
		{"n": "The sergeant is a few steps away, leaning on the gatepost. The letter is in your hand, the plain red seal under your thumb."},
		{"choice": "seal", "options": opts, "prompt": "Choose (1-%d)" % opts.size()},
	]


static func _open(ok: bool, helped: bool) -> Array:
	var out: Array = []
	if ok:
		out.append({"n": "A warm thumbnail under the wax, a slow lift. The seal comes away whole."})
	else:
		out.append({"n": "The wax cracks in two with a small, terrible snap. No hiding that."})
	out.append({"n": "In a clerk's tidy hand: \"L. The council's purse for the miners is %d silver. They mean to offer the first fools a hundred and fifty and haggle up from there. P.\"" % PURSE})
	out.append({"i": "Four hundred. Worth knowing."})
	out.append({"fx": "purse", "wait": 0.1})
	if ok:
		out.append({"n": "The wax goes back where it was. Nobody would know."})
		out.append({"fx": "q:lisbet_seal=read", "wait": 0.1})
		if not helped:
			out.append({"fx": "xp:%s" % LehanQuests.CHECK_XP, "wait": 0.1})
		out.append_array(_rudd("read"))
	else:
		out.append({"fx": "q:lisbet_seal=broken", "wait": 0.1})
		out.append_array(_rudd("broken"))
	return out


static func _rudd(seal: String) -> Array:
	var out: Array = [{"s": "guard", "t": "From Lisbet? Let's have it, then."},
		{"n": "He turns the letter over in thick fingers and looks at the seal for a long moment."}]
	if seal == "broken":
		out.append({"s": "guard", "t": "Seal's broken. She won't like that."})
	else:
		out.append({"s": "guard", "t": "Seal's whole. Good."})
	if LehanQuests.get_q("lisbet_tail") == "followed":
		out.append({"s": "guard", "t": "And you brought company. Pip! Out you come."})
		out.append({"n": "The boy in the big cap steps out from behind a water butt, grinning from ear to ear."})
	else:
		out.append({"s": "guard", "t": "No Pip behind you? Then you shook him off. Not many do."})
	out.append({"s": "guard", "t": "It's a test, friend. Lisbet tests anyone she might work with. Go back and tell her. Mind, she'll know already. She always does."})
	out.append({"fx": "q:lisbet=delivered", "wait": 0.1})
	out.append({"n": "(Go back to Lisbet in the market square.)"})
	return out


# ---------------------------------------------------------------- back to Lisbet

static func _return() -> Array:
	var h := LehanQuests.host_first()
	var seal := LehanQuests.get_q("lisbet_seal")
	var tailed := LehanQuests.get_q("lisbet_tail") == "followed"
	var pay := int(LehanQuests.get_q("lisbet_pay", str(PAY)))
	var out: Array = [{"s": "lisbet", "t": "Rudd sent word. Faster than you walk, %s." % h}]
	if tailed:
		out.append({"s": "lisbet", "t": "Pip walked behind you the whole way. Close enough to pick your pocket. Didn't, though. Family rule."})
	match seal:
		"whole":
			if not tailed:
				out.append({"s": "lisbet", "t": "Not followed, not opened. You'll do."})
			else:
				out.append({"s": "lisbet", "t": "But you didn't open it. That counts for something."})
			out.append_array(_ending(pay, not tailed))
		"broken":
			out.append({"s": "lisbet", "t": "Clumsy fingers. But you came back, and you didn't sell what you read to anyone. That's more than most."})
			out.append_array(_ending(pay, false))
		"read":
			var lied := Game.check(LehanQuests.host_char(), "talk", 10)
			var liar := LehanQuests.host_trait(["Deceitful", "Greedy", "Proud"])
			out.append({"s": "lisbet", "t": "Rudd says the seal was whole. So. Did you read it?"})
			out.append({"choice": "lisbet_read", "options": [
				{"t": "I did. Four hundred.", "say": _host(), "tags": ["Honest"] if LehanQuests.host_has("Honest") else [],
					"after": [{"n": "Lisbet laughs, a real one."}, {"s": "lisbet", "t": "Honest and nosy. I can work with that."}] + _ending(pay, true)},
				{"t": "Of course not.", "say": _host(), "tags": [liar] if liar != "" else [], "ok": lied, "checks": [LehanQuests.chk(LehanQuests.host_char(), "talk", 10)], "tip": "She lies for a living.",
					"after": ([{"s": "lisbet", "t": "...Good. I believe you. Mostly."}, {"fx": "xp:%s" % LehanQuests.CHECK_XP, "wait": 0.1}] + _ending(pay, true)) if lied \
						else ([{"s": "lisbet", "t": "Liar. A good one, almost. I like that less than you'd think."}] + _ending(pay, false))},
			]})
	return out


## Payment, the purse, the fee and the crier.
static func _ending(pay: int, good: bool) -> Array:
	var fee := FEE_GOOD if good else FEE_BAD
	var out: Array = [{"n": "She counts %d silver into your palm." % pay}, {"fx": "silver:%d" % pay, "wait": 0.1}]
	if not Game.story.get("council_purse", false):
		out.append({"s": "lisbet", "t": "And since you carried it, here's what it said. Free. The council has %d silver set aside for those miners. Don't take their first offer." % PURSE})
		out.append({"fx": "purse", "wait": 0.1})
	out.append({"s": "lisbet", "t": "If you ever want someone who can open a lock, or a mouth, I'm at the inn most nights. For a fee, of course. Everything in Lehan costs something."})
	out.append({"fx": "q:lisbet_fee=%d" % fee, "wait": 0.1})
	out.append({"fx": "q:lisbet=done", "wait": 0.1})
	out.append({"fx": "recruit:lisbet", "wait": 0.1})
	out.append({"n": "(Lisbet Farrow is now on the inn's list. Mustering her costs %d silver.)" % fee})
	out.append_array(LehanQuests.finish_xp_steps("lisbet"))
	out.append_array(LehanQuests.quest_finished_steps())
	return out
