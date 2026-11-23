class_name BoddoQuest
extends RefCounted
## Boddo's debt of honour, a Lehan quest (see LehanQuests and IDEAS.md). Tam Reed, a porter, once
## pulled Boddo out of the river. Tam died this spring, and Master Gell, the warehouse master,
## struck his last fourteen weeks' wages from the book. Boddo swore Tam's widow Hanna would be
## paid, but nobody listens to a Thuug accusing a human merchant.
##
## First the proof: the wage book in Gell's warehouse (talk your way to a look and spot the lie,
## lift the book, or come back after dark). Then Gell himself: shame him in front of his porters
## or lean on him. Or skip all that and pay Hanna yourself.
##
## Quest values: boddo = proof / found / failed / paid / self / done; boddo_tried_<way>;
## boddo_wary (Gell is on guard); boddo_nudge.

const OWED := 40      # what Tam was owed, if the host pays it
const CHECK := 9       # Game.NORMAL
const TRY_AGAIN := {"n": "(That didn't work. Go into the warehouse again to try another way.)"}


static func _host() -> String:
	return LehanQuests.host_key()


static func _say(t: String) -> Dictionary:
	return {"s": _host(), "t": t}


static func _fx(f: String) -> Dictionary:
	return {"fx": f, "wait": 0.1}


static func _tried(way: String) -> bool:
	return LehanQuests.get_q("boddo_tried_" + way) != ""


# ---------------------------------------------------------------- Boddo in the square

static func talk() -> Array:
	match LehanQuests.get_q("boddo"):
		"":
			return _offer()
		"proof", "found", "failed":
			return _waiting()
		"paid", "self":
			return _return(LehanQuests.get_q("boddo") == "self")
	return []


static func _offer() -> Array:
	var out: Array = [
		{"s": "boddo", "t": "Hm."},
		_say("That's a heavy load, even for a Thuug."),
		{"s": "boddo", "t": "Not as heavy as a debt. A Thuug pays what he owes. Boddo cannot. Not alone."},
		{"s": "boddo", "t": "Tam Reed pulled Boddo out of the river, two winters back. The spring flood had Boddo under a drifting barge. A Thuug can hold his breath a long time, but not for ever. Tam did not let go."},
		{"s": "boddo", "t": "Tam died in the spring. Fever. Master Gell, at the warehouse, says Tam was paid to the end. He was not. Fourteen weeks. Forty silver. His widow Hanna sells her pots to eat."},
		{"s": "boddo", "t": "Boddo went to Gell. Gell laughed. Boddo went to the watch. The watch laughed. A Thuug's word against a merchant's book."},
		{"i": "He doesn't raise his voice. He doesn't need to. That is the anger of someone who has waited a long time, and will wait longer."},
	]
	out.append_array(LehanQuests.errand_comment())
	var opts: Array = []
	opts.append({"t": "Then we'll find the book that proves it.", "say": _host(),
		"after": [{"s": "boddo", "t": "The book is in Gell's warehouse. Where the smith's street meets the square. Big doors, a barrel on the sign."},
			{"s": "boddo", "t": "Boddo cannot go in. Gell's men know Boddo's shell."},
			_fx("q:boddo=proof"), _fx("place:warehouse"),
			{"n": "(Find proof in Gell's Warehouse, now on the town map: where the smith's street meets the square.)"}]})
	var kind := LehanQuests.host_trait(["Generous", "Pious", "Honest"])
	opts.append(_pay_option(kind))
	opts.append({"t": "Not my debt.", "say": _host(),
		"after": [{"s": "boddo", "t": "No. It is Boddo's. Boddo will be here. Boddo is always here."}]})
	out.append({"choice": "boddo", "options": opts})
	return out


static func _pay_option(tag: String) -> Dictionary:
	var can := Game.party_silver() >= OWED
	var after: Array
	if can:
		after = [_fx("pay:%d" % OWED), _fx("q:boddo=self"), _fx("q:boddo_way=self"),
			{"n": "You count out %d silver. Boddo looks at the coins for a long moment, then closes his big hand around them." % OWED},
			{"s": "boddo", "t": "Boddo will take it to Hanna. Today."}] + _return(true)
	else:
		after = [{"n": "You count your silver. It does not come to %d." % OWED},
			{"s": "boddo", "t": "Kind. But a purse cannot pay what it does not have."}]
	return {"t": "Forty silver? I'll pay it myself. (%d silver)" % OWED, "say": _host(),
		"tags": [tag] if tag != "" else [], "tip": "Pay Hanna from your own purse",
		"after": after}


