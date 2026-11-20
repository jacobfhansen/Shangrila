class_name SkeeQuest
extends RefCounted
## Skee's lights, a Lehan quest (see LehanQuests and IDEAS.md). Skee, a Nisk rat-catcher, saw blue
## lights in the old tunnels under the town, dropped his bag and ran. Someone should look.
##
## The way down is under the tannery on Tanners' Row (pick the grate, talk the tanner round, find
## the loose drain, or pay her). Below (LehanTunnels, walked in 3D): a rat nest, a collapse, Skee's
## bag, and the chamber of the lights: the shattered remains of an old figure, maybe crowned like
## the shrine's stone head, a few shards still glowing. Then Skee has to be persuaded that it isn't
## ghosts; what was found down there helps.
##
## Quest values: skee = going / seen / done; skee_way (the way down is open); skee_tried_<way>;
## skee_rats, skee_collapse, skee_bag; skee_lore, skee_ward, skee_touched; skee_ask_<way>.

const TANNER_FEE := 5


static func _host() -> String:
	return LehanQuests.host_key()


static func _say(t: String) -> Dictionary:
	return {"s": _host(), "t": t}


static func _fx(f: String) -> Dictionary:
	return {"fx": f, "wait": 0.1}


static func _q(k: String) -> String:
	return LehanQuests.get_q(k)


## Where a check's bonus comes from, for its tooltip.
static func _why(parts: Array) -> String:
	return ", ".join(parts.filter(func(p): return p != ""))


static func _learned_why(bonus: int) -> String:
	return "learned from failed tries +%d" % bonus if bonus > 0 else ""


static func _helped_why(helpers: int, bonus: int) -> String:
	return _why(["helped by the rest of the party +%d" % helpers if helpers > 0 else "", _learned_why(bonus)])


static func _first(c: Dictionary) -> String:
	return c.name.split(" ")[0]


static func collapse_passed() -> bool:
	return _q("skee_collapse") != ""


static func bag_taken() -> bool:
	return _q("skee_bag") != ""


static func rats_done() -> bool:
	return _q("skee_rats") != ""


static func way_open() -> bool:
	return _q("skee_way") != ""


# ---------------------------------------------------------------- Skee in the square

static func talk() -> Array:
	match _q("skee"):
		"":
			return _offer()
		"going":
			return [{"s": "skee", "t": "The tannery, on Tanners' Row. The old cellar steps. Mind the rats. Skee did not."}]
		"seen":
			return _persuade()
	return []


static func _offer() -> Array:
	var out: Array = [
		{"s": "skee", "t": "Rats, rats, rats. One silver for a dozen tails, and the council pays late."},
		{"s": "skee", "t": "Not the rats that worry Skee. Lights, down in the old tunnels under the town. Blue ones. Where no lamp should be."},
		{"i": "Old tunnels under the town. The spirit remembers the streets that felt laid over older ones."},
		{"s": "skee", "t": "Skee went down by the tannery on Tanners' Row. Saw the lights. Dropped Skee's bag and ran. Skee is not proud of it."},
		{"s": "skee", "t": "Someone should look. Someone who is not Skee."},
	]
	out.append_array(LehanQuests.errand_comment())
	var go: Array = [_fx("q:skee=going"), _fx("place:tannery"),
		{"s": "skee", "t": "The tanner keeps a grate over the old cellar steps. She does not like visitors. Skee does not like her."},
		{"n": "(Find a way down under the tannery on Tanners' Row, now on the town map.)"}]
	var opts: Array = [{"t": "I'll go and look.", "say": _host(), "after": go}]
	var curious := LehanQuests.host_trait(["Curious"])
	if curious != "":
		opts.append({"t": "Blue lights where no lamp should be? Now I have to see.", "say": _host(), "tags": [curious], "after": go})
	opts.append({"t": "Not my business.", "say": _host(),
		"after": [{"s": "skee", "t": "No. Nobody's business. That is how things stay, down there."}]})
	out.append({"choice": "skee", "options": opts})
	return out


