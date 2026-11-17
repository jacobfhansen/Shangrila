class_name LehanData
extends RefCounted
## Arriving in Lehan (see "Arrival in Lehan: the employer and the split" in IDEAS.md): the walk
## to the employer's house, the meeting, the pay and how it is split (each host has their own
## twist), the company splitting up at the inn, and the short talks that win them back.
##
## Choices record what happened with {"fx": "key=value"} steps; the town screen passes them to
## record(). settle() then pays everyone and decides who is soured, and parting() and
## rejoin_talk() read the result. Everything is kept in Game.story["lehan"].

const EMPLOYER := {"name": "The Employer", "race": "Human",
	"look": {"skin": "#d8b898", "hair": "#8a8a8a", "cloth": "#4a4a50"}}

## What the job pays, in silver, by how the proof and the questions went.
const PAY := {"head": 100, "kept": 60, "lie": 70, "warm": 70, "silent": 60}
const POCKET := 15       # what Tikkat can palm from the purse
const SKETCH := 5        # what Ithrae gives up for a look at the sketch
const MEETING_XP := 1.0 / 3.0   # of a raise, for everyone at the meeting

static func _pick(prefer: Array, host: String) -> String:
	for k in prefer:
		if k != host:
			return k
	return prefer[0]


static func _name(key: String) -> String:
	return PrologueData.CAST[key].name


static func _first(key: String) -> String:
	return _name(key).split(" ")[0]


## "100 silver pieces".
static func _coins(silver: int) -> String:
	return "%d silver pieces" % silver


static func state() -> Dictionary:
	if not Game.story.has("lehan"):
		Game.story["lehan"] = {}
	return Game.story["lehan"]


## Applies a {"fx": "key=value"} step from the scene.
static func record(fx: String) -> void:
	var kv := fx.split("=")
	if kv.size() == 2:
		state()[kv[0]] = kv[1]


## The company member with this key, wherever they are (party or inn).
static func member(key: String) -> Dictionary:
	var nm := _name(key)
	for c in Game.party + Game.roster:
		if c.name == nm:
			return c
	return {}


static func head_saved() -> bool:
	return Game.story.get("host", "") == "ommuk" and Game.story.get("prologue_reply", -1) == 1


## Who would notice Tikkat palming coins: the best Perception, with Curious eyes a little sharper.
## Ties go to the earlier member of the company.
static func noticer(host: String) -> String:
	var best := ""
	var top := -999
	for k in PrologueData.ORDER:
		if k == host:
			continue
		var c := member(k)
		if c.is_empty():
			continue
		var p: int = Game.ability(c, "perception") * 2
		if "Curious" in PrologueData.CAST[k].traits:
			p += 1
		if p > top:
			top = p
			best = k
	return best


# ---------------------------------------------------------------- the walk

static func walk(host: String) -> Array:
	var h := _first(host)
	var lead := _pick(["joss", "maera", "ommuk"], host)
	return [
		{"n": "Inside the gate, Lehan smells of smoke, wet straw and fresh bread. The company threads its way through the evening crowd."},
		{"s": lead, "t": "Pay first, then beds. Our man said he'd wait for us off Tanners' Row."},
		{"s": _pick(["tikkat", "ommuk", "maera"], host), "t": "Tanners' Row? That's where the smell lives."},
		{"s": _pick(["maera", "ithrae", "joss"], host), "t": "Rich enough to pay five people to break a rock. Poor enough to live by the tanneries. Odd."},
		{"i": "Through %s's eyes the spirit watches roofs, chimneys and crooked lanes go by. The name Lehan means nothing to it. And yet the streets feel strangely familiar, as if they were laid over older ones." % h},
		{"s": _pick(["ommuk", "tikkat", "ithrae"], host), "t": "I will be glad of a bed. This shell was not made for roads."},
		{"n": "The house is narrow and plain, squeezed between a cooper's yard and a shuttered shop. A single lamp burns behind the shutters."},
		{"s": lead, "a": "knocking", "t": "Harrow Company. We're expected."},
	]


# ---------------------------------------------------------------- the meeting

