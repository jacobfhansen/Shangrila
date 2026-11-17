class_name PrologueData
extends RefCounted
## The opening scene, "Dawn at the shrine" (see DIALOGUES.md in the repository root).
##
## Steps are dictionaries:
##   {"n": text}                          narration
##   {"s": who, "t": text, "a": aside}    speech ("a" is an optional stage direction)
##   {"i": text}                          inner experience (the spirit's touch, the host's thoughts)
##   {"fx": "touch"}                      the spirit's first touch (a flash of light)

## The Harrow Company. `look` drives RacePortrait; `abilities` are their starting values
## (race bonus included, see IDEAS.md).
const CAST := {
	"joss": {"name": "Joss Harrow", "race": "Human", "cls": "Warrior",
		"abilities": {"combat": 2, "toughness": 1, "talk": 1},
		"traits": ["Brave", "Greedy", "Proud"],
		"blurb": "The company's leader. A town guard thrown out for taking bribes.",
		"look": {"skin": "#d8a878", "hair": "#4a3018", "cloth": "#6a2a20", "beard": true}},
	"maera": {"name": "Maera Vell", "race": "Human", "cls": "Ranger",
		"abilities": {"combat": 1, "missile": 2, "perception": 1, "survival": 1},
		"traits": ["Curious", "Loyal", "Hot-tempered"],
		"blurb": "A poacher's daughter who knows every forest path to the coast.",
		"look": {"skin": "#f0c8a0", "hair": "#a0502a", "cloth": "#3a5a2a", "hood": true}},
	"ommuk": {"name": "Ommuk", "race": "Thuug", "cls": "Cleric",
		"abilities": {"combat": 1, "toughness": 2, "lore": 1, "magic": 1},
		"traits": ["Pious", "Calm", "Generous"],
		"blurb": "A slow, patient healer who prays to whoever listens.",
		"look": {"skin": "#6f8a5c", "shell": "#5a4630", "cloth": "#d8c8a0"}},
	"ithrae": {"name": "Ithrae", "race": "Aeldroe", "cls": "Mage",
		"abilities": {"perception": 1, "lore": 1, "magic": 2},
		"traits": ["Curious", "Melancholy", "Honest"],
		"blurb": "A young Aeldroe who left her people to study magic.",
		"look": {"skin": "#dce6f2", "hair": "#f0f4ff", "cloth": "#4a4a8a"}},
	"tikkat": {"name": "Tikkat", "race": "Nisk", "cls": "Thief",
		"abilities": {"stealth": 2, "thievery": 1, "perception": 1},
		"traits": ["Greedy", "Cheerful", "Cowardly"],
		"blurb": "The lock-picker. Came cheap, talks too much, owes the most.",
		"look": {"skin": "#8a7866", "cloth": "#3a3030"}},
}

const ORDER := ["joss", "maera", "ommuk", "ithrae", "tikkat"]


## The Harrow Company as DialogueBox cast (flagged so they appear in the Speaking row).
static func company_cast() -> Dictionary:
	var c := {}
	for k in ORDER:
		var d: Dictionary = CAST[k].duplicate()
		d["company"] = true
		c[k] = d
	return c

## The waking: the spirit opens its eyes on the camp, before it has a host.
## {"sp": text} is the spirit's own thought (it has no host and no face yet).
const INTRO := [
	{"fx": "eyes", "wait": 5.2},
	{"sp": "...light."},
	{"n": "Grey dawn. Mist lies in the ditch along the road. By the embers of a campfire, five shapes are stirring."},
	{"s": "tikkat", "a": "yawning", "t": "Who decided we sleep next to a haunted rock?"},
	{"s": "joss", "t": "The man paying us did. Up. All of you."},
	{"sp": "Where... am I?"},
	{"s": "maera", "a": "rolling up her blanket", "t": "There was a root under my back all night. The same root. I've named it."},
	{"s": "ommuk", "t": "Roots are honest. They stay where they are. Unlike Tikkat in his sleep."},
	{"s": "tikkat", "t": "I do not move in my sleep."},
	{"s": "ithrae", "t": "You kicked me twice."},
	{"sp": "How long have I slept? The stone around me is old. So very old."},
	{"n": "Half the brambles have been hacked away from the shrine, uncovering a weathered stone figure. Its face is worn smooth, but the outline of a crown can still be made out."},
	{"sp": "A crown. Mine?"},
	{"s": "joss", "t": "Right. Picks and crowbars. The man paid for rubble by noon, and rubble is what he gets."},
	{"sp": "They mean to break it. Let them. There is nothing in that stone for me now."},
	{"s": "ithrae", "a": "a hand on the stone", "t": "Joss... it's warm. Stone shouldn't be warm at dawn."},
	{"s": "tikkat", "t": "Warm stone means silver underneath. Everyone knows that."},
	{"s": "ommuk", "a": "humming a slow prayer", "t": "Everyone does not know that."},
	{"sp": "Who are they? Hired hands. Five of them. Living, breathing, warm."},
	{"s": "maera", "a": "watching the trees", "t": "Someone's been watching this place. There are fresh tracks by the road."},
	{"sp": "I am fading. The stone held me together. Without it I am smoke in the morning air."},
	{"sp": "I must hold on to one of them. Now, before the light takes me."},
	{"host_choice": true},
]