# ---------------------------------------------------------------- the tannery

## Going in at the tannery door: find a way down (one try per visit), or straight down if found.
static func tannery() -> Array:
	if _q("skee") == "":
		return [{"n": "The tannery stinks of lime and worse. The tanner, arms stained brown to the elbow, looks at you until you leave."}]
	if way_open():
		return [{"n": "The tanner jerks her head at the cellar steps without a word. Cold air breathes up from below."}]
	var out: Array = [{"n": "The tannery stinks of lime and worse. In the yard an iron grate covers old cellar steps. The tanner, arms stained brown to the elbow, watches you."}]
	var opts: Array = []
	var down: Array = [_fx("q:skee_way=1"), {"n": "Stone steps, worn hollow, lead down into the dark."}]
	if _q("skee_tried_pick") == "":
		var thief := LehanQuests.best("thievery")
		var ok := Game.check(thief, "thievery", Game.NORMAL)
		opts.append({"t": "Pick the grate's lock while she's busy with the vats.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(thief, "thievery", Game.NORMAL)],
			"after": [_fx("q:skee_tried_pick=1")] + ([{"n": "A twist, a click. %s eases the grate up without a sound." % _first(thief)}, _fx("xp:%s" % LehanQuests.CHECK_XP)] + down if ok
				else [{"n": "The lock is rusted solid. The tanner turns round and folds her arms."}, _try_again()])})
	if _q("skee_tried_talk") == "":
		var talker := LehanQuests.best("talk")
		var ok := Game.check(talker, "talk", Game.NORMAL)
		var o := {"t": "A rat-catcher saw something in your cellar. Let us look, and we'll clear your rats on the way.",
			"ok": ok, "checks": [LehanQuests.chk(talker, "talk", Game.NORMAL)],
			"after": [_fx("q:skee_tried_talk=1")] + ([{"n": "\"Rats,\" says the tanner, and spits. \"Take all you like.\" She unlocks the grate."}, _fx("xp:%s" % LehanQuests.CHECK_XP)] + down if ok
				else [{"n": "\"Rat-catchers see things after a jug of ale,\" says the tanner. \"Out.\""}, _try_again()])}
		var k := LehanQuests.key_of(talker)
		o["say"] = k if k != "" else _host()
		o["portrait"] = o.say
		opts.append(o)
	if _q("skee_tried_look") == "":
		var eye := LehanQuests.best("perception")
		var ok := Game.check(eye, "perception", Game.NORMAL)
		opts.append({"t": "Look around the yard for another way down.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(eye, "perception", Game.NORMAL)],
			"after": [_fx("q:skee_tried_look=1")] + ([{"n": "Behind the lime pit, %s finds a drain cover that rocks under a boot. Below it, a crawl, and then the old steps." % _first(eye)}, _fx("xp:%s" % LehanQuests.CHECK_XP)] + down if ok
				else [{"n": "Vats, hides, a dog asleep on a pile of scraps. No other way down that you can see."}, _try_again()])})
	if LehanQuests.can_nudge("skee") and _q("skee_tried_spirit") == "":
		var ok := Game.check(LehanQuests.host_char(), "perception", Game.NORMAL, 4)
		opts.append({"t": "Let the spirit feel for where the cold air comes up.", "tags": ["Spirit"], "silent": true,
			"ok": ok, "checks": [LehanQuests.chk(LehanQuests.host_char(), "perception", Game.NORMAL, 4, "the spirit's help")],
			"tip": "The spirit can help once on this quest.",
			"after": [_fx("q:skee_tried_spirit=1"), _fx("q:skee_nudge=used"), LehanQuests.nudge_line()]
				+ ([{"n": "A thread of cold, from under a drain cover behind the lime pit. It lifts away. Below: a crawl, and then the old steps."}] + down if ok
					else [{"n": "Cold everywhere, and nowhere in particular. Whatever the spirit feels, it can't point to it."}, _try_again()])})
	var can_pay := Game.party_silver() >= TANNER_FEE
	opts.append({"t": "Here's %d silver for your trouble. Open the grate." % TANNER_FEE, "say": _host(),
		"tip": "Always works, if you have the silver",
		"after": [_fx("pay:%d" % TANNER_FEE), {"n": "The coins vanish into a brown fist. The grate opens."}] + down if can_pay
			else [{"n": "Your purse doesn't run to it."}]})
	opts.append({"t": "Leave for now.", "silent": true, "after": []})
	out.append({"choice": "tannery", "options": opts, "prompt": "Choose (1-%d)" % opts.size()})
	return out