static func meeting(host: String) -> Array:
	var h := _first(host)
	var lead := _pick(["joss", "maera", "ommuk"], host)
	var steps: Array = [
		{"n": "A man in a plain grey coat lets them in. The room is bare: a table, two chairs, a cold hearth. Nobody lives here. Somebody is only waiting here."},
		{"s": "employer", "t": "You're late. Well? Is it done?"},
		{"s": lead, "t": "Rubble, as ordered."},
		{"i": "The moment the man looks at %s, something cold stirs behind %s's eyes. A certainty with no reason behind it, no name and no face: whoever this man is, he would see you destroyed." % [h, h]},
	]
	steps.append_array(_proof(host, lead))
	if host == "ithrae":
		steps.append(_sketch_choice())
	steps.append({"s": "employer", "t": "And that is the end of it. You were never here, and you never saw this house."})
	steps.append_array(_split(host))
	if host == "maera":
		steps.append_array([
			{"n": "On the way out, Maera's eyes do what they always do, and catch what nobody else does."},
			{"n": "Behind the house stands a cart, packed and roped, ready to leave. By the door is a pair of boots caked with the red mud of the shrine road."},
			{"fx": "saw_cart=yes", "wait": 0.1},
			{"i": "The tracks by the shrine, Maera thinks. He was the one watching from the trees. And now he's leaving town."},
		])
	steps.append({"n": "The door closes behind them. A bolt slides home."})
	return steps


static func _proof(host: String, lead: String) -> Array:
	if head_saved():
		return [
			{"s": "employer", "t": "Proof?"},
			{"i": "The crowned head sits in Ommuk's pack, heavy as a sleeping child. He has carried it all the way from the shrine."},
			{"choice": "proof", "speakers": true, "prompt": "Choose a reply (1-2)", "options": [
				{"t": "Here. The head of the figure. Whole.", "say": host, "after": [
					{"fx": "proof=head", "wait": 0.1},
					{"n": "He turns the stone head in his hands, slowly, the way a man handles a snake that might not be dead."},
					{"s": "employer", "t": "Good. Very good. For this, I pay extra."},
					{"n": "He counts out %s onto the table, and the head disappears into a sack." % _coins(PAY.head)},
					{"i": "Ommuk watches the stone face go. Something in his old chest aches, and he cannot say why."}]},
				{"tags": ["Calm"], "t": "We broke it all. There is nothing to show but dust on our boots.", "say": host, "after": [
					{"fx": "proof=kept", "wait": 0.1},
					{"s": "employer", "t": "Nothing? I pay for results, not stories."},
					{"n": "His eyes narrow, but he counts out the coins: %s, less than promised." % _coins(PAY.kept)},
					{"i": "The head stays in Ommuk's pack. He tells himself it deserved better than a stranger's sack."}]},
			]},
		]
	return [
		{"s": lead, "a": "setting a chip of carved stone on the table", "t": "A piece of the crown. The rest is gravel."},
		{"s": "employer", "t": "A chip of stone. I could have picked that up anywhere."},
		{"s": "employer", "a": "leaning closer", "t": "Tell me about the night. Did anything happen at the shrine? Anything... unusual?"},
		{"choice": "night", "speakers": true, "prompt": "Choose a reply (1-3)", "options": [
			{"t": "Nothing happened. We slept, we broke it, we left.", "say": host, "after": [
				{"fx": "answer=lie", "wait": 0.1},
				{"s": "employer", "t": "Nothing. Good."},
				{"n": "He studies %s a moment too long. Then he counts out %s onto the table." % [_first(host), _coins(PAY.lie)]}]},
			{"t": "The stone was warm. At dawn. That's all.", "say": host, "after": [
				{"fx": "answer=warm", "wait": 0.1},
				{"n": "The man goes very still."},
				{"s": "employer", "t": "Stone keeps the sun's heat. You would do well to forget it."},
				{"i": "He is lying, the spirit knows. And under the lie, he is afraid."},
				{"n": "He counts out %s, quickly, as if he wants them gone." % _coins(PAY.warm)}]},
			{"t": "(Say nothing. Let the others answer.)", "silent": true, "after": [
				{"fx": "answer=silent", "wait": 0.1},
				{"s": _pick(["tikkat", "joss", "ommuk"], host), "t": "Tikkat snored, Maera named a root. Nothing worth your coin."},
				{"s": "employer", "t": "Late, and no proof. I'll pay, less something for my trouble."},
				{"n": "He counts out %s onto the table." % _coins(PAY.silent)}]},
		]},
	]


