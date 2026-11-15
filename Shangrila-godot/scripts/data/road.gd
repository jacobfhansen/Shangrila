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
	steps.append_array(consent(host))
	steps.append({"n": "(From now on you control %s fully in combat. The others still act on their own.)" % h})
	steps.append({"n": "By evening the walls of Lehan rise out of the fields."})
	return steps


## The spirit's first words: it asks its host to let it take control. Each host has four
## pitches; those marked "ok" suit the host's traits. A wrong pitch gets pushback and another
## try; taking hold by force always works, but leaves the host afraid.
const CONSENT := {
	"joss": {
		"intro": "Joss walks on, scowling at nothing. Then, for the first time, the thing inside him finds words.",
		"answer": "Afraid? I've been afraid of sergeants and moneylenders. Not of voices. Get out of my head.",
		"pitches": [
			{"ok": true, "t": "Follow my lead, and you will never count coppers again. Your debt will be the first thing to go.",
				"reply": "Joss goes very still. The debt. The moneylender's smile. Go on, he thinks. I'm listening."},
			{"ok": true, "t": "Let me guide you, and people will bow to you, as they once bowed to me.",
				"reply": "The hall again, and the bowing crowd. Joss swallows. They'd bow? To me?"},
			{"t": "Your friends need you. Let me help you keep them alive.",
				"reply": "They're hired swords, not friends, Joss thinks. Try again."},
			{"t": "I am old, and tired, and lost. Please.",
				"reply": "Please? Something like a laugh. Beggars get nothing from me. I've been one."},
		],
	},
	"maera": {
		"intro": "Maera's hand is on her knife again before she knows why. Then, for the first time, the thing inside her finds words.",
		"answer": "I'm not afraid. I'm angry. You were in my head on the road, and in my arm in that fight. Who are you?",
		"pitches": [
			{"ok": true, "t": "Let me in, and I will show you the hall again, and everything behind it. All of it.",
				"reply": "All of it? The anger doesn't go, but something hungrier joins it. Fine. Show me."},
			{"ok": true, "t": "Your friends nearly died today. Let me help you keep them safe.",
				"reply": "She looks at the others: Ommuk's split lip, Tikkat still shaking. For them, she thinks. Not for you."},
			{"t": "Be calm. Breathe. You are safe with me.",
				"reply": "Don't tell me to be calm! Her pulse hammers. The wrong thing to say."},
			{"t": "Coin enough for a house by the coast. That is what I offer.",
				"reply": "I don't want your coin. I want answers."},
		],
	},
	"ommuk": {
		"intro": "Ommuk sits down at the side of the road, slowly, as Thuugs do. Then, for the first time, the thing inside him finds words.",
		"answer": "I am not afraid, he thinks, quite calmly. I have prayed for sixty years. I only wonder what took you so long to answer.",
		"pitches": [
			{"ok": true, "t": "You prayed for someone to listen. I listened.",
				"reply": "A long, slow breath. Then I will listen too. Guide me, and I will follow, as far as my conscience allows."},
			{"ok": true, "t": "Let me in, and together we will help those who need it.",
				"reply": "Help. He turns the word over like a pebble. Yes. That I can agree to."},
			{"t": "Do as I say, and you will be rich.",
				"reply": "Ommuk's laugh is a low rumble. What would a Thuug do with riches? Buy a bigger shell?"},
			{"t": "Obey me. I was a king.",
				"reply": "Kings, Ommuk thinks, have never answered a single one of my prayers."},
		],
	},
	"ithrae": {
		"intro": "Ithrae walks a little apart from the others, rubbing the hand that touched the stone. Then, for the first time, the thing inside her finds words.",
		"answer": "I'm not afraid of you, she thinks. I'm afraid of how familiar you feel. What are you?",
		"pitches": [
			{"ok": true, "t": "I do not know what I am. Help me find out.",
				"reply": "A long silence. That's the first honest thing anyone has said to me in weeks. All right. We'll find out together."},
			{"ok": true, "t": "Let me in, and I will show you what lies behind the hall of light.",
				"reply": "Behind it... She bites her lip. You know I can't say no to that."},
			{"t": "Smile. You are alive, and the day is fine.",
				"reply": "Easy for you to say, she thinks. You're already dead. Aren't you?"},
			{"t": "You will be powerful. More powerful than any mage alive.",
				"reply": "Power. She shivers. That word sounds wrong in your voice. I don't know why."},
		],
	},
	"tikkat": {
		"intro": "Tikkat hums a nervous tune to drown out the feeling in his head. It doesn't work. Then, for the first time, the thing inside him finds words.",
		"answer": "Everyone says that right before something terrible happens, he thinks. What do you want?",
		"pitches": [
			{"ok": true, "t": "Let me in, and I will keep the blades away from you. You felt my help today.",
				"reply": "No blades? Not one? A shaky breath. Deal. Deal, deal, deal."},
			{"ok": true, "t": "Follow my lead, and your pockets will never be empty again.",
				"reply": "Never empty. His paws twitch towards his purse. You know exactly what to say to a Nisk, don't you?"},
			{"t": "Be brave. Face your fears.",
				"reply": "Brave Nisk are dead Nisk, he thinks. Everyone knows that."},
			{"t": "Pray with me.",
				"reply": "Pray? I'll leave that to Ommuk. He has the patience for it."},
		],
	},
}


static func consent(host: String) -> Array:
	var c: Dictionary = CONSENT[host]
	return [
		{"n": c.intro},
		{"sp": "Do not be afraid."},
		{"i": c.answer},
		_consent_choice(host, [0, 1, 2, 3], true),
	]


static func _consent_choice(host: String, left: Array, first: bool) -> Dictionary:
	var h := _name(host)
	var c: Dictionary = CONSENT[host]
	var opts := []
	for k in left:
		var pitch: Dictionary = c.pitches[k]
		var after: Array = [{"sp": pitch.t}, {"i": pitch.reply}]
		if pitch.get("ok", false):
			after.append({"fx": "consent_given", "wait": 0.1})
			after.append({"i": "Something settles inside %s, like a hand closing around a sword hilt. This time, the hand is welcome." % h})
		else:
			var rest := left.duplicate()
			rest.erase(k)
			after.append(_consent_choice(host, rest, false))
		opts.append({"bb": "[i]\u201C%s\u201D[/i]" % pitch.t, "after": after})
	opts.append({"bb": "[i](Take hold of %s by force.)[/i]" % h, "after": [
		{"fx": "consent_forced", "wait": 0.1},
		{"i": "The spirit closes around %s's will like a fist. %s fights it, and loses. For a moment there is only terror, then a dull, sullen quiet." % [h, h]},
	]})
	var prompt := "What does the spirit say?" if first else "Try again, or take hold by force"
	return {"choice": "consent", "options": opts, "speakers": "traits", "prompt": prompt}