## Each failed try at the rats or the collapse teaches you something: +1 on the next try.
static func _learned(obstacle: String) -> int:
	return int(_q("skee_%s_fails" % obstacle) if _q("skee_%s_fails" % obstacle) != "" else "0")


static func _failed(obstacle: String) -> Dictionary:
	return _fx("q:skee_%s_fails=%d" % [obstacle, _learned(obstacle) + 1])


static func _try_again() -> Dictionary:
	return {"n": "(That didn't work. Come back to the tannery to try another way.)"}


# ---------------------------------------------------------------- below the town

## The rats. If they are not dealt with, the screen steps the party back the way it came.
static func rats() -> Array:
	var out: Array = [{"n": "The floor ahead is moving. Rats: dozens of them, a heaving carpet around something long dead. Eyes catch the torchlight."}]
	var opts: Array = []
	var bonus := _learned("rats")
	if bonus > 0:
		out.append({"n": "(You've seen how this nest moves now: +%d on your next try.)" % bonus})
	var sneak := LehanQuests.best("stealth")
	var ok := Game.check(sneak, "stealth", Game.NORMAL, bonus)
	opts.append({"t": "Edge along the wall, slow and quiet.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(sneak, "stealth", Game.NORMAL, bonus, _learned_why(bonus))], "tip": "The best at it leads the way.",
		"after": [{"n": "Step by careful step along the wall. The rats squeal and shift, and let you by."}, _fx("q:skee_rats=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
			else [{"n": "A boot scrapes. The carpet of rats boils up your legs, biting. You stumble back the way you came."}, _fx("hurt:2"), _failed("rats")]})
	var woods := LehanQuests.best("survival")
	ok = Game.check(woods, "survival", Game.NORMAL, bonus)
	opts.append({"t": "Smoke them out with the torch and a handful of damp straw, the way rat-catchers do.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(woods, "survival", Game.NORMAL, bonus, _learned_why(bonus))],
		"after": [{"n": "Thick, stinking smoke rolls along the passage. The rats pour away into cracks in the walls."}, _fx("q:skee_rats=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
			else [{"n": "The straw won't catch, the smoke goes the wrong way, and you retreat coughing."}, _fx("hurt:1"), _failed("rats")]})
	var fighter := LehanQuests.best("combat")
	var helpers := mini(Game.party.size() - 1, 2)
	ok = Game.check(fighter, "combat", Game.NORMAL, helpers + bonus)
	opts.append({"t": "Wade in, stamping and swinging.", "silent": true,
		"ok": ok, "checks": [LehanQuests.chk(fighter, "combat", Game.NORMAL, helpers + bonus, _helped_why(helpers, bonus))], "tip": "Even if it works, the bites hurt.",
		"after": [{"n": "A short, disgusting fight. When it's over the rats have fled, and the passage is yours."}, _fx("q:skee_rats=1"), _fx("hurt:1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
			else [{"n": "There are too many. You back off, kicking, bleeding from a dozen small bites."}, _fx("hurt:3"), _failed("rats")]})
	if LehanQuests.can_nudge("skee"):
		ok = Game.check(sneak, "stealth", Game.NORMAL, 4 + bonus)
		opts.append({"t": "Let the spirit guide your feet.", "tags": ["Spirit"], "silent": true,
			"ok": ok, "checks": [LehanQuests.chk(sneak, "stealth", Game.NORMAL, 4 + bonus, _why(["the spirit's help +4", _learned_why(bonus)]))],
			"tip": "The spirit can help once on this quest.",
			"after": [_fx("q:skee_nudge=used"), LehanQuests.nudge_line()] + ([{"n": "Your feet find the quiet places. The rats never even turn their heads."}, _fx("q:skee_rats=1")] if ok
				else [{"n": "Even so, a rat squeals underfoot, and the whole nest wakes. You retreat."}, _fx("hurt:2")])})
	opts.append({"t": "Back away.", "silent": true, "after": [{"n": "You back away from the rats."}]})
	out.append({"choice": "rats", "options": opts, "prompt": "Choose (1-%d)" % opts.size()})
	return out


## The collapse: a way through, for some hits if it goes wrong. It can be tried again.
static func collapse() -> Array:
	var out: Array = [{"n": "The passage ends in a slope of fallen stone and rotten timbers. But cold air seeps through from somewhere beyond."}]
	var opts: Array = []
	var bonus := _learned("collapse")
	if bonus > 0:
		out.append({"n": "(You know this pile better each time: +%d on your next try.)" % bonus})
	var eye := LehanQuests.best("perception")
	var woods := LehanQuests.best("survival")
	var reader: Dictionary = eye if Game.ability(eye, "perception") >= Game.ability(woods, "survival") else woods
	var skill := "perception" if reader == eye else "survival"
	var ok := Game.check(reader, skill, Game.NORMAL, bonus)
	opts.append({"t": "Follow the cold air, and find where the stones are only leaning.", "silent": true,
		"ok": ok, "checks": [LehanQuests.chk(reader, skill, Game.NORMAL, bonus, _learned_why(bonus))], "tip": "Whoever is best at Perception or Survival looks.",
		"after": [{"n": "%s finds it: a gap behind a tilted beam, just wide enough to squeeze through." % _first(reader)}, _fx("q:skee_collapse=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
			else [{"n": "A stone shifts under a hand, and rubble rattles down on your heads."}, _fx("hurt:2"), _failed("collapse")]})
	var strong := LehanQuests.best("toughness")
	var diggers := mini(Game.party.size() - 1, 2)
	ok = Game.check(strong, "toughness", Game.NORMAL, diggers + bonus)
	opts.append({"t": "Dig through, stone by stone.", "silent": true,
		"ok": ok, "checks": [LehanQuests.chk(strong, "toughness", Game.NORMAL, diggers + bonus, _helped_why(diggers, bonus))],
		"after": [{"n": "An hour of sweat and scraped knuckles, and there's a way through."}, _fx("q:skee_collapse=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
			else [{"n": "The pile slides and settles again, worse than before. Bruised and filthy, you give up for now."}, _fx("hurt:3"), _failed("collapse")]})
	if LehanQuests.can_nudge("skee"):
		ok = Game.check(LehanQuests.host_char(), "perception", Game.NORMAL, 4 + bonus)
		opts.append({"t": "Let the spirit feel for the way through.", "tags": ["Spirit"], "silent": true,
			"ok": ok, "checks": [LehanQuests.chk(LehanQuests.host_char(), "perception", Game.NORMAL, 4 + bonus, _why(["the spirit's help +4", _learned_why(bonus)]))],
			"tip": "The spirit can help once on this quest.",
			"after": [_fx("q:skee_nudge=used"), LehanQuests.nudge_line()] + ([{"n": "There. Behind the tilted beam. A gap, just wide enough."}, _fx("q:skee_collapse=1")] if ok
				else [{"n": "Nothing. Stone and more stone."}])})
	opts.append({"t": "Leave it.", "silent": true, "after": []})
	out.append({"choice": "collapse", "options": opts, "prompt": "Choose (1-%d)" % opts.size()})
	return out


static func bag() -> Array:
	return [{"n": "A leather bag, dropped and half chewed. Inside: rat traps, a sling, a little carved charm against ghosts. A rat's head is burned into the flap."},
		{"i": "Skee's. He really did run."},
		_fx("q:skee_bag=1"), {"n": "(You take Skee's bag.)"}]


## The chamber of the lights: the shattered remains of a figure that once stood there, smashed on
## purpose and walled in (the player may guess by whom), a few of its shards still glowing. One way of looking per visit; the first time also takes a glowing
## shard for Skee.
static func lights() -> Array:
	var first := _q("skee") == "going"
	var out: Array = []
	if first:
		out.append({"n": "The passage ends in an old doorway that was once bricked up. Most of the bricks have fallen in."})
		out.append({"n": "Beyond it is a round chamber. In the middle lies a heap of broken stone, all that is left of something that once stood here. A figure, perhaps. Most of the pieces are grey and dead, but here and there a shard gives off a weak blue light, cold and steady."})
		out.append({"n": "The breaks are sharp and clean. This didn't fall with age. Someone broke it, on purpose and thoroughly."})
		out.append({"n": "On one of the larger pieces runs part of a carved band. A circlet, maybe. Or a crown."})
		out.append({"i": "A crown, like the one on the stone head from the shrine? Hard to say. It's broken off just where it would matter."})
		out.append({"sp": "Something here is familiar. I can't hold on to it."})
		out.append(_fx("q:skee=seen"))
		Game.story["crown_ward_seen"] = true
	else:
		out.append({"n": "A few shards still glow faintly among the rubble."})
	var opts: Array = []
	var done: Array = [] if not first else [{"n": "You pick a small glowing shard out of the rubble for Skee. It stays faintly blue in your palm."},
		{"n": "(Go back to Skee in the market square.)"}]
	if _q("skee_lore") == "":
		var scholar := LehanQuests.best("lore")
		var ok := Game.check(scholar, "lore", Game.NORMAL)
		opts.append({"t": "Read what is left of the carvings.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(scholar, "lore", Game.NORMAL)],
			"after": ([{"n": "%s fits a few pieces together. Warding script, older than Lehan, most of it lost. What is left says something like \"...kept below... let it sleep.\"" % _first(scholar)},
				_fx("q:skee_lore=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
				else [{"n": "Old letters on broken stone, too few to make sense of."}]) + done})
	if _q("skee_ward") == "":
		var caster := LehanQuests.best("magic")
		var ok := Game.ability(caster, "magic") > 0 and Game.check(caster, "magic", Game.NORMAL)
		opts.append({"t": "Hold a glowing shard and feel what it does.", "silent": true, "ok": ok, "checks": [LehanQuests.chk(caster, "magic", Game.NORMAL).merged({"needs_skill": true})],
			"after": ([{"n": "%s's hand tingles. There is still a pull in the shards, faint but steady: a ward, broken but not quite gone. It seems to hold something down. What, it's hard to tell." % _first(caster)},
				_fx("q:skee_ward=1"), _fx("xp:%s" % LehanQuests.CHECK_XP)] if ok
				else [{"n": "Cold stone. A hum, maybe, too low to be sure of."}]) + done})
	if _host() != "" and _q("skee_touched") == "":
		opts.append({"t": "Let the spirit reach for the shards.", "tags": ["Spirit"], "silent": true,
			"tip": "No check. The spirit wants to.",
			"after": [_fx("q:skee_touched=1"), {"sp": "I have been near this before. I don't know when."},
				{"i": "For a moment the host sees pale stone and a door closing. Then only the tunnel again, and the cold."},
				{"n": "One of the shards flickers, then steadies."}] + done})
	opts.append({"t": "Just take a glowing shard for Skee, and go." if first else "Leave the rubble be.", "silent": true, "after": done})
	out.append({"choice": "lights", "options": opts, "prompt": "Choose (1-%d)" % opts.size()})
	return out


# ---------------------------------------------------------------- persuading Skee

## One argument per talk; if every argument has failed, Skee comes anyway.
static func _persuade() -> Array:
	var out: Array = [{"s": "skee", "t": "You went down. You came back. Skee is glad. Skee is also... What was it? Ghosts? Tell Skee it was not ghosts."}]
	var opts: Array = []
	var talker := LehanQuests.best("talk")
	var tried_all := true
	var join: Array = _join()
	if _q("skee_ask_stone") == "":
		tried_all = false
		var ok := Game.check(talker, "talk", Game.NORMAL, 2)
		opts.append(_spoken(talker, {"t": "No ghost. Old broken stone with a glow in it. Here, hold it. It's only stone.",
			"ok": ok, "checks": [LehanQuests.chk(talker, "talk", Game.NORMAL, 2, "the glowing shard helps")],
			"after": [_fx("q:skee_ask_stone=1"), {"n": "Skee turns the shard over and over in his small hands."}] + (join if ok else _not_sure())}))
	if _q("skee_lore") != "" and _q("skee_ask_lore") == "":
		tried_all = false
		opts.append({"t": "The carvings are wards. They keep something down there. Not up here with us.", "say": _host(), "tags": ["Lore"],
			"tip": "What the carvings said: no check needed",
			"after": [_fx("q:skee_ask_lore=1"), {"s": "skee", "t": "Wards. Wards are good. Skee has a charm. Skee understands wards."}] + join})
	if bag_taken() and _q("skee_ask_bag") == "":
		tried_all = false
		var ok := Game.check(talker, "talk", Game.EASY)
		opts.append(_spoken(talker, {"t": "You dropped this when you ran. Your traps are all still in it.",
			"ok": ok, "checks": [LehanQuests.chk(talker, "talk", Game.EASY)], "tip": "He wants his bag back.",
			"after": [_fx("q:skee_ask_bag=1"), {"n": "Skee hugs the bag to his chest."}] + (join if ok else _not_sure())}))
	var calm := LehanQuests.host_trait(["Pious", "Calm", "Brave"])
	if calm != "" and _q("skee_ask_trait") == "":
		tried_all = false
		var ok := Game.check(LehanQuests.host_char(), "talk", Game.EASY)
		opts.append({"t": "Whatever it is, it has been down there longer than anyone's grandmother, and it hasn't hurt anyone yet.",
			"say": _host(), "tags": [calm], "ok": ok, "checks": [LehanQuests.chk(LehanQuests.host_char(), "talk", Game.EASY)],
			"after": [_fx("q:skee_ask_trait=1")] + (join if ok else _not_sure())})
	if _q("skee_ask_come") == "":
		tried_all = false
		var ok := Game.check(talker, "talk", Game.NORMAL)
		opts.append(_spoken(talker, {"t": "Come with us. Not down there. Just with us. You'll be safer in company than alone in your cellars.",
			"ok": ok, "checks": [LehanQuests.chk(talker, "talk", Game.NORMAL)],
			"after": [_fx("q:skee_ask_come=1")] + (join if ok else _not_sure())}))
	if tried_all:
		return [{"s": "skee", "t": "Skee has thought and thought. Skee is still afraid. But Skee is more afraid of not knowing."}] + join
	opts.append({"t": "Later.", "say": _host(), "after": [{"s": "skee", "t": "Later. Yes. Skee will be here. Above ground."}]})
	out.append({"choice": "skee_persuade", "options": opts, "prompt": "Choose (1-%d)" % opts.size()})
	return out


static func _not_sure() -> Array:
	return [{"s": "skee", "t": "Skee... is not sure. Skee will think about it. Ask Skee again."},
		{"n": "(Skee isn't convinced yet. Talk to him again, and try another argument.)"}]


static func _join() -> Array:
	return [
		{"s": "skee", "t": "Not ghosts. Good. Then Skee is not a coward. Skee was only careful."},
		{"s": "skee", "t": "Skee will come with you. Skee has good eyes, and a good sling, and Skee knows every crack in this town. At the inn, when you want Skee."},
		_fx("q:skee=done"), _fx("recruit:skee"),
		{"n": "(Skee is now on the inn's list. He asks no fee.)"},
	] + LehanQuests.finish_xp_steps("skee") + LehanQuests.quest_finished_steps()


static func _spoken(c: Dictionary, o: Dictionary) -> Dictionary:
	var k := LehanQuests.key_of(c)
	o["say"] = k if k != "" else _host()
	o["portrait"] = o.say
	return o