## Ithrae's twist in the meeting: she asks what the shrine really was.
static func _sketch_choice() -> Dictionary:
	return {"choice": "shrine", "speakers": true, "prompt": "Choose a reply (1-2)", "options": [
		{"tags": ["Curious"], "t": "What was that shrine, really? Whose face was on it?", "say": "ithrae", "after": [
			{"s": "employer", "t": "A nobody's. An old eyesore on a road my family wants widened. You are paid to break things, not to ask about them."},
			{"n": "Half under his gloves lies a sheet of paper: a sketch of the shrine, drawn with care."},
			{"choice": "sketch", "speakers": true, "prompt": "Choose a reply (1-2)", "options": [
				{"tags": ["Curious"], "t": "Let me look at that sketch, and keep five silver of my share.", "say": "ithrae", "after": [
					{"fx": "mark=yes", "wait": 0.1},
					{"n": "He hesitates, then shrugs and slides it across. While the others talk, Ithrae copies a small mark from its corner into her notes: a ring, cut through by a single line."},
					{"s": "employer", "t": "Satisfied? Five silver lighter, and none the wiser."}]},
				{"t": "Never mind.", "say": "ithrae", "after": []},
			]}]},
		{"t": "(Say nothing.)", "silent": true, "after": []},
	]}


# ---------------------------------------------------------------- the pay split