static func _waiting() -> Array:
	var st := LehanQuests.get_q("boddo")
	var line := "Gell's book. In the warehouse, where the smith's street meets the square." if st == "proof" \
		else ("You have the book. Now make Gell pay." if st == "found"
			else "Gell has burned the page. Boddo saw the smoke. There is no proof now. Only silver.")
	var opts: Array = [{"t": "Not yet.", "say": _host(), "after": [{"s": "boddo", "t": "Hm."}]}]
	opts.push_front(_pay_option(LehanQuests.host_trait(["Generous", "Pious", "Honest"])))
	return [{"s": "boddo", "t": line}, {"choice": "boddo_wait", "options": opts}]


static func _return(self_paid: bool) -> Array:
	var out: Array = []
	if self_paid:
		out.append({"s": "boddo", "t": "Hanna wept. She thought it came from Gell, at last. Boddo did not tell her otherwise."})
		out.append({"s": "boddo", "t": "Your silver paid Boddo's debt. That makes Boddo's debt yours. Gell still sleeps soundly, but Boddo will not forget who paid."})
	else:
		out.append({"s": "boddo", "t": "Gell's own clerk came to Hanna's door with forty silver in a bag. Gell's porters were watching. The whole street knows."})
		out.append({"s": "boddo", "t": "Tam is paid. Boddo's debt is paid. And Gell will remember Boddo's shell now. Good."})
	out.append({"s": "boddo", "t": "Boddo carries. Boxes, barrels, friends who fall. Boddo will carry for you. At the inn, when you want him."})
	out.append(_fx("q:boddo=done"))
	out.append(_fx("recruit:boddo"))
	out.append({"n": "(Boddo is now on the inn's list. He asks no fee.)"})
	out.append_array(LehanQuests.finish_xp_steps("boddo"))
	out.append_array(LehanQuests.quest_finished_steps())
	return out


# ---------------------------------------------------------------- Gell's warehouse

## Going in at the warehouse door.
static func warehouse() -> Array:
	match LehanQuests.get_q("boddo"):
		"proof":
			return _look_for_proof()
		"found":
			return [{"n": "Gell's warehouse. Master Gell himself is at the desk today, a heavy man with rings on every finger."}] + _confront()
		"failed":
			return [{"n": "Gell sees you at the door and smiles. \"Lost something?\" A porter shuts the door in your face."}]
		"":
			return [{"n": "Sacks, barrels and the smell of tar. A clerk looks up from a high desk."},
				{"n": "\"Buying or selling? Neither? Then out. This is a place of business.\""}]
	return [{"n": "Gell's warehouse. The porters glance at you and go back to their work, a little more carefully than before."}]