## Right after the host is chosen: the first touch, seen from inside the host.
const TOUCH := [
	{"fx": "touch"},
	{"i": "Something stirs behind your eyes. A pressure, like a hand laid gently on the inside of your skull."},
	{"i": "For one heartbeat you see a hall full of light, and a crowd bowing low, to you. Then it is gone, and the mist is back."},
]

## How the host choice describes each of them, from the spirit's point of view.
const SEEN_AS := {
	"joss": "The one giving the orders. Hard, and hungry for something.",
	"maera": "The one watching the trees. Restless, sharp-eyed.",
	"ommuk": "The slow one, humming a prayer to no one in particular.",
	"ithrae": "The pale one with her hand on the stone. She can feel me.",
	"tikkat": "The small one, all whiskers and nerves.",
}

## Per host: their inner reaction, then the first choice. Each reply has tags, the line
## the host speaks (empty for a silent choice), and what follows.
const HOSTS := {
	"joss": {
		"inner": [
			"Joss's jaw tightens. He has had men try to get inside his head before: sergeants, moneylenders, a priest once. None of them got far.",
			"Not now, he thinks. Whatever you are, you're not getting a share.",
			"But the bowing crowd stays with him, like the taste of good wine. Nobody has bowed to Joss Harrow. Not ever.",
		],
		"replies": [
			{"tags": [], "t": "You heard me. Picks out. We're paid by the stone.",
				"after": [{"n": "The others shrug and take up their tools. By noon the shrine is rubble, and nobody asks Joss any questions."}]},
			{"tags": ["Proud"], "t": "I give the orders, and I say we take a look first. Nobody touches it until I say so.",
				"after": [{"s": "ommuk", "t": "Wise. Old things deserve a look before they are broken."},
					{"s": "tikkat", "t": "Wise is slow. Slow is unpaid."},
					{"n": "Joss makes them wait. For once, nobody argues with him."}]},
			{"tags": [], "t": "Ithrae, step away from that thing. Now.",
				"after": [{"s": "ithrae", "t": "I... yes. Of course."},
					{"n": "Ithrae steps back, rubbing her hand. Maera glances at Joss. She has never heard that tone from him before."}]},
			{"tags": ["Greedy"], "t": "If it's worth this much to someone to smash, it's worth something whole. Let's think about this.",
				"after": [{"s": "tikkat", "t": "Now you're talking!"},
					{"s": "ommuk", "t": "Now he is talking like Tikkat."},
					{"n": "Joss walks around the figure, weighing it with his eyes. The hall of light is still there, just behind them."}]},
		],
	},
	"maera": {
		"inner": [
			"Maera spins round, knife half drawn, before she understands that the touch came from inside.",
			"Who's there? Her heart is pounding. Show yourself, or get out of my head.",
			"The vision of the hall lingers. She has never seen a place like it, and she wants, badly, to see it again.",
		],
		"replies": [
			{"tags": ["Hot-tempered"], "t": "Did someone just... no. Forget it. Let's get this done.",
				"after": [{"n": "Maera attacks the brambles as if they had insulted her. Later she snaps at Tikkat for nothing, and doesn't apologise."}]},
			{"tags": ["Curious"], "t": "Did anyone else feel that? Just now?",
				"after": [{"s": "joss", "t": "Feel what?"},
					{"s": "ithrae", "t": "...Something. I felt something."},
					{"n": "The others stare at the two of them. Ommuk stops humming."}]},
			{"tags": ["Loyal"], "t": "Joss, those tracks worry me. Let's finish fast and get off this road.",
				"after": [{"s": "joss", "t": "Fair enough. Double time, all of you."},
					{"n": "They work fast and are gone before the mist lifts. Behind them, someone steps out of the trees to look at the rubble."}]},
			{"tags": [], "silent": true, "t": "(Say nothing. Keep watching the trees.)",
				"after": [{"n": "Maera says nothing. The pressure behind her eyes fades to a patient hum, as if something has decided to wait."}]},
		],
	},
	"ommuk": {
		"inner": [
			"Ommuk stops humming. For a long moment he does not move at all, which for a Thuug is saying something.",
			"So someone does listen, he thinks, and something in his old chest goes warm. All those years, praying to whoever was there. And someone was.",
			"Then, more slowly: but who prays to a stone with a crown on it?",
		],
		"replies": [
			{"tags": ["Pious"], "t": "We should not break this. Not without a prayer first.",
				"after": [{"s": "joss", "t": "Make it a short one."},
					{"n": "Ommuk prays, slowly, as Thuugs do. Tikkat groans. Joss watches the sun climb."}]},
			{"tags": ["Calm"], "t": "Let the stone be warm. We do the job, and we do it gently.",
				"after": [{"n": "They take the shrine apart stone by stone. Ommuk lifts the crowned head clear before the rest falls, and sets it carefully in the grass."}]},
			{"tags": ["Generous"], "t": "Whatever we are paid for this, my share goes to the next temple we pass.",
				"after": [{"s": "joss", "t": "Ha! Your share, your loss."},
					{"n": "Joss laughs. Ithrae doesn't."}]},
			{"tags": [], "t": "Joss, do you feel nothing? Nothing at all?",
				"after": [{"s": "joss", "t": "Nothing. Now pick up a crowbar."},
					{"n": "He answers too quickly. Even Tikkat notices."}]},
		],
	},
	"ithrae": {
		"inner": [
			"The warmth of the stone floods up Ithrae's arm and into her head, and for a moment she cannot see her own hand.",
			"Then the hall of light, and the bowing crowd, and something under it all that makes her want to weep. Not fear. Grief. Old grief, older than she is, and it feels like it belongs to her.",
			"Why does it feel like coming home, she thinks, and like a wound?",
		],
		"replies": [
			{"tags": ["Honest"], "t": "There's something in my head, Joss. I'm not joking. It came from the stone.",
				"after": [{"s": "tikkat", "t": "Haunted! I said it was haunted!"},
					{"s": "ommuk", "t": "You said it was silver."},
					{"s": "joss", "t": "Then we break it fast. Ithrae, stand back."},
					{"n": "Nobody looks at Ithrae quite the same way for the rest of the day."}]},
			{"tags": ["Curious"], "t": "Give me a moment with it before you break it. I need to understand this.",
				"after": [{"n": "Ithrae traces the worn letters at the figure's feet and copies them into her book. Most of the words are gone. One of them might be a name."}]},
			{"tags": ["Melancholy"], "t": "It doesn't matter. Break it. Nothing that old should still be warm.",
				"after": [{"n": "The job goes on. Ithrae does not say another word until they reach Lehan."}]},
			{"tags": [], "t": "I'm fine. It's the cold.",
				"after": [{"n": "It is a lie, and lies come hard to her. Somewhere behind her eyes, something takes note."}]},
		],
	},
	"tikkat": {
		"inner": [
			"Tikkat's whiskers go flat against his face. Every hair on his body stands up at once.",
			"Nope, he thinks. Nope, nope, nope. Haunted stone. Haunted rat. Haunted everything.",
			"But the hall in the vision was full of gold, wasn't it? Floors of it. And a little voice that isn't quite his own suggests that a thing which shows you gold might know where more is.",
		],
		"replies": [
			{"tags": ["Cowardly"], "t": "Smash it quick and let's go. Quick quick. I don't like it here.",
				"after": [{"n": "Tikkat swings his pick like someone possessed, which, he will later think, is not a funny way to put it."},
					{"n": "He looks over his shoulder all the way to Lehan."}]},
			{"tags": ["Greedy"], "t": "Wait, wait. What if there's something buried under it? Old shrines have offerings.",
				"after": [{"n": "They dig. Under the base lies a handful of coins, green with age, stamped with a crowned head. Nobody has seen their like."},
					{"s": "joss", "t": "Into the common purse, Tikkat."},
					{"s": "tikkat", "t": "Obviously. Obviously."}]},
			{"tags": ["Cheerful"], "t": "Haunted shrine, warm rocks, mystery tracks. Best job we've had all year!",
				"after": [{"n": "Maera laughs despite herself. Even Ommuk smiles. The work goes quickly after that."}]},
			{"tags": [], "t": "Did... did anyone else just see a lot of gold?",
				"after": [{"s": "joss", "t": "Lay off the wine, Tikkat."},
					{"n": "Tikkat decides to keep the next vision to himself."}]},
		],
	},
}