static func _split(host: String) -> Array:
	var steps: Array = []
	if host == "tikkat":
		steps.append({"n": "The employer drops the purse on the table, right next to Tikkat's paw."})
		var nk := noticer(host)
		var caught: Array = [{"fx": "pocket=yes", "wait": 0.1},
			{"n": "Two coins, three, four, gone up a sleeve before anyone has looked down."}]
		if nk != "":
			caught.append({"n": "Anyone, that is, except %s, whose eyes rest on Tikkat's sleeve a moment too long." % _first(nk)})
			caught.append({"fx": "noticer=" + nk, "wait": 0.1})
		steps.append({"choice": "pocket", "speakers": true, "prompt": "Choose (1-2)", "options": [
			{"tags": ["Greedy"], "silent": true, "t": "(Palm a few coins while nobody is looking.)", "after": caught},
			{"silent": true, "t": "(Keep your paws to yourself.)", "after": [
				{"i": "Tikkat sits on his paws. It is the hardest thing he has done all week."}]},
		]})
	if host == "joss":
		steps.append({"n": "Joss pulls the purse across the table. It is the leader's job to share out the pay."})
		steps.append({"choice": "split", "speakers": true, "prompt": "How does Joss share it? (1-3)", "options": [
			{"t": "Even shares. We all broke the same rock.", "say": "joss", "after": [
				{"fx": "split=even", "wait": 0.1},
				{"s": "maera", "t": "Even? From you? Who are you, and what have you done with Joss?"}]},
			{"tags": ["Greedy"], "t": "A double share for the leader. It's my name on the debt.", "say": "joss", "after": [
				{"fx": "split=double", "wait": 0.1},
				{"s": "maera", "t": "Your name, our backs. Fine. Take it."},
				{"n": "Maera does not look at Joss again for the rest of the evening."}]},
			{"tags": ["Proud"], "t": "Double for me. And Tikkat's share goes against what he owes me.", "say": "joss", "after": [
				{"fx": "split=docked", "wait": 0.1},
				{"s": "tikkat", "t": "Half? Half! I swung a pick like everyone else!"},
				{"s": "maera", "t": "And you keep a double share on top. Generous, Joss."}]},
		]})
		return steps
	# Everyone else: Joss shares it out his way.
	steps.append({"s": "joss", "a": "counting", "t": "Double share for the leader. Tikkat, half a share. The rest goes against what you owe me."})
	if host == "tikkat":
		steps.append({"i": "Half. Tikkat bites back a squeak, and thinks of what is up his sleeve."})
	else:
		steps.append({"s": "tikkat", "t": "Half? Half! I swung a pick like everyone else!"})
	match host:
		"ommuk":
			steps.append({"choice": "ommuk", "speakers": true, "prompt": "Choose a reply (1-4)", "options": [
				{"tags": ["Generous"], "t": "Take mine, Tikkat. A Thuug needs little.", "say": "ommuk", "after": [
					{"fx": "gift=tikkat", "wait": 0.1},
					{"s": "tikkat", "t": "You... really? Ommuk, you old rock. I'll never forget it. Well. Probably never."},
					{"s": "joss", "t": "Gone soft in the shell, that one."}]},
				{"tags": ["Pious"], "t": "My share goes to the temple here. I said so at the shrine.", "say": "ommuk", "after": [
					{"fx": "gift=temple", "wait": 0.1},
					{"s": "joss", "t": "Your share, your loss."},
					{"n": "Later that evening, the old priest of Lehan's little temple finds a heavy purse on his altar, and a slow, patient Thuug sitting in the back row."}]},
				{"tags": ["Calm"], "t": "Peace, both of you. Joss, half a share is too little. Tikkat, a debt is a debt.", "say": "ommuk", "after": [
					{"fx": "calmed=yes", "wait": 0.1},
					{"s": "joss", "t": "...Fine. Three quarters. And not a word more about it."},
					{"s": "tikkat", "t": "Three quarters. I can live with three quarters."}]},
				{"t": "(Say nothing, and pocket your share.)", "silent": true, "after": [
					{"n": "Tikkat sulks all the way to the inn."}]},
			]})
		"ithrae":
			steps.append({"choice": "ithrae", "speakers": true, "prompt": "Choose a reply (1-2)", "options": [
				{"tags": ["Honest"], "t": "That isn't fair, Joss, and you know it. Even shares.", "say": "ithrae", "after": [
					{"fx": "split=even", "wait": 0.1}, {"fx": "called_out=yes", "wait": 0.1},
					{"n": "The employer raises an eyebrow. Joss's face goes dark red."},
					{"s": "joss", "t": "...Even shares, then. Since our mage has spoken."},
					{"s": "tikkat", "a": "whispering", "t": "Thank you. Thank you, thank you."}]},
				{"t": "(Say nothing.)", "silent": true, "after": [
					{"n": "It isn't fair, and Ithrae knows it. She looks at the table and says nothing."}]},
			]})
		"maera":
			steps.append({"choice": "maera", "speakers": true, "prompt": "Choose a reply (1-3)", "options": [
				{"tags": ["Loyal"], "t": "Joss. We all did the same work. Even shares, and no hard feelings.", "say": "maera", "after": [
					{"fx": "split=even", "wait": 0.1}, {"fx": "stood_up=calm", "wait": 0.1},
					{"s": "joss", "a": "grumbling", "t": "Even shares. Fine. Don't make a habit of it."}]},
				{"tags": ["Hot-tempered"], "t": "Half a share? You greedy, crooked guardsman. Even shares, or I'll split your skull instead.", "say": "maera", "after": [
					{"fx": "split=even", "wait": 0.1}, {"fx": "stood_up=angry", "wait": 0.1},
					{"n": "For a moment nobody breathes. Then Joss shoves the coins into five even piles."},
					{"s": "joss", "t": "There. Happy? I won't forget that, Vell."},
					{"s": "tikkat", "t": "I will never forget it either. In a good way!"}]},
				{"t": "(Say nothing.)", "silent": true, "after": [
					{"n": "Maera's jaw tightens. She says nothing."}]},
			]})
	return steps