static func _look_for_proof() -> Array:
	var out: Array = [{"n": "Sacks, barrels and the smell of tar. A clerk with ink to his elbows sits at a high desk. Beside him lies a fat ledger: the wage book."}]
	out.append_array(LehanQuests.errand_comment())
	var opts: Array = []
	var talker := LehanQuests.best("talk")
	var eye := LehanQuests.best("perception")
	var thief := LehanQuests.best("thievery")
	var sneak := LehanQuests.best("stealth")
	if not _tried("talk"):
		var got_look := Game.check(talker, "talk", Game.EASY)
		var scholar := LehanQuests.best("lore")
		var spotted := Game.check(eye, "perception", CHECK) or Game.check(scholar, "lore", CHECK)
		var after: Array = [_fx("q:boddo_tried_talk=1")]
		if not got_look:
			after.append({"n": "The clerk looks %s up and down, and sniffs. \"Gell deals with merchants, not with whatever you are.\"" % _first(talker)})
			after.append(TRY_AGAIN)
		elif spotted:
			after.append({"n": "The clerk turns the ledger round, proud of his neat columns. %s reads down the porters' wages..." % _first(eye)})
			after.append(_fx("xp:%s" % LehanQuests.CHECK_XP))
			after.append_array(_found(false))
		else:
			after.append({"n": "The clerk turns the ledger round. Columns of names and figures. If there's a lie in them, it hides well."})
			after.append(TRY_AGAIN)
		opts.append(_spoken(talker, {"t": "We're looking to store goods. Can we see what you keep, and what it costs?",
			"ok": got_look and spotted, "checks": [LehanQuests.chk(talker, "talk", Game.EASY), LehanQuests.chk(eye, "perception", CHECK),
				LehanQuests.chk(scholar, "lore", CHECK).merged({"or": true})],
			"tip": "Talk gets a look at the ledger; Perception or Lore spots the lie in it.", "after": after}))
	if not _tried("lift"):
		var ok := Game.check(thief, "thievery", CHECK)
		var after: Array = [_fx("q:boddo_tried_lift=1")]
		if ok:
			after.append({"n": "A cart backs into the door with a crash. While the clerk shouts at the carter, the wage book goes under %s's coat." % _first(thief)})
			after.append(_fx("xp:%s" % LehanQuests.CHECK_XP))
			after.append_array(_found(true))
		else:
			after.append({"n": "%s's hand is on the ledger when the clerk turns round. \"Thief! Out! Out!\" Two porters see you to the street." % _first(thief)})
			after.append(_fx("q:boddo_wary=1"))
			after.append(TRY_AGAIN)
		opts.append({"t": "Wait for the clerk to look away, and lift the wage book.", "silent": true,
			"ok": ok, "checks": [LehanQuests.chk(thief, "thievery", CHECK)], "tip": "If it fails, Gell's men are wary of you.", "after": after})
	if not _tried("night"):
		var ok := Game.check(sneak, "stealth", CHECK)
		var after: Array = [_fx("q:boddo_tried_night=1")]
		if ok:
			after.append({"n": "After dark, the loading door gives to a shoulder. Inside, a watchman snores on a sack of grain. The wage book is where the clerk left it."})
			after.append(_fx("xp:%s" % LehanQuests.CHECK_XP))
			after.append_array(_found(true))
		else:
			after.append({"n": "After dark, the loading door creaks. The watchman isn't asleep. He's big, and he has a cudgel."})
			var fight := _scuffle()
			after.append_array(fight.steps)
			if fight.won:
				after.append({"n": "The watchman sits down hard among the sacks. Nobody stops you taking the wage book."})
				after.append(_fx("q:boddo_wary=1"))
				after.append_array(_found(true))
			else:
				after.append(TRY_AGAIN)
		opts.append({"t": "Come back after dark, and in through the loading door.", "silent": true,
			"ok": ok, "checks": [LehanQuests.chk(sneak, "stealth", CHECK)],
			"tip": "If it fails: a scuffle with the watchman (Combat, helped by the rest of the party).", "after": after})
	if LehanQuests.can_nudge("boddo") and not _tried("spirit"):
		var ok := Game.check(eye, "perception", CHECK, 4)
		var after: Array = [_fx("q:boddo_tried_spirit=1"), _fx("q:boddo_nudge=used"), LehanQuests.nudge_line()]
		if ok:
			after.append({"n": "Across the room, upside down, one line in the wage book seems to stand out from the rest, as if someone had underlined it."})
			after.append_array(_found(false))
		else:
			after.append({"n": "The figures swim, and settle, and say nothing. Whatever the spirit is looking for, it isn't on this page."})
			after.append(TRY_AGAIN)
		opts.append({"t": "Let the spirit look at the ledger with you.", "tags": ["Spirit"], "silent": true,
			"ok": ok, "checks": [LehanQuests.chk(eye, "perception", CHECK, 4, "the spirit's help")],
			"tip": "The spirit can help once on this quest.", "after": after})
	opts.append({"t": "Leave for now.", "silent": true, "after": []})
	out.append({"choice": "proof", "options": opts, "prompt": "Choose (1-%d)" % opts.size()})
	return out


## The proof, read out; then Gell (at once, or on another visit if the book was taken).
static func _found(taken: bool) -> Array:
	var out: Array = [
		{"n": "There it is. \"Tam Reed, porter: fourteen weeks.\" A line through it, and in another ink: \"Died. No claim.\" Below, the same sum, paid to \"O. G.\""},
		{"i": "Forty silver for a dead man's widow, into a rich man's pocket. The host's jaw tightens. So does something underneath it."},
		_fx("q:boddo=found"),
	]
	if taken:
		out.append(_fx("q:boddo_page=1"))
		out.append({"n": "(You have Tam's page from the wage book. Go back into the warehouse to face Master Gell with it.)"})
	else:
		out.append({"n": "Heavy footsteps on the stairs. Master Gell comes down to see who's reading his books: a heavy man with rings on every finger."})
		out.append_array(_confront())
	return out


