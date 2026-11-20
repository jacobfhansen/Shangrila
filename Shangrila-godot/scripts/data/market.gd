class_name MarketData
extends RefCounted
## Who stands in Lehan's streets and market square (LehanStreets) and what they say. Lisbet, Skee
## and Boddo are the hooks for the Lehan quests (LehanQuests, LisbetQuest, BoddoQuest, SkeeQuest).

## Map digit -> person. `look` drives FigureArt and the dialogue portrait (RacePortrait).
const PEOPLE := {
	"1": {"key": "crier", "name": "Odo the Crier", "race": "Human", "height": 1.75,
		"look": {"skin": "#e0b890", "hair": "#6a5a4a", "cloth": "#2a4a7a", "legs": "#3a3a3a", "hat": true}},
	"2": {"key": "lisbet", "name": "Lisbet Farrow", "race": "Human", "height": 1.6,
		"look": {"skin": "#f0c8a8", "hair": "#c09040", "cloth": "#7a3a5a", "legs": "#4a3040"}},
	"3": {"key": "skee", "name": "Skee", "race": "Nisk", "height": 1.25,
		"look": {"skin": "#9a8a70", "cloth": "#4a5a3a", "legs": "#3a3028"}},
	"4": {"key": "boddo", "name": "Boddo", "race": "Thuug", "height": 1.6,
		"look": {"skin": "#7a8a5a", "shell": "#6a5236", "cloth": "#8a7050"}},
	"5": {"key": "wenna", "name": "Old Wenna", "race": "Human", "height": 1.5,
		"look": {"skin": "#d8b090", "hair": "#d8d8d0", "cloth": "#6a5a4a", "legs": "#4a3a2a", "apron": true, "hood": true}},
	"6": {"key": "siv", "name": "Siv the Herb Seller", "race": "Aeldroe", "height": 1.8,
		"look": {"skin": "#e0eaf0", "hair": "#c8e0d0", "cloth": "#3a6a5a", "legs": "#2a4a40"}},
	"7": {"key": "guard", "name": "Sergeant Rudd", "race": "Human", "height": 1.8,
		"look": {"skin": "#c89870", "hair": "#2a2018", "cloth": "#7a2a20", "legs": "#3a3a40", "hat": true, "beard": true}},
	"8": {"key": "hal", "name": "Hal Venner", "race": "Human", "height": 1.8,
		"look": {"skin": "#d8a880", "hair": "#4a3020", "cloth": "#5a4a3a", "legs": "#3a3028"}},
}


## The dialogue cast: the company plus everyone in the square.
static func cast() -> Dictionary:
	var c := PrologueData.company_cast()
	for k in PEOPLE:
		var p: Dictionary = PEOPLE[k]
		c[p.key] = {"name": p.name, "race": p.race, "look": p.look}
	return c


static func _host_first(host: String) -> String:
	return PrologueData.CAST[host].name.split(" ")[0] if PrologueData.CAST.has(host) else "friend"


## The conversation with the person on map digit `id`. Effects: "notice" (the crier's notice puts
## the council house on the town map and points out the smith; the job itself is taken at the
## council, see CouncilData).
static func talk(id: String, host: String) -> Array:
	var who: String = PEOPLE[id].key
	var h := _host_first(host)
	match who:
		"crier":
			if not LehanData.has_job() and not LehanQuests.any_done():
				return [
					{"s": "crier", "t": "No council news today, friend. The price of eggs, a lost goat, and the Widow Marl's opinion of the price of eggs."},
					{"s": "crier", "t": "If it's work you're after, ask Lisbet there by the stalls. She hears everything a day before I cry it."},
					{"n": "(Something has to happen before the story moves on. Lisbet, Skee and Boddo in the square each have something for you to do.)"},
				]
			if not LehanData.has_job():
				return [
					{"s": "crier", "t": "Hear ye! A notice from the council of Lehan!"},
					{"s": "crier", "t": "Miners have gone missing in the old workings above the town. Six good men, and not a word from them in nine days."},
					{"s": "crier", "t": "The council will pay well for anyone willing to look into it. Ask at the council house, there on the north side of the square."},
					{"s": host, "t": "Paid work. Finally."},
					{"fx": "notice", "wait": 0.1},
					{"n": "(The Council House is now on the town map. Your old companions at the inn may listen now that there is a job. Across the square hangs the sign of a weapon smith: the Weapon Smith is on the town map too.)"},
				]
			if not CouncilData.accepted():
				return [
					{"s": "crier", "t": "The council's notice stands: miners missing in the old workings above the town. Ask at the council house."},
					{"s": "crier", "t": "Bring friends when you go in. The council haggles harder with a lone sword."},
				]
			return [
				{"s": "crier", "t": "The council's notice stands: miners missing in the old workings above the town. The council pays well."},
				{"s": "crier", "t": "If you go up there, buy a good blade first. The smith across the square won't mind me saying so."},
			]
		"lisbet":
			return LisbetQuest.talk()
		"skee":
			return SkeeQuest.talk()
		"boddo":
			return BoddoQuest.talk()
		"wenna":
			var out: Array = []
			if Game.story.get("employer", "") != "":
				out = [
					{"s": "wenna", "t": "You came from Tanners' Row, didn't you? I saw you go in at the narrow house."},
					{"s": "wenna", "t": "That grey-coated fellow left at dawn. A packed cart and a hurry. Nobody in Lehan knows his name, and I know everybody's name."},
				]
			if LehanData.has_job() and not Game.mines_entered():
				out.push_front({"s": "wenna", "t": "Still here? I thought you lot were for the mines. Six men up there, and you're buying eggs."})
			if not out.is_empty():
				return out
			return [
				{"s": "wenna", "t": "Forty years I've sold eggs in this square, and I've never seen the council so frightened. Six miners gone."},
			]
		"guard":
			if LehanQuests.get_q("lisbet") == "carrying":
				return LisbetQuest.deliver()
			if Game.story.get("employer", "") == "":
				return [{"s": "guard", "t": "Keep your blades sheathed inside the walls, and we'll get along fine."}]
			return [
				{"s": "guard", "t": "Still in town? Most of your sort move on once the money's spent."},
				{"s": "guard", "t": "The grey-coat on Tanners' Row went out through this gate at dawn. Headed north, with a cart. Not my business where."},
			]
		"hal":
			return MinesQuest.hal_talk()
		"siv":
			return [
				{"s": "siv", "t": "Alnon leaf, fresh from the marsh. The smith sells you steel to make holes. I sell what closes them."},
				{"s": "siv", "t": "Come back with silver. One day I will have a proper stall."},
			]
	return []