## Who gets what, plus who is soured. Pays everyone and stores the outcome. Call once.
static func settle(host: String) -> void:
	var st := state()
	var total: int = PAY.get(st.get("proof", st.get("answer", "silent")), PAY.silent)
	var pocket := POCKET if st.get("pocket", "") == "yes" else 0
	total -= pocket
	var split: String = st.get("split", "even" if host == "joss" else "default")
	var w := {"joss": 1.0, "maera": 1.0, "ommuk": 1.0, "ithrae": 1.0, "tikkat": 1.0}
	if split in ["default", "double", "docked"]:
		w.joss = 2.0
	if split in ["default", "docked"]:
		w.tikkat = 0.75 if st.get("calmed", "") == "yes" else 0.5
	var sum := 0.0
	for k in w:
		sum += w[k]
	var shares := {}
	var given := 0
	for k in w:
		shares[k] = int(total * w[k] / sum)
		given += shares[k]
	shares.joss += total - given
	var fair := int(total / 5.0)
	shares.tikkat += pocket
	if st.get("mark", "") == "yes":
		shares.ithrae = maxi(0, shares.ithrae - SKETCH)
	match st.get("gift", ""):
		"tikkat":
			shares.tikkat += shares.ommuk
			shares.ommuk = 0
		"temple":
			shares.ommuk = 0
			Game.story["temple_friend"] = true
	st["shares"] = shares
	if st.get("proof", "") == "kept":
		var om := member("ommuk")
		var slot := Game.free_pack_slot(om) if not om.is_empty() else -1
		if slot >= 0:
			om.items[slot] = 33
	for k in shares:
		var c := member(k)
		if not c.is_empty():
			Game.add_silver(c, shares[k])
	# Who is soured, who is won over, who wants a cut.
	var mood := {}
	for k in PrologueData.ORDER:
		mood[k] = {"state": "talk"}
	if split == "double":
		mood.maera = {"state": "soured", "grudge": "double"}
	if split in ["default", "docked"] and st.get("calmed", "") != "yes":
		mood.tikkat = {"state": "soured", "grudge": "docked", "owed": maxi(0, fair - shares.tikkat)}
	if split == "docked":
		mood.maera = {"state": "soured", "grudge": "double"}
	if st.get("gift", "") == "tikkat" or st.get("called_out", "") == "yes" or st.get("stood_up", "") == "angry":
		mood.tikkat = {"state": "won"}
	if st.get("called_out", "") == "yes":
		mood.joss = {"state": "soured", "grudge": "humbled"}
	if st.get("stood_up", "") == "angry":
		mood.joss = {"state": "soured", "grudge": "angry"}
	var nk: String = st.get("noticer", "")
	if pocket > 0 and nk != "":
		if "Greedy" in PrologueData.CAST[nk].traits:
			mood[nk] = {"state": "cut", "owed": pocket / 2}
		elif "Honest" in PrologueData.CAST[nk].traits:
			mood[nk] = {"state": "soured", "grudge": "theft", "owed": pocket}
	for k in mood:
		if k == host:
			continue
		var c := member(k)
		if c.is_empty():
			continue
		c["rejoin"] = mood[k].state
		c["grudge"] = mood[k].get("grudge", "")
		c["owed"] = mood[k].get("owed", 0)
	st["xp"] = Game.story_xp(MEETING_XP)


# ---------------------------------------------------------------- at the inn

## The walk to the inn and the company going its separate ways. Call after settle().
static func parting(host: String) -> Array:
	var h := _first(host)
	var steps: Array = [
		{"n": "The inn is warm and loud, and for the first time in a week nobody is carrying a crowbar."},
		{"n": "Nobody says it out loud, but everyone knows it: the job is done, the pay is shared, and the Harrow Company has no more work."},
		{"n": "(The job is done: everyone gains experience. Spend it at the inn, under Info.)"},
	]
	for k in PrologueData.ORDER:
		if k == host:
			continue
		var c := member(k)
		steps.append({"s": k, "t": _goodbye(k, c.get("rejoin", "talk"), c.get("grudge", ""))})
	steps.append({"fx": "split", "wait": 0.8})
	steps.append({"i": "%s sits alone at the table with a cup going cold. The spirit feels the company drift apart like smoke. It will need them again. It will need many more than them." % h})
	steps.append({"n": "(The company has split up. The others stay at the inn. Find work for them first, then choose one there and Muster to talk them round.)"})
	return steps


static func _goodbye(k: String, mood: String, grudge: String) -> String:
	if mood == "won":
		return {"tikkat": "You stood up for me. I won't forget that. Find me when there's work. Safe work."}.get(k,
			"Thank you, for back there. Find me when there's work.")
	if mood == "cut":
		return "Clever little paws, Tikkat. We'll talk about that, you and me. Later."
	match grudge:
		"docked": return "Half a share. Half! Don't anyone talk to me. I'm going to bed."
		"double": return "Double share for the leader. I'll remember that, Joss. Don't come looking for me."
		"humbled": return "Lectured in front of the client, by my own mage. I need a drink. Alone."
		"angry": return "Crooked guardsman, she calls me. In front of everyone. We're done for tonight."
		"theft": return "Some of us can count, Tikkat. I won't pretend I didn't see. Good night."
	return {
		"joss": "I'll be at the moneylender's in the morning, and back here drinking whatever's left by noon.",
		"maera": "A bath, a bed, and a day with nobody talking to me. Then we'll see.",
		"ommuk": "I will sit by the fire and rest this old shell. You know where to find me.",
		"ithrae": "I'll take a room upstairs. I have... things to write down.",
		"tikkat": "Beds! Real beds! Wake me in a week.",
	}[k]