## Facing Gell with the proof. Each way can be tried once; if both fail, he burns the page.
static func _confront() -> Array:
	var wary := LehanQuests.get_q("boddo_wary") != ""
	var bonus := -1 if wary else 0
	var opts: Array = []
	var both_tried := _tried("shame") and _tried("lean")
	if both_tried:
		return [{"n": "Gell won't see you."}]
	var talker := LehanQuests.best("talk")
	if not _tried("shame"):
		var ok := Game.check(talker, "talk", CHECK, bonus + 1)   # the porters are on Tam's side
		var after: Array = [_fx("q:boddo_tried_shame=1")]
		if ok:
			after.append({"n": "%s reads Tam's line out loud. The porters stop working. One by one, they turn to look at Gell." % _first(talker)})
			after.append({"n": "\"A mistake,\" says Gell, too loudly. \"A clerk's mistake. The widow will be paid. Today.\""})
			after.append(_fx("q:boddo=paid"))
			after.append(_fx("xp:%s" % LehanQuests.CHECK_XP))
			after.append({"n": "(Go back to Boddo in the market square.)"})
		else:
			after.append({"n": "%s reads Tam's line out loud. Gell laughs. \"Porters can't read, friend. And they know who pays them.\" The porters look at their feet." % _first(talker)})
			after.append(_fx("q:boddo_wary=1"))
			after.append_array(_after_failed_confront("shame"))
		opts.append(_spoken(talker, {"t": "Read it out, so every porter in here can hear what you did to Tam.",
			"ok": ok, "checks": [LehanQuests.chk(talker, "talk", CHECK, bonus + 1, _why(["the porters are on Tam's side +1", "Gell is wary -1" if wary else ""]))],
			"after": after}))
	if not _tried("lean"):
		var tag := LehanQuests.host_trait(["Proud", "Hot-tempered", "Brave", "Vengeful", "Greedy"])
		var heavy := LehanQuests.best("combat")
		var ok := Game.check(heavy, "combat", CHECK, bonus + (1 if tag != "" else 0))
		var after: Array = [_fx("q:boddo_tried_lean=1")]
		if ok:
			after.append({"n": "%s leans over the desk until Gell has to lean back. Nobody says anything for a while." % _first(heavy)})
			after.append({"n": "\"Fine,\" Gell says at last. \"Forty. To the widow. And then I never see you again.\""})
			after.append(_fx("q:boddo=paid"))
			after.append(_fx("xp:%s" % LehanQuests.CHECK_XP))
			after.append({"n": "(Go back to Boddo in the market square.)"})
		else:
			after.append({"n": "Gell snaps his fingers. Two of his biggest porters step up behind you."})
			var fight := _scuffle()
			after.append_array(fight.steps)
			if fight.won:
				after.append({"n": "Gell looks at his porters, groaning among the barrels, and goes pale. \"All right! Forty, to the widow. Just go.\""})
				after.append(_fx("q:boddo=paid"))
				after.append({"n": "(Go back to Boddo in the market square.)"})
			else:
				after.append_array(_after_failed_confront("lean"))
		opts.append({"t": "Pay her, or the next time you lean on a porter, someone leans back.", "say": _host(),
			"tags": [tag] if tag != "" else [],
			"ok": ok, "checks": [LehanQuests.chk(heavy, "combat", CHECK, bonus + (1 if tag != "" else 0), _why([tag + " +1" if tag != "" else "", "Gell is wary -1" if wary else ""]))],
			"tip": "Looking dangerous. If it fails: a scuffle with his porters.", "after": after})
	opts.append({"t": "Leave, and think about it.", "silent": true, "after": []})
	return [{"choice": "gell", "options": opts, "prompt": "Choose (1-%d)" % opts.size()}]


static func _after_failed_confront(way: String) -> Array:
	var other := "lean" if way == "shame" else "shame"
	if _tried(other):
		return [{"n": "Gell takes the page and holds it to a candle. \"What proof?\" The ash drifts to the floor."},
			_fx("q:boddo=failed"),
			{"n": "(The proof is gone. Boddo's debt can still be paid in silver: talk to Boddo.)"}]
	return [{"n": "(Gell won't budge this way. There is still the other way, if you come back.)"}]


## A scuffle (a last resort): the best fighter and the party's numbers against Gell's men.
## Losing costs everyone some hits, but nobody is killed. Returns {won, steps}.
static func _scuffle() -> Dictionary:
	var fighter := LehanQuests.best("combat")
	var helpers := mini(Game.party.size() - 1, 2)
	if Game.check(fighter, "combat", CHECK, helpers):
		return {"won": true, "steps": [{"n": "A short, ugly scuffle among the barrels. %s ends it, and Gell's men decide they are not paid enough for this." % _first(fighter)},
			_fx("xp:%s" % LehanQuests.CHECK_XP)]}
	return {"won": false, "steps": [{"n": "A short, ugly scuffle among the barrels, and you lose it. You end up in the gutter, bruised, with your ears ringing."},
		_fx("hurt:3"), _fx("q:boddo_wary=1")]}


## Where a bonus comes from, for the check's tooltip.
static func _why(parts: Array) -> String:
	return ", ".join(parts.filter(func(p): return p != ""))


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


## An option spoken by a party member (by the host if they are not one of the cast).
static func _spoken(c: Dictionary, o: Dictionary) -> Dictionary:
	var k := LehanQuests.key_of(c)
	o["say"] = k if k != "" else _host()
	o["portrait"] = o.say
	return o