# ---------------------------------------------------------------- winning them back

## What each says before there is any work to offer (the mines job comes from the market's crier).
const NO_JOB := {
	"joss": "Talk to me when there's a job, and a purse at the end of it.",
	"maera": "Work? What work? Come back when you have some.",
	"ommuk": "Rest first. When there is a task worth doing, come and tell me about it.",
	"ithrae": "Is there work? No? Then let me write.",
	"tikkat": "No job, no Tikkat. Wake me when there's coin in it.",
}


const NO_JOB_HINT := "(There is no work to offer yet. News of jobs is cried in the market square.)"


## What a companion says when asked to rejoin before there is a job.
static func no_job_line(k: String, c: Dictionary, host: String) -> String:
	if c.get("rejoin", "talk") == "won":
		return "You stood by me, %s, and I'll stand by you. But there's no job yet. Find one, and I'm yours." % _first(host)
	return NO_JOB[k]


## What happens when the host knocks at the employer's house.
static func knock_text() -> String:
	if Game.story.get("left_lehan", false):
		return "You knock. No reply.\n\nThe shutters are closed, and no lamp burns behind them. The house looks empty."
	if Game.story.has("employer"):
		return "The door opens a crack. A grey sleeve, an eye.\n\n\"Our business is done. Go away.\"\n\nThe door shuts, and a bolt slides home."
	return "A narrow, plain house. Nobody answers."


static func has_job() -> bool:
	return "mines" in Game.known


## A short talk at the inn. Effects: "pay:N" (the host pays N silver), "join", "notyet".
## `purse` is what the party has, so unaffordable offers say so.
static func rejoin_talk(k: String, c: Dictionary, host: String, purse: int) -> Array:
	var h := _first(host)
	var mood: String = c.get("rejoin", "talk")
	var owed: int = c.get("owed", 0)
	if not has_job():
		return [{"s": k, "t": no_job_line(k, c, host)},
			{"n": NO_JOB_HINT}, {"fx": "notyet", "wait": 0.1}]
	if mood == "won":
		return [{"s": k, "t": "%s! Of course I'm coming. You stood by me." % h}, {"fx": "join", "wait": 0.1}]
	var no := func(line: String) -> Array:
		return [{"s": k, "t": line}, {"fx": "notyet", "wait": 0.1}]
	var yes := func(line: String) -> Array:
		return [{"s": k, "t": line}, {"fx": "join", "wait": 0.1}]
	var paid := func(n: int, line: String) -> Array:
		if purse < n:
			return [{"n": "%s counts the coins. Not enough." % h}, {"fx": "notyet", "wait": 0.1}]
		return [{"fx": "pay:%d" % n, "wait": 0.1}, {"s": k, "t": line}, {"fx": "join", "wait": 0.1}]
	var opener := ""
	var opts: Array = []
	if mood == "cut":
		opener = "Half of what went up your sleeve, rat. Then we talk about work."
		opts = [
			{"t": "Fair. Here's your half. (%s)" % Game.money_string(owed), "say": host,
				"after": paid.call(owed, "Pleasure doing business. Right. Where are we going?")},
			{"t": "I don't know what you're talking about.", "say": host,
				"after": no.call("Course you don't. Come back when your memory improves.")},
		]
	elif mood == "soured":
		match c.grudge:
			"docked":
				opener = "Back for the other half of my share? Oh, wait. That's in Joss's purse."
				opts = [
					{"tags": ["Greedy"], "t": "Here's what you were short. (%s) Now come on." % Game.money_string(owed), "say": host,
						"after": paid.call(owed, "Now that is a language I understand. I'm in.")},
					{"t": "Forget the money. Think of the next job.", "say": host,
						"after": no.call("The next job, where I get half again? No thank you.")},
				]
			"double":
				opener = "A double share for the leader, and you all just nodded. What do you want?"
				opts = [
					{"tags": ["Loyal"], "t": "You were right, and we should have said so. It won't happen again.", "say": host,
						"after": yes.call("...All right. One more chance. Don't waste it.")},
					{"t": "It's only coin, Maera. Let it go.", "say": host,
						"after": no.call("Only coin. That's what people say when it's someone else's.")},
				]
			"humbled", "angry":
				opener = "Come to gloat? Or to lecture me again?"
				opts = [
					{"tags": ["Proud"], "t": "Neither. The company needs its leader. Lead it.", "say": host,
						"after": yes.call("...Needs its leader. Well. Someone has to keep you lot alive.")},
					{"t": "A round for the table, on me. No hard feelings. (2S)", "say": host,
						"after": paid.call(20, "Make it a big round. And this never happened.")},
					{"t": "You had it coming, Joss.", "say": host,
						"after": no.call("Did I. Then you can manage without me.")},
				]
			"theft":
				opener = "I saw what you took, Tikkat. I can't travel with someone who steals from their friends."
				opts = [
					{"tags": ["Honest"], "t": "You're right. Here, the coins, all of them. Share them as you see fair. (%s)" % Game.money_string(owed), "say": host,
						"after": paid.call(owed, "...Thank you. That's all I wanted. I'll come.")},
					{"t": "It was only a few coins.", "say": host,
						"after": no.call("A few coins today. What tomorrow?")},
				]
	else:
		match k:
			"joss":
				opener = "Back already? What, miss my winning smile?"
				opts = [
					{"tags": ["Greedy"], "t": "The council pays well for the mines. Your debt won't pay itself.", "say": host,
						"after": yes.call("...No. No, it won't. All right. Count me in.")},
					{"tags": ["Proud"], "t": "The company needs a leader. Lead it.", "say": host,
						"after": yes.call("Needs a leader. Ha! Of course it does. Let's go.")},
					{"t": "Because I'm asking.", "say": host,
						"after": no.call("Asking's cheap. Come back with a better reason.")},
				]
			"maera":
				opener = "I said a day with nobody talking to me. It's been an hour."
				opts = [
					{"tags": ["Curious"], "t": "Miners are vanishing in the old workings. Don't you want to know why?", "say": host,
						"after": yes.call("...Vanishing. Damn you. Yes, I want to know. I'm in.")},
					{"tags": ["Loyal"], "t": "We're stronger together. You know it.", "say": host,
						"after": yes.call("We are. Fine. Somebody has to watch your backs.")},
					{"t": "There's good coin in it.", "say": host,
						"after": no.call("Did I ask about coin? Go away.")},
				]
			"ommuk":
				opener = "Sit. The fire is warm. What troubles you?"
				opts = [
					{"tags": ["Pious"], "t": "Miners are missing. Their families pray for them. Someone should answer.", "say": host,
						"after": yes.call("Someone should. Yes. I will come.")},
					{"tags": ["Generous"], "t": "People need help in those mines, and you're a healer.", "say": host,
						"after": yes.call("Then I will bring my bandages. And my slowness.")},
					{"t": "Come for the pay, Ommuk.", "say": host,
						"after": no.call("What would a Thuug do with more pay? Ask me another way.")},
				]
			"ithrae":
				opener = "Oh. It's you. I was writing about... the shrine."
				opts = [
					{"tags": ["Curious"], "t": "That shrine isn't finished with us. Maybe the old mines hold some answers.", "say": host,
						"after": yes.call("You feel it too, don't you? All right. I'll come.")},
					{"tags": ["Melancholy"], "t": "Better than sitting alone in a rented room, writing.", "say": host,
						"after": yes.call("...That's unkind. And true. Wait while I get my book.")},
					{"t": "We need a mage. Name your price.", "say": host,
						"after": no.call("My price? I'm not a sword for hire. Not like that.")},
				]
			"tikkat":
				opener = "Shh. I'm sleeping. In a real bed. Go away."
				opts = [
					{"tags": ["Greedy"], "t": "A full share this time, and I'll buy the first round. (1S)", "say": host,
						"after": paid.call(10, "A full share AND a drink? Why didn't you say so!")},
					{"tags": ["Cowardly"], "t": "You can stay at the back. We'll keep the blades off you.", "say": host,
						"after": yes.call("At the back. Way at the back. Behind Ommuk. Deal.")},
					{"t": "Haunted mines! You'll love it.", "say": host,
						"after": no.call("Haunted. Mines. Those are my two least favourite words. No.")},
				]
	return [{"s": k, "t": opener},
		{"choice": "rejoin", "speakers": true, "prompt": "Choose a reply (1-%d)" % opts.size(), "options": opts}]
