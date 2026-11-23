extends Node
## Global game state and rules. Started as a port of Shangrila.p / ShangrilaUtils.p (1997); the
## character rules are now the simpler ones in IDEAS.md: ten abilities from 0 to 10, silver only.

var SAVE_PREFIX := "user://save"   # + "_1.json" .. "_3.json", "_auto.json"; the dev tour uses its own (main.gd)
const OLD_SAVE := "user://shangrila_save.json"   # the single save before slots: becomes slot 1
const SAVE_SLOTS := 3
const REST_DAYS := 2       # a badly wounded companion rests this many days at the inn
const REST_PRICE := 3      # silver a day
const INN_NIGHT := 1       # silver a head for the party's night at the inn

const RACES := ["Human", "Thuug", "Aeldroe", "Nisk"]
enum { HUMAN, THUUG, AELDROE, NISK }
const RACE_INFO := [
	"Humans: adaptable and quick to learn. +1 in a favoured ability, raises cost 10% less.",
	"Thuugs: slow, turtle-like folk. +1 Toughness, the shell gives +1 armour, but they act late.",
	"Aeldroes: slim, half-transparent beings. +1 Magic, +2 Stealth in the dark, but frail.",
	"Nisk: quick, wiry rat-folk. +1 Stealth, natural climbers with a keen nose.",
]
## Saves before version 2 used the original 1997 races; map them onto the new ones.
const OLD_RACE_MAP := [THUUG, AELDROE, HUMAN, NISK, HUMAN]  # Dwarf, Elf, Half Elf, Halfling, Human

const CLASSES := ["Cleric", "Enchanter", "Mage", "Monk", "Paladin", "Ranger", "Thief", "Warrior"]
enum { CLERIC, ENCHANTER, MAGE, MONK, PALADIN, RANGER, THIEF, WARRIOR }
const NO_CLASS := -1

## The ten abilities, 0 (untrained) to 10 (legendary). Checks: d10 + ability against a
## difficulty (EASY, NORMAL, HARD).
const ABILITIES := ["combat", "missile", "toughness", "stealth", "thievery", "perception",
	"survival", "lore", "magic", "talk"]
const ABILITY_NAMES := {
	"combat": "Combat", "missile": "Missile Weapons", "toughness": "Toughness", "stealth": "Stealth",
	"thievery": "Thievery", "perception": "Perception", "survival": "Survival", "lore": "Lore",
	"magic": "Magic", "talk": "Talk",
}
const ABILITY_INFO := {
	"combat": "Melee hits, parrying and dodging blows.",
	"missile": "Bows and thrown weapons.",
	"toughness": "Hit points, carrying, resisting poison and fear.",
	"stealth": "Hiding, sneaking and slipping away.",
	"thievery": "Locks, traps and pockets. Needs at least 1.",
	"perception": "Spotting and noticing things, and acting first in a fight.",
	"survival": "Foraging, tracking and climbing.",
	"lore": "Herbs, first aid, reading and judging what things are worth.",
	"magic": "Spells and mana. Casting needs at least 1.",
	"talk": "Haggling and persuading.",
}
const MAX_ABILITY := 10
const EASY := 6
const NORMAL := 9
const HARD := 12

## Abilities a class makes cheaper to raise. The first one gets the Human +1.
const FAVOURED := {
	CLERIC: ["magic", "lore", "combat", "toughness"],
	ENCHANTER: ["magic", "talk", "lore"],
	MAGE: ["magic", "lore", "perception"],
	MONK: ["combat", "toughness", "stealth"],
	PALADIN: ["combat", "toughness", "magic", "talk"],
	RANGER: ["missile", "survival", "perception", "combat"],
	THIEF: ["stealth", "thievery", "perception", "talk"],
	WARRIOR: ["combat", "toughness", "missile"],
}
## What a character of each class starts with, before the race bonus.
const CLASS_START := {
	CLERIC: {"magic": 1, "lore": 1, "combat": 1},
	ENCHANTER: {"magic": 1, "talk": 1},
	MAGE: {"magic": 1, "lore": 1},
	MONK: {"combat": 1, "toughness": 1},
	PALADIN: {"combat": 1, "toughness": 1},
	RANGER: {"missile": 1, "survival": 1},
	THIEF: {"stealth": 1, "thievery": 1},
	WARRIOR: {"combat": 1, "toughness": 1},
}
const RACE_ABILITY := ["", "toughness", "magic", "stealth"]   # Humans: the class's first favoured
const RACE_HITS := [10, 13, 7, 9]

const MAX_ROSTER := 23
const MAX_PARTY := 6
const PORTRAITS := 32
const PORTRAIT_CAST := 100   # icons from here on are the pre-made characters (RacePortrait)

## Equipment slot numbers are the same as in the original (Items[1..30]).
const SLOT_HEAD := 1
const SLOT_NECK := 2
const SLOT_CHEST := 3
const SLOT_ARMS := 4
const SLOT_BELT := 5
const SLOT_RHAND := 6
const SLOT_LHAND := 7
const SLOT_LEGS := 8
const SLOT_FEET := 9
const PACK_FIRST := 10
const PACK_LAST := 27
const SLOT_RFINGER := 28
const SLOT_LFINGER := 29
const SLOT_QUIVER := 30

const DIR_NAMES := ["North", "East", "South", "West"]
const DIR_LETTERS := ["N", "E", "S", "W"]
const DIR_VEC := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

## World map. `at` is the position on assets/world_map.png (600x370). `screen` is entered on
## arrival. `kind` is "city" (can be found by travelling near it) or "dungeon" / "plot" (only
## through rumours, clues or exits).
const LOCATIONS := {
	"shrine": {"name": "The Old Shrine", "kind": "ruin", "at": Vector2(168, 292), "screen": "",
		"desc": "A roadside shrine, long hidden under brambles. Only rubble is left."},
	"lehan": {"name": "Lehan", "kind": "city", "at": Vector2(236, 252), "screen": "streets",
		"desc": "A walled town with an inn and a weapon smith."},
	"mines": {"name": "The Mines", "kind": "dungeon", "at": Vector2(292, 200), "screen": "dungeon",
		"desc": "Old mine workings in the hills above Lehan."},
	"marsh_shrine": {"name": "The Drowned Shrine", "kind": "plot", "at": Vector2(424, 300), "screen": "village",
		"desc": "Oggal, a Thuug stilt village on the causeways of the marshes, and beyond it an old shrine half sunk in black water. The jailers' record says they drowned something of the spirit's there."},
	"aubermont": {"name": "Aubermont", "kind": "capital", "at": Vector2(205, 92), "screen": "",
		"desc": "The great city of the north, dark stone on four hills above the mouth of the Aube. The old founding families live there, in their houses on the highest hill. Something of the spirit's lies there, behind iron."},
}
## Town maps. Places appear on them as they are discovered; `start` are known on arrival.
## `at` is the position on the town image (600x370, made by tools/make_textures.py).
const TOWNS := {
	"lehan": {"name": "Lehan", "image": "town_lehan", "start": ["gate", "market", "inn"], "places": {
		"gate": {"name": "South Gate", "kind": "gate", "at": Vector2(300, 336),
			"desc": "The road leads out into the land."},
		"market": {"name": "Market Square", "kind": "market", "at": Vector2(300, 178),
			"desc": "Stalls, a well, and a crier with the council's notices."},
		"inn": {"name": "The Inn", "kind": "inn", "at": Vector2(432, 232),
			"desc": "Beds, ale, and people looking for work or company."},
		"smith": {"name": "Weapon Smith", "kind": "smith", "at": Vector2(176, 132),
			"desc": "Blades, bows and armour, at Lehan prices."},
		"hideout": {"name": "The Employer's House", "kind": "house", "at": Vector2(160, 272),
			"desc": "A narrow, plain house off Tanners' Row, where the company was paid."},
		"warehouse": {"name": "Gell's Warehouse", "kind": "warehouse", "at": Vector2(150, 190),
			"desc": "Master Gell's warehouse, where the smith's street meets the square."},
		"tannery": {"name": "The Tannery", "kind": "tannery", "at": Vector2(200, 300),
			"desc": "A stinking tannery on Tanners' Row, with old cellar steps under an iron grate."},
		"council": {"name": "Council House", "kind": "council", "at": Vector2(300, 96),
			"desc": "A stone hall on the north side of the square, where the town's council sits."},
	}},
}

## Routes between locations, with the number of days on the road.
const ROUTES := [["lehan", "mines", 1], ["shrine", "lehan", 1], ["lehan", "marsh_shrine", 3], ["lehan", "aubermont", 4]]
## Endurance each character uses per day of travel (food is what refills it).
const TRAVEL_COST := 20      # Endurance a day on the road: three days take most of a full bar
const RATIONS := [50, 51, 30]   # what is eaten on the road, in this order: bread, dried fish, cheese
const FOOD_PRICES := {50: 1, 51: 2}   # provisions at the inn

var main: Node            # set by main.gd, used for modal dialogs
var items := {}           # id -> item dictionary (templates, never mutated)
var city := {}

var roster: Array = []    # "Mob" - characters waiting at the inn
var party: Array = []     # up to 6 characters
var visited := {}         # Vector3i(x, y, level) -> true: the squares of the mines seen so far
var site := "mines"       # which dungeon the dungeon screen shows: "mines" or "shrine" (area_script)
var mine_level := 1       # the level of that dungeon the party is on (see MinesArea, ShrineArea)
var pos := MinesArea.START   # the party's square on that level
var facing := 0           # 0 N, 1 E, 2 S, 3 W
var location := "lehan"   # key in LOCATIONS: where the party is on the world map
var known: Array = ["lehan", "mines"]   # discovered locations
var story := {}           # story state, e.g. {"host": "ithrae", "prologue_reply": 0}
var town_known := {}      # town key -> [discovered place keys]
var day := 1              # the day count: travel, nights' sleep and rest days move it on

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_make_items()
	_make_world()
	new_game()
	if FileAccess.file_exists(OLD_SAVE) and not FileAccess.file_exists(slot_path(1)):
		DirAccess.rename_absolute(OLD_SAVE, slot_path(1))


func my_random(lo: int, hi: int) -> int:
	return rng.randi_range(lo, hi)


# ---------------------------------------------------------------- items

func _it(id: int, nm: String, shape: String, col: String, weight: int, price: int, props := {}, desc := "") -> void:
	var it := {
		"id": id, "name": nm, "shape": shape, "col": Color(col), "weight": weight, "price": price,
		"defense": 0, "attack": 0, "damage": 0, "desc": desc,
		"head": false, "neck": false, "chest": false, "arms": false, "belt": false, "legs": false,
		"feet": false, "quiver": false, "rfinger": false, "lfinger": false,
		"axe": false, "blunt": false, "bow": false, "dagger": false, "unarm": false, "pole": false,
		"sword": false, "throw": false,
		"armor": false, "weapon": false, "gun": false, "dims": false, "misil": false, "food": false,
		"hits": [0, 0], "health": [0, 0], "magic": [0, 0], "dmg": [0, 0],
	}
	it.merge(props, true)
	items[id] = it


func _make_items() -> void:
	# Same pool as InitData. Prices are in silver (the original's copper prices were mostly
	# placeholders of 111).
	_it(2, "Red Shirt", "shirt", "#b02a20", 20, 1, {"armor": true, "chest": true}, "A plain shirt of red linen.")
	_it(3, "Longsword", "sword", "#d0d4dc", 60, 15, {"dmg": [2, 7], "weapon": true, "sword": true}, "A fine straight blade, balanced for one hand.")
	_it(4, "Iron Helmet", "helmet", "#8a8f99", 45, 6, {"armor": true, "head": true, "defense": 2}, "Dented, but it has saved a skull or two.")
	_it(5, "Small Sack", "sack", "#a08050", 5, 1, {"dims": true}, "Holds a few odds and ends.")
	_it(6, "Heavy Robe", "robe", "#5a4a7a", 50, 3, {"armor": true, "chest": true, "defense": 1}, "Thick wool, warm in cold halls.")
	_it(7, "Heavy Boots", "boots", "#5a3a20", 60, 3, {"armor": true, "feet": true, "defense": 1}, "Iron-shod boots for long marches.")
	_it(8, "Sandals", "sandals", "#b08850", 10, 1, {"armor": true, "feet": true}, "Light and cool, little protection.")
	_it(9, "Leather Pants", "pants", "#7a5030", 20, 2, {"armor": true, "legs": true, "defense": 1}, "Supple boiled leather.")
	_it(10, "Leather Armor", "armor", "#8a5a30", 200, 12, {"armor": true, "chest": true, "defense": 3}, "A studded leather jerkin.")
	_it(11, "Longbow", "bow", "#8a6030", 50, 25, {"dmg": [1, 6], "gun": true, "bow": true}, "Tall yew bow. Needs arrows.")
	_it(12, "Quiver", "quiver", "#6a4020", 30, 2, {"dims": true, "quiver": true}, "A leather quiver for arrows.")
	_it(13, "Arrows", "arrow", "#c0a070", 2, 1, {"misil": true, "quiver": true}, "A bundle of goose-feathered, iron-tipped arrows. Most can be picked up again after a fight.")
	_it(14, "Mace", "mace", "#9aa0aa", 50, 8, {"dmg": [2, 5], "weapon": true, "blunt": true}, "A flanged iron head on an ash haft.")
	_it(15, "Wooden Shield", "shield", "#8a6234", 30, 4, {"armor": true, "defense": 1}, "Oak planks bound with iron.")
	_it(16, "Dark Pants", "pants", "#2a2a35", 20, 1, {"armor": true, "legs": true}, "Dark cloth trousers.")
	_it(17, "Yellow Robe", "robe", "#c8a020", 40, 3, {"armor": true, "chest": true}, "The saffron robe of a monk.")
	_it(18, "Staff", "staff", "#7a5530", 50, 1, {"dmg": [1, 4], "weapon": true, "blunt": true}, "A sturdy walking staff.")
	_it(19, "Spell Book", "book", "#5a2030", 100, 10, {"dims": true}, "Pages full of crabbed arcane script.")
	_it(20, "Magicuser Hat", "hat", "#30307a", 15, 2, {"armor": true, "head": true}, "Tall, pointed and starry.")
	_it(21, "Holy Symbol", "symbol", "#d4a830", 10, 5, {"neck": true, "dims": true}, "Blessed by the temple priests.")
	_it(22, "Holy Water", "flask", "#80b0e0", 20, 3, {"dims": true}, "A vial of blessed water.")
	_it(23, "First Aid Kit", "kit", "#e8e0d0", 100, 5, {"dims": true}, "Bandages, salves and a needle.")
	_it(24, "Lockpick Kit", "lockpick", "#6a4a2a", 100, 5, {"dims": true}, "Picks and tension tools. Not strictly legal.")
	_it(25, "Shoes", "shoes", "#4a3020", 25, 2, {"armor": true, "feet": true}, "Soft leather shoes.")
	_it(26, "Wood Axe", "axe", "#9aa0aa", 50, 3, {"dmg": [1, 6], "weapon": true, "axe": true}, "Meant for trees, works on other things.")
	_it(27, "Rope", "rope", "#c0a060", 50, 2, {"dims": true}, "Fifty feet of hemp rope.")
	_it(28, "Alnon Leaf", "leaf", "#40a040", 1, 2, {"dims": true, "food": true, "health": [10, 30]}, "A healing herb. Chew it.")
	_it(29, "Alman Root", "root", "#a07040", 1, 2, {"dims": true, "food": true, "hits": [1, 4]}, "Bitter root that closes wounds.")
	_it(30, "Cheese", "cheese", "#e8c040", 15, 1, {"dims": true, "food": true, "health": [20, 25]}, "A good wedge of hard cheese.")
	_it(31, "Clasp Knife", "knife", "#c8ccd4", 5, 2, {"dmg": [1, 3], "weapon": true, "dagger": true}, "A folding knife.")
	_it(32, "Bardiche", "bardiche", "#a0a6b0", 125, 12, {"dmg": [2, 8], "weapon": true, "axe": true}, "A long-hafted axe with a crescent blade.")
	_it(33, "Crowned Head", "stonehead", "#a8a090", 150, 0, {"dims": true, "quest": true}, "The stone head from the old shrine. Its face is worn smooth, but the crown is still clear, and it is faintly warm.")
	# Quest items (★): they can't be thrown away or sold, and stay in the party (see
	# LehanQuests.sync_items, which hands them out and takes them back as the quests move on).
	_it(34, "Lisbet's Letter", "letter", "#e8dcc0", 1, 0, {"dims": true, "quest": true},
		"A folded letter for Sergeant Rudd at the south gate, closed with a plain red seal. Nobody follows you. Nobody opens it.")
	_it(35, "Tam's Page", "page", "#e0d0a8", 1, 0, {"dims": true, "quest": true,
		"text": "\"Tam Reed, porter: fourteen weeks.\" A line through it, and in another ink: \"Died. No claim.\" Below, the same sum, paid to \"O. G.\""},
		"A page torn from Master Gell's wage book: the proof of what was done to Tam Reed.")
	_it(36, "Skee's Bag", "bag", "#6a5030", 10, 0, {"dims": true, "quest": true},
		"A leather bag, half chewed by rats. Rat traps, a sling and a little carved charm against ghosts. A rat's head is burned into the flap.")
	_it(37, "Glowing Shard", "chip", "#7aa8f0", 1, 0, {"dims": true, "quest": true},
		"A shard from the broken figure in the tunnels under Lehan. It stays faintly blue, and cold, like the light in the chamber.")
	# The mines (see MinesArea and MinesQuest): miners' kit, the foreman's stores, the jailers' arms.
	_it(38, "Miner's Pick", "pick", "#9aa0aa", 70, 6, {"dmg": [1, 6], "weapon": true, "axe": true},
		"A heavy pick with a worn ash handle. Made for rock, but it bites anything. Ore can be chipped out with it.")
	_it(39, "Leather Cap", "cap", "#7a5030", 15, 2, {"armor": true, "head": true, "defense": 1},
		"A miner's padded leather cap, good against low ceilings and falling stones.")
	_it(40, "Miner's Lamp", "lamp", "#c8a040", 20, 4, {"dims": true},
		"A brass lamp with a shielded flame. In bad air the flame shrinks and turns blue, long before you feel it.")
	_it(41, "Foreman's Key", "key", "#a08850", 1, 0, {"dims": true, "quest": true},
		"An iron key on a leather thong, taken from the foreman's belt at the breach.")
	_it(42, "Lift Crank", "crank", "#6a6a70", 40, 0, {"dims": true, "quest": true},
		"The iron crank for the lift's winding drum, kept in the foreman's stores.")
	_it(43, "Silver-Grey Ore", "ore", "#a8a8b8", 30, 12, {"dims": true},
		"A lump of ore from the new diggings, heavy and glittering. The smith in Lehan pays well for it.")
	_it(44, "Steel Sword", "sword", "#e0e4ec", 55, 30, {"dmg": [2, 8], "weapon": true, "sword": true, "attack": 1},
		"Good steel from the foreman's stores, better than anything the smith in Lehan sells.")
	_it(45, "Steel Cap", "helmet", "#b0b4bc", 35, 12, {"armor": true, "head": true, "defense": 2},
		"A close-fitting steel cap, made for the miners who dig where the rock is loose.")
	_it(46, "Jailer's Blade", "sword", "#a0b0c8", 60, 40, {"dmg": [2, 8], "weapon": true, "sword": true, "attack": 1, "bane": "oath"},
		"An old blade from the jailers' armoury. It bites deeper into their oath-bound dead. It is cold, and the host does not like to hold it.")
	_it(47, "Ward-Etched Shield", "shield", "#8a90a0", 45, 30, {"armor": true, "defense": 2},
		"A shield etched with old warding lines. Cold to the touch; the host would rather not carry it.")
	_it(48, "Holm Seal", "seal", "#b08840", 1, 0, {"dims": true, "quest": true,
		"text": "A heavy signet: a tower within a ring of chain. Around it, worn small: \"WE HOLD\"."},
		"A signet ring from the jailers' armoury in the sealed galleries. The mark of one of Lehan's old families.")
	_it(49, "Jailer's Record", "page", "#d8c8a0", 2, 0, {"dims": true, "quest": true,
		"text": "\"...the body we sealed below, and set the Warden at the gate. Iron and oath will hold it: no blade of ours can harm the Warden, nor any blade while the pieces of the tyrant still sleep apart. The second piece we took to the marsh-folk's causeway and drowned it at the old shrine, where the water never clears...\""},
		"A brittle page from the jailers' armoury, in an old hand.")
	_it(50, "Bread", "bread", "#c89050", 10, 1, {"dims": true, "food": true, "health": [25, 30]},
		"A dark travel loaf. Keeps for a week, tastes of it.")
	_it(51, "Dried Fish", "fish", "#b0a080", 8, 2, {"dims": true, "food": true, "health": [30, 40]},
		"Salted and dried on the marsh racks. Chewy, filling.")
	_it(52, "Bog-Iron Spear", "spear", "#5a5a60", 55, 14, {"dmg": [2, 7], "weapon": true, "pole": true},
		"Dark marsh iron on an ash shaft. Heavy, and it never quite rusts.")
	_it(53, "Shell Shield", "shield", "#6a7a4a", 30, 10, {"armor": true, "defense": 2},
		"Overlapping plates of river-turtle shell on a wicker frame. Light and tough.")
	# The Drowned Shrine's sigils, which open its sunken door (ShrineQuest).
	_it(54, "Crown Sigil", "sigil_crown", "#4a4c48", 3, 0, {"dims": true, "quest": true},
		"A disc of dark stone as wide as a hand, carved with a crown. Found in the shrine grounds.")
	_it(55, "Chain Sigil", "sigil_chain", "#4a4c48", 3, 0, {"dims": true, "quest": true},
		"A disc of dark stone as wide as a hand, carved with a chain. Found in the shrine grounds.")
	_it(56, "Wave Sigil", "sigil_wave", "#4a4c48", 3, 0, {"dims": true, "quest": true},
		"A disc of dark stone as wide as a hand, carved with waves. Found in the shrine grounds.")


func item(id: int) -> Dictionary:
	return items.get(id, {})


func _make_world() -> void:
	# World[1] 'Lehan', Shops[2] (weapon smith). Duplicated longswords are as in the original.
	city = {
		"name": "Lehan",
		"shop": {"name": "Weapon Smith", "price_mod": 1.0, "stock": [3, 14, 26, 18, 11, 12, 13, 31, 3, 3, 3, 32]},
	}


# ---------------------------------------------------------------- characters

func blank_character() -> Dictionary:
	var it := []
	it.resize(31)
	it.fill(0)
	var ab := {}
	for k in ABILITIES:
		ab[k] = 0
	return {
		"name": "", "icon": 2, "race": HUMAN, "cls": NO_CLASS,
		"max_health": 0, "health": 0, "max_hits": 0, "hits": 0, "max_magic": 0, "magic": 0,
		"abilities": ab, "max_encum": 0, "xp": 0, "xp_total": 0, "tactic": "", "silver": 0, "items": it,
		"counts": it.duplicate(),
	}


func ability(c: Dictionary, key: String) -> int:
	return c.get("abilities", {}).get(key, 0)


## A check: d10 + ability + bonus against a difficulty (EASY 6, NORMAL 9, HARD 12).
## A weakened character (out of Endurance) has −1.
func check(c: Dictionary, key: String, difficulty: int, bonus := 0) -> bool:
	return my_random(1, 10) + ability(c, key) + bonus - (1 if weakened(c) else 0) >= difficulty


## The chance of passing that check, in percent (10% for each face of the d10 that is enough).
func chance(c: Dictionary, key: String, difficulty: int, bonus := 0) -> int:
	var need := difficulty - ability(c, key) - bonus + (1 if weakened(c) else 0)
	return clampi(11 - need, 0, 10) * 10


## The starting abilities for a class and race (nobody starts above 2).
func start_abilities(cls: int, race: int) -> Dictionary:
	var ab := {}
	for k in ABILITIES:
		ab[k] = 0
	ab.merge(CLASS_START.get(cls, {}), true)
	var extra: String = RACE_ABILITY[race]
	if extra == "" and FAVOURED.has(cls):
		extra = FAVOURED[cls][0]
	if extra != "":
		ab[extra] = mini(ab[extra] + 1, 2)
	return ab


## A new character of the given class and race, ready to go.
func make_character(nm: String, cls: int, race: int, icon: int, abilities := {}) -> Dictionary:
	var c := blank_character()
	c.race = race
	c.icon = icon
	set_class(c, cls)
	c.abilities = abilities.duplicate() if not abilities.is_empty() else start_abilities(cls, race)
	for k in ABILITIES:
		if not c.abilities.has(k):
			c.abilities[k] = 0
	c["start_abilities"] = c.abilities.duplicate()
	c.silver = my_random(10, 20)
	finish_character(c, nm)
	c.hits = c.max_hits
	c.health = c.max_health
	c.magic = c.max_magic
	return c


func is_favoured(c: Dictionary, key: String) -> bool:
	return key in FAVOURED.get(c.cls, [])


## Experience needed to raise an ability by one: the new value x 100, or x 150 if the class
## does not favour it. Humans pay 10% less. -1 when it is already at the top.
func raise_cost(c: Dictionary, key: String) -> int:
	var to := ability(c, key) + 1
	if to > MAX_ABILITY:
		return -1
	var cost := to * (100 if is_favoured(c, key) else 150)
	if c.race == HUMAN:
		cost = cost * 9 / 10
	return cost


## True if the character has enough experience to raise some ability (the portraits' gold star).
func can_raise(c: Dictionary) -> bool:
	for k in ABILITIES:
		var cost := raise_cost(c, k)
		if cost >= 0 and c.xp >= cost:
			return true
	return false


func raise_ability(c: Dictionary, key: String) -> bool:
	var cost := raise_cost(c, key)
	if cost < 0 or c.xp < cost:
		return false
	c.xp -= cost
	c.abilities[key] += 1
	var hp_before: int = c.max_hits
	var mana_before: int = c.max_magic
	update_derived(c)
	c.hits += c.max_hits - hp_before
	c.magic += c.max_magic - mana_before
	return true


## The best of the fighting abilities (Combat, Missile Weapons, or Magic for casters).
func best_fighting(c: Dictionary) -> String:
	var best := "combat"
	for k in ["missile", "magic"]:
		if k == "magic" and spell_for(c).is_empty():
			continue
		if ability(c, k) > ability(c, best):
			best = k
	return best


## How far the character has come, to compare with a monster's level for experience: their best
## fighting ability + Toughness, + 1 for every 2 raises bought in the other abilities since they
## were made (so keeping Combat low to be paid more for fights doesn't pay; see IDEAS.md).
func power(c: Dictionary) -> int:
	return ability(c, best_fighting(c)) + ability(c, "toughness") + other_raises(c) / 2


## All the raises bought since the character was made (for Nerve: veterans keep their nerve).
func raises_bought(c: Dictionary) -> int:
	var start: Dictionary = c.get("start_abilities", {})
	var n := 0
	for k in ABILITIES:
		n += maxi(0, ability(c, k) - int(start.get(k, ability(c, k))))
	return n


## A companion has died: there is no raising the dead (IDEAS.md). They leave the party; what
## they carried goes to the others as far as their packs hold, their silver is shared. Returns
## the log lines.
func bury(c: Dictionary) -> Array:
	party.erase(c)
	var lines := ["%s is dead." % c.name]
	if not story.has("dead"):
		story["dead"] = []
	story.dead.append(c.name)
	if party.is_empty():
		return lines
	var left := []
	for s in range(1, c.items.size()):
		var id: int = c.items[s]
		if id == 0:
			continue
		var n := qty(c, s)
		for o in party:
			while n > 0 and pack_add(o, id):
				n -= 1
		if n > 0:
			left.append(item(id).name if n == 1 else "%d %s" % [n, item(id).name])
	var each: int = c.silver / party.size()
	for o in party:
		add_silver(o, each)
	lines.append("The others take what %s carried%s." % [c.name.split(" ")[0],
		"" if left.is_empty() else " (no room for: %s)" % ", ".join(left)])
	return lines


## Raises bought since the character was made in abilities other than their best fighting one
## and Toughness.
func other_raises(c: Dictionary) -> int:
	var start: Dictionary = c.get("start_abilities", {})
	var best := best_fighting(c)
	var n := 0
	for k in ABILITIES:
		if k != best and k != "toughness":
			n += maxi(0, ability(c, k) - int(start.get(k, ability(c, k))))
	return n


## One raise's worth of experience for this character (their next raise in their best fighting
## ability). Fights pay a small part of it, story moments a bigger one.
func raise_unit(c: Dictionary) -> int:
	return maxi(100, raise_cost(c, best_fighting(c)))


## Rounds a fraction up or down at random, so small amounts still add up on average.
func round_random(v: float) -> int:
	var whole := floori(v)
	return whole + (1 if rng.randf() < v - whole else 0)


## Experience earned: `xp` is what is left to spend, `xp_total` all that was ever earned.
func gain_xp(c: Dictionary, x: int) -> void:
	c.xp += x
	c["xp_total"] = int(c.get("xp_total", 0)) + x


## A character's abilities when made, for a save from before they were kept: the cast's, a
## recruit's, or the class's and race's.
func _guess_start_abilities(c: Dictionary) -> Dictionary:
	var start := {}
	for src in PrologueData.CAST.values() + LehanQuests.RECRUITS.values():
		if src.name == c.name:
			start = src.abilities.duplicate()
	if start.is_empty():
		start = start_abilities(c.cls, c.race)
	for k in ABILITIES:
		start[k] = mini(int(start.get(k, 0)), ability(c, k))
	return start


## For a save from before `xp_total` was kept: what is unspent plus what the raises bought since
## the character was made cost.
func _estimate_xp_total(c: Dictionary) -> int:
	var start: Dictionary = c.get("start_abilities", _guess_start_abilities(c))
	var spent := 0
	for k in ABILITIES:
		for to in range(int(start.get(k, 0)) + 1, ability(c, k) + 1):
			var cost := to * (100 if is_favoured(c, k) else 150)
			spent += cost * 9 / 10 if c.race == HUMAN else cost
	return c.xp + spent


## Story experience: everyone in the party gets `fraction` of a raise.
## R2 Insight, from the marsh remnant: the spirit sees its followers' natures, not only its host's.
func has_insight() -> bool:
	return story.get("insight", false)


## How many remnants the spirit has gathered (itself, the one woken at the roadside shrine, is 1).
func remnants() -> int:
	return story.get("remnants", 1)


## What the spirit can see of a character's nature: [text, tooltip]. The host's traits always; the
## others' only with Insight, which also shows their nerve and any grudge.
func nature_of(c: Dictionary) -> Array:
	var host: String = story.get("host", "")
	var is_host := host != "" and LehanQuests.key_of(c) == host
	var traits: Array = c.get("traits", [])
	if is_host:
		var tip := "The spirit lives inside its host, so it knows its host's nature."
		tip += "\nThe spirit has gathered %d remnant%s of itself%s." % [remnants(), "" if remnants() == 1 else "s",
			" (Insight: it sees the nature of everyone who follows it)" if has_insight() else ""]
		return ["Nature: " + ", ".join(traits), tip]
	if not has_insight():
		return ["Nature: hidden from the spirit", "The spirit can't see into anyone but its host yet: only what they say and do."]
	var n := Combat.base_nerve(c)
	var bits: Array = [", ".join(traits) if not traits.is_empty() else "nothing out of the ordinary"]
	bits.append("nerve %s" % ("shaky" if n <= 0 else "steady" if n <= 2 else "bold"))
	if str(c.get("grudge", "")) != "":
		bits.append("holds a grudge")
	return ["Nature: " + " · ".join(bits),
		"Insight: the spirit sees %s's nature.\nNerve %d: how well %s holds in a fight before anything goes wrong (class, traits and experience)." % [c.name.split(" ")[0], n, c.name.split(" ")[0]]
		+ ("\nA grudge from the split in Lehan, not yet forgotten." if str(c.get("grudge", "")) != "" else "")]


func story_xp(fraction: float) -> int:
	var total := 0
	for c in party:
		var x := roundi(raise_unit(c) * fraction)
		gain_xp(c, x)
		total = maxi(total, x)
	return total


## Hits when not badly wounded (max_hits is halved while wounded): what the bars and the sheet
## measure against, so a wounded character never looks fully healed.
func full_hits(c: Dictionary) -> int:
	return RACE_HITS[c.race] + 3 * ability(c, "toughness")


## Hit points, mana and carrying limit, from race and abilities.
func update_derived(c: Dictionary) -> void:
	c.max_hits = full_hits(c)
	if c.get("wounded", false):
		c.max_hits = ceili(c.max_hits / 2.0)   # badly wounded: until rested at the inn
	c.max_health = 70 + 10 * ability(c, "toughness")
	c.max_encum = 1200 + 150 * ability(c, "toughness")
	c.max_magic = 2 + 3 * ability(c, "magic") if not spell_for(c).is_empty() and ability(c, "magic") > 0 else 0
	c.hits = mini(c.hits, c.max_hits)
	c.health = mini(c.health, c.max_health)
	c.magic = mini(c.magic, c.max_magic)


const CLASS_ITEMS := {
	CLERIC: [14, 6, 8, 21, 22, 23],
	ENCHANTER: [2, 8, 16, 18, 19, 20],
	MAGE: [2, 8, 16, 18, 19, 20],
	MONK: [8, 5, 17, 27, 28, 29],
	PALADIN: [3, 4, 15, 10, 9, 7],
	RANGER: [11, 12, 13, 10, 9, 7],
	THIEF: [2, 31, 16, 24, 25, 27],
	WARRIOR: [3, 4, 15, 10, 9, 7],
}


func set_class(c: Dictionary, k: int) -> void:
	c.cls = k
	var list: Array = CLASS_ITEMS[k]
	for i in 6:
		set_slot(c, PACK_FIRST + i, list[i])
	equip_from_pack(c)


## Puts on what is in the pack: clothes and armour where they are worn, the first weapon in
## the right hand, a shield in the left, arrows in the quiver. Taken slots are left alone.
func equip_from_pack(c: Dictionary) -> void:
	for s in range(PACK_FIRST, PACK_LAST + 1):
		var id: int = c.items[s]
		if id == 0:
			continue
		var it := item(id)
		var dst := -1
		for slot in [SLOT_HEAD, SLOT_NECK, SLOT_CHEST, SLOT_ARMS, SLOT_BELT, SLOT_LEGS, SLOT_FEET]:
			if fits(id, slot) and c.items[slot] == 0:
				dst = slot
				break
		if dst < 0:
			if (it.weapon or it.gun) and c.items[SLOT_RHAND] == 0:
				dst = SLOT_RHAND
			elif it.armor and it.defense > 0 and c.items[SLOT_LHAND] == 0 and not (it.head or it.neck
					or it.chest or it.arms or it.belt or it.legs or it.feet):
				dst = SLOT_LHAND
			elif it.misil and c.items[SLOT_QUIVER] == 0:
				dst = SLOT_QUIVER
		if dst >= 0:
			set_slot(c, dst, id)
			take_from(c, s)


func finish_character(c: Dictionary, nm: String) -> void:
	c.name = nm
	update_derived(c)


func encumbrance(c: Dictionary) -> int:
	var e := 0
	for i in range(1, 31):
		if c.items[i] != 0:
			e += item(c.items[i]).weight * qty(c, i)
	return e + c.silver / 10


## Armour from what is worn (and a Thuug's shell).
func armor(c: Dictionary) -> int:
	var ac := 0
	if c.race == THUUG:
		ac += 1  # shell
	for i in [1, 2, 3, 4, 5, 8, 9]:
		if c.items[i] != 0:
			ac += item(c.items[i]).defense
	for i in [SLOT_RHAND, SLOT_LHAND]:
		if c.items[i] != 0:
			var it := item(c.items[i])
			# Only things that are not worn elsewhere (i.e. shields) count in the hands.
			if not (it.head or it.neck or it.chest or it.arms or it.belt or it.legs or it.feet):
				ac += it.defense
	return ac


## The ability used with the weapon in a hand: Missile Weapons for bows and thrown weapons.
func weapon_ability(c: Dictionary, slot: int) -> String:
	var id: int = c.items[slot]
	if id != 0 and (item(id).gun or item(id).throw):
		return "missile"
	return "combat"


## What the character adds to a d10 when attacking with the weapon in a hand.
func to_hit(c: Dictionary, slot: int) -> int:
	var id: int = c.items[slot]
	return ability(c, weapon_ability(c, slot)) + (item(id).attack if id != 0 else 0) - (1 if weakened(c) else 0)


## Out of Endurance (the apple bar): −1 on every check and to hit, until they eat.
func weakened(c: Dictionary) -> bool:
	return c.has("health") and c.has("max_health") and c.max_health > 0 and c.health <= 0


## Damage range of the weapon in a hand, as text for the View Character screen.
func damage_string(c: Dictionary, slot: int) -> String:
	var id: int = c.items[slot]
	if id == 0:
		return "1-4" if c.cls == MONK else "1-2"
	var d: Array = item(id).dmg
	return "-" if d[1] == 0 else "%d-%d" % [d[0], d[1]]


# ---------------------------------------------------------------- combat helpers (new)

## One spell per spell-casting class so far (more open up later as Magic rises: at 3, 5, ...).
## The 1997 game had no spells, only a "Spells" button and the Magic Arts skill.
const SPELLS := {
	MAGE: {"name": "Fire Dart", "cost": 2, "target": "enemy", "desc": "A bolt of flame that never misses."},
	ENCHANTER: {"name": "Slumber", "cost": 3, "target": "enemy", "desc": "Puts a whole group of foes to sleep."},
	CLERIC: {"name": "Mend", "cost": 2, "target": "ally", "desc": "Heals wounds and can raise the fallen."},
}

const TACTICS := {
	"attack": "Attack", "parry": "Parry", "spell": "Cast spell", "turn": "Turn undead",
	"hide": "Hide", "pass": "Pass",
}


## The class's spell, if the character has at least 1 in Magic.
func spell_for(c: Dictionary) -> Dictionary:
	if ability(c, "magic") < 1:
		return {}
	return SPELLS.get(c.cls, {})


func tactics_for(c: Dictionary) -> Array:
	var t := ["attack", "parry"]
	if not spell_for(c).is_empty():
		t.append("spell")
	if c.cls == CLERIC or c.cls == PALADIN:
		t.append("turn")
	t.append_array(["hide", "pass"])
	return t


## The default action used by the Defaults button and by auto-combat.
func tactic(c: Dictionary) -> String:
	var t: String = c.get("tactic", "")
	if t in tactics_for(c):
		return t
	return "spell" if not spell_for(c).is_empty() else "attack"


func add_silver(c: Dictionary, amount: int) -> void:
	c.silver = maxi(0, c.silver + amount)


## The map code of the current dungeon (MinesArea or ShrineArea: the same static API).
func area_script() -> GDScript:
	return ShrineArea if site == "shrine" else MinesArea


## Its story code (MinesQuest or ShrineQuest).
func quest_script() -> GDScript:
	return ShrineQuest if site == "shrine" else MinesQuest


## The level part of a visited square's key: each dungeon's levels get their own numbers.
func vz() -> int:
	return mine_level + (100 if site == "shrine" else 0)


## Back to the mines' own state (after leaving the shrine): their entrance, level 1.
func to_mines() -> void:
	site = "mines"
	mine_level = 1
	pos = MinesArea.START
	facing = MinesArea.START_FACING


## How deep in the mines the party is, for the wandering monsters (Combat.TIERS: depth / 7).
func depth() -> int:
	return (mine_level - 1) * 7 + 3


## Whether the party has been down the mines yet.
func mines_entered() -> bool:
	return story.get("mines_entered", false)


## The whole party fell: they wake at the last checkpoint (a camp in the mines, or the inn),
## robbed of half their coins and, after a deadly fight, badly wounded. Returns the screen.
func party_defeated(wounding := true) -> String:
	for c in party:
		if wounding:
			wound(c)
		c.hits = 1
		add_silver(c, -c.silver / 2)
	var cp: Dictionary = story.get("checkpoint", {})
	if cp.get("kind", "") == "camp":
		site = "mines"
		mine_level = int(cp.level)
		pos = Vector2i(int(cp.pos[0]), int(cp.pos[1]))
		facing = int(cp.facing)
		location = "mines"
		return "dungeon"
	to_mines()
	if cp.get("kind", "") == "village":
		location = "marsh_shrine"
		return "village"
	location = "lehan"
	return "inn"


## The words for where the party wakes after a wipe.
func checkpoint_name() -> String:
	var cp: Dictionary = story.get("checkpoint", {})
	if cp.get("kind", "") == "camp":
		return "by the camp's fire on level %d of the mines" % int(cp.level)
	if cp.get("kind", "") == "village":
		return "in the guest hut at Oggal"
	return "at the inn in %s" % city.name


## Reaching a checkpoint (a camp in the mines, the inn in town): the party wakes here after a wipe,
## and the game is saved in the automatic slot.
func reach_checkpoint(screen: String) -> bool:
	if screen == "dungeon":
		story["checkpoint"] = {"kind": "camp", "level": mine_level, "pos": [pos.x, pos.y], "facing": facing}
	elif screen == "village":
		story["checkpoint"] = {"kind": "village"}
	else:
		story["checkpoint"] = {"kind": "inn"}
	return save_game(screen, "auto")


# ---------------------------------------------------------------- wounds and days

## A severe wound (fell in a deadly fight and wasn't brought back up): hits can't rise above half
## until the character has rested at the inn (REST_DAYS days, REST_PRICE silver a day).
func wound(c: Dictionary) -> void:
	c["wounded"] = true
	update_derived(c)


func is_resting(c: Dictionary) -> bool:
	return int(c.get("rest_until", 0)) > 0


## Days left before a resting companion is fit again.
func rest_left(c: Dictionary) -> int:
	return maxi(0, int(c.get("rest_until", 0)) - day)


## Leaves a badly wounded companion at the inn to rest.
func start_rest(c: Dictionary) -> void:
	c["rest_until"] = day + REST_DAYS


## Days pass (travel, a night's sleep, waiting at the inn). Companions resting at the inn heal.
func pass_days(n: int) -> Array:
	day += n
	var lines := []
	for c in roster:
		if is_resting(c) and rest_left(c) == 0:
			c.erase("rest_until")
			c.erase("wounded")
			update_derived(c)
			c.hits = c.max_hits
			lines.append("%s has rested and is fit again." % c.name)
	return lines


## DoesItFit: can item from slot `src` be placed in slot `dst`?
func fits(id: int, dst: int) -> bool:
	var it := item(id)
	if it.is_empty():
		return false
	match dst:
		SLOT_HEAD: return it.head
		SLOT_NECK: return it.neck
		SLOT_CHEST: return it.chest
		SLOT_ARMS: return it.arms
		SLOT_BELT: return it.belt
		SLOT_RHAND, SLOT_LHAND: return true
		SLOT_LEGS: return it.legs
		SLOT_FEET: return it.feet
		SLOT_RFINGER: return it.rfinger
		SLOT_LFINGER: return it.lfinger
		SLOT_QUIVER: return it.quiver
	return dst >= PACK_FIRST and dst <= PACK_LAST


func is_quest_item(id: int) -> bool:
	return item(id).get("quest", false)


## Who carries an item, in the party or at the inn ({} if nobody).
func holder_of(id: int) -> Dictionary:
	for c in party + roster:
		if id in c.items:
			return c
	return {}


## A quest item for the party: into the first free pack slot, the host's first. If every pack is
## full, it takes the place of the host's last ordinary pack item (which is left behind).
func give_item(id: int, first: Dictionary = {}) -> Dictionary:
	if party.is_empty():
		return {}
	var order: Array = [first] if not first.is_empty() else []
	order.append_array(party)
	for c in order:
		if pack_add(c, id):
			return c
	var c: Dictionary = order[0]
	for s in range(PACK_LAST, PACK_FIRST - 1, -1):
		if not is_quest_item(c.items[s]):
			set_slot(c, s, id)
			return c
	return {}


## Takes an item away from whoever carries it (in the party or at the inn).
func take_item(id: int) -> void:
	for c in party + roster:
		for s in c.items.size():
			if c.items[s] == id:
				take_from(c, s)
				return


## A character is leaving the party: their quest items go to those who stay. False if nobody
## stays to take them (then the character should not leave).
func hand_over_quest_items(c: Dictionary) -> bool:
	var stay := party.filter(func(m): return m != c)
	var ids: Array = []
	for s in c.items.size():
		if is_quest_item(c.items[s]):
			ids.append(c.items[s])
	if ids.is_empty():
		return true
	if stay.is_empty():
		return false
	for id in ids:
		take_item(id)
		var to: Dictionary = stay[0]
		for m in stay:
			if free_pack_slot(m) >= 0:
				to = m
				break
		var s := free_pack_slot(to)
		if s < 0:
			for k in range(PACK_LAST, PACK_FIRST - 1, -1):
				if not is_quest_item(to.items[k]):
					s = k
					break
		if s >= 0:
			set_slot(to, s, id)
	return true


# ---------------------------------------------------------------- stacks
## A pack slot can hold a stack of the same item (anything but quest items, which are one of a
## kind): `c.counts[s]` is how many. Worn and held slots always hold one.

func _counts(c: Dictionary) -> Array:
	if not c.has("counts") or c.counts.size() < c.items.size():
		var a: Array = c.get("counts", [])
		a.resize(c.items.size())
		for i in a.size():
			if a[i] == null:
				a[i] = 0
		c["counts"] = a
	return c.counts


## How many are in a slot (0 if it is empty).
func qty(c: Dictionary, s: int) -> int:
	if c.items[s] == 0:
		return 0
	return maxi(1, int(_counts(c)[s]))


## Puts `n` of an item in a slot (0 empties it).
func set_slot(c: Dictionary, s: int, id: int, n := 1) -> void:
	c.items[s] = id
	_counts(c)[s] = n if id != 0 else 0


## Takes `n` out of a slot; the last one empties it.
func take_from(c: Dictionary, s: int, n := 1) -> void:
	var left := qty(c, s) - n
	if left <= 0:
		set_slot(c, s, 0, 0)
	else:
		_counts(c)[s] = left


func stacks(id: int) -> bool:
	return id != 0 and not is_quest_item(id)


## Where one more of an item would go in the pack: onto a stack of it, or a free slot (-1: full).
func pack_slot_for(c: Dictionary, id: int) -> int:
	if stacks(id):
		for i in range(PACK_FIRST, PACK_LAST + 1):
			if c.items[i] == id:
				return i
	return free_pack_slot(c)


## Puts `n` of an item into the pack (stacked if it can be). False if there is no room.
func pack_add(c: Dictionary, id: int, n := 1) -> bool:
	var s := pack_slot_for(c, id)
	if s < 0:
		return false
	if c.items[s] == id:
		_counts(c)[s] = qty(c, s) + n
	else:
		set_slot(c, s, id, n if stacks(id) else 1)
	return true


## One of an item for the party: onto someone's stack of it if there is one, else into the first
## free slot. Returns who took it ({} if every pack is full). `members` defaults to the party.
func party_add(id: int, members: Array = []) -> Dictionary:
	var who: Array = members if not members.is_empty() else party
	if stacks(id):
		for c in who:
			for s in range(PACK_FIRST, PACK_LAST + 1):
				if c.items[s] == id:
					pack_add(c, id)
					return c
	for c in who:
		if pack_add(c, id):
			return c
	return {}


## How many of an item a character carries, worn and packed.
func count_of(c: Dictionary, id: int) -> int:
	var n := 0
	for s in c.items.size():
		if c.items[s] == id:
			n += qty(c, s)
	return n


## Gathers the same items in the pack into stacks (older saves kept one item per slot).
func stack_pack(c: Dictionary) -> void:
	for s in range(PACK_FIRST, PACK_LAST + 1):
		var id: int = c.items[s]
		if not stacks(id):
			continue
		for t in range(s + 1, PACK_LAST + 1):
			if c.items[t] == id:
				_counts(c)[s] = qty(c, s) + qty(c, t)
				set_slot(c, t, 0, 0)
	for s in c.items.size():
		if c.items[s] == 0:
			_counts(c)[s] = 0


func free_pack_slot(c: Dictionary) -> int:
	for i in range(PACK_FIRST, PACK_LAST + 1):
		if c.items[i] == 0:
			return i
	return -1


## EatAndDrink.
func eat(c: Dictionary, id: int) -> String:
	var it := item(id)
	var h := my_random(it.hits[0], it.hits[1])
	var he := my_random(it.health[0], it.health[1])
	var m := my_random(it.magic[0], it.magic[1])
	c.hits = mini(c.hits + h, c.max_hits)
	c.health = mini(c.health + he, c.max_health)
	c.magic = mini(c.magic + m, c.max_magic)
	var parts := []
	if h: parts.append("+%d hits" % h)
	if he: parts.append("+%d health" % he)
	if m: parts.append("+%d mana" % m)
	return "%s eats the %s. %s" % [c.name, it.name, ", ".join(parts)]


# ---------------------------------------------------------------- money (silver only)

func party_silver() -> int:
	var t := 0
	for c in party:
		t += c.silver
	return t


func money_string(silver: int) -> String:
	return "%d silver" % silver


## Takes `amount` silver from the party, member by member.
func pay(amount: int) -> bool:
	if party_silver() < amount:
		return false
	var left := amount
	for c in party:
		var take := mini(c.silver, left)
		c.silver -= take
		left -= take
	return true


# ---------------------------------------------------------------- game / save

func new_game() -> void:
	roster = []
	party = []
	visited = {}
	mine_level = 1
	pos = MinesArea.START
	facing = MinesArea.START_FACING
	location = "lehan"
	known = ["lehan", "mines"]
	story = {}
	town_known = {}
	day = 1
	site = "mines"


## After the prologue: the Harrow Company becomes the party, with the host first. They stand
## at the ruined shrine, a day from Lehan, and do not know of the mines yet.
func start_company(host: String, reply: int) -> void:
	new_game()
	var cast: Dictionary = PrologueData.CAST
	var order: Array = PrologueData.ORDER.duplicate()
	order.erase(host)
	order.push_front(host)
	for key in order:
		var src: Dictionary = cast[key]
		var c := make_character(src.name, CLASSES.find(src.cls), RACES.find(src.race),
			PORTRAIT_CAST + PrologueData.ORDER.find(key), src.abilities)
		c["traits"] = src.traits.duplicate()   # hidden from the player
		party.append(c)
	location = "shrine"
	known = ["shrine", "lehan"]
	story = {"host": host, "prologue_reply": reply}


## The file for a save slot: 1 .. SAVE_SLOTS, or "auto" for the checkpoint saves.
func slot_path(slot: Variant) -> String:
	return "%s_%s.json" % [SAVE_PREFIX, str(slot)]


## All slots, the automatic one first.
func save_slots() -> Array:
	var a: Array = ["auto"]
	for i in SAVE_SLOTS:
		a.append(i + 1)
	return a


func has_save() -> bool:
	for s in save_slots():
		if FileAccess.file_exists(slot_path(s)):
			return true
	return false


## Where the party is, for the load list.
func place_name(screen: String) -> String:
	match screen:
		"dungeon":
			if site == "shrine":
				return ShrineArea.NAMES[mine_level - 1]
			var at_camp := MinesArea.kind_of(mine_level, MinesArea.char_at(mine_level, pos)) == "camp"
			return "Mines level %d%s" % [mine_level, ", camp" if at_camp else ""]
		"inn":
			return "%s, the inn" % city.get("name", "Lehan")
		"streets":
			return "%s, the streets" % city.get("name", "Lehan")
		"tunnels":
			return "Under %s" % city.get("name", "Lehan")
		"village":
			return "Oggal, in the marshes"
	return LOCATIONS.get(location, {}).get("name", location.capitalize())


## What the load list shows of a save: {where, day, party: [[name, state]]}, state "fine",
## "wounded" or "dead"; empty when there is no save in the slot.
func save_info(slot: Variant) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return {"where": "(unreadable)", "day": 0, "party": []}
	var who := []
	for c in data.get("party", []):
		who.append([str(c.get("name", "?")).split(" ")[0], "wounded" if c.get("wounded", false) else "fine"])
	for nm in data.get("story", {}).get("dead", []):
		who.append([str(nm).split(" ")[0], "dead"])
	return {"where": data.get("where", str(data.get("screen", "?")).capitalize()), "day": int(data.get("day", 0)), "party": who}


func save_game(screen: String, slot: Variant = 1) -> bool:
	var v := []
	for k in visited:
		v.append([k.x, k.y, k.z])
	var data := {
		"version": 7, "screen": screen, "roster": roster, "party": party,
		"visited": v, "level": mine_level, "pos": [pos.x, pos.y], "facing": facing,
		"location": location, "known": known, "story": story, "town_known": town_known,
		"day": day, "where": place_name(screen), "site": site,
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


func _ints(v: Variant) -> Variant:
	# JSON turns every number into a float; turn them back into ints.
	if v is float:
		return int(v)
	if v is Array:
		var a := []
		for e in v:
			a.append(_ints(e))
		return a
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _ints(v[k])
		return d
	return v


## Saves before version 3 had six attributes, 22 skills and three kinds of coin. Money is
## converted (copper / 10, rounded up); abilities restart from the class and race.
func _convert_v3(c: Dictionary) -> void:
	var copper: int = c.get("gold", 0) * 100 + c.get("silver", 0) * 10 + c.get("copper", 0)
	c.silver = ceili(copper / 10.0)
	var cast_ab := {}
	for k in PrologueData.ORDER:
		if PrologueData.CAST[k].name == c.name:
			cast_ab = PrologueData.CAST[k].abilities
	c.abilities = cast_ab.duplicate() if not cast_ab.is_empty() else start_abilities(c.cls, c.race)
	c.xp = 0
	for k in ["gold", "copper", "level", "skills", "strength", "dexterity", "constitution",
			"intelligence", "will", "charisma"]:
		c.erase(k)
	update_derived(c)
	c.hits = c.max_hits
	c.magic = c.max_magic
	if c.get("owed", 0) > 0:
		c.owed = ceili(c.owed / 10.0)


## Returns the screen name to resume on, or "" on failure.
func load_game(slot: Variant = 1) -> String:
	if not FileAccess.file_exists(slot_path(slot)):
		return ""
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if not data is Dictionary:
		return ""
	data = _ints(data)
	roster = data.get("roster", [])
	party = data.get("party", [])
	if data.get("version", 1) < 2:
		# The party is saved as separate copies, so convert both lists.
		for c in roster + party:
			c.race = OLD_RACE_MAP[clampi(c.race, 0, OLD_RACE_MAP.size() - 1)]
	if data.get("version", 1) < 3:
		for c in roster + party:
			_convert_v3(c)
	if data.get("version", 1) < 4:
		# Older games kept the starting gear in the pack.
		for c in roster + party:
			equip_from_pack(c)
	if data.get("version", 1) < 5:
		# Thieves used to start without a weapon: give them their clasp knife.
		for c in roster + party:
			if c.cls == THIEF and not 31 in c.items:
				if pack_add(c, 31):
					equip_from_pack(c)
	for c in roster + party:
		stack_pack(c)
		update_derived(c)
		if not c.has("start_abilities"):
			c["start_abilities"] = _guess_start_abilities(c)
		if not c.has("xp_total"):
			c["xp_total"] = _estimate_xp_total(c)
	story = data.get("story", {})
	day = int(data.get("day", 1))
	visited = {}
	site = data.get("site", "mines")
	var A := area_script()
	mine_level = clampi(int(data.get("level", 1)), 1, A.MAPS.size())
	pos = A.START
	facing = A.START_FACING
	if data.get("version", 1) < 6:
		# The mines were redrawn (three new levels): old saves start again at the entrance.
		if data.get("visited", []).size() > 1:
			story["mines_entered"] = true
	else:
		for p in data.get("visited", []):
			visited[Vector3i(int(p[0]), int(p[1]), int(p[2]))] = true
		var p: Array = data.get("pos", [pos.x, pos.y])
		pos = Vector2i(int(p[0]), int(p[1]))
		facing = int(data.get("facing", 0))
		if not A.walkable(mine_level, pos):
			mine_level = 1
			pos = A.START
			facing = A.START_FACING
	location = data.get("location", "lehan")
	if not LOCATIONS.has(location):
		location = "lehan"
	known = data.get("known", ["lehan", "mines"])
	town_known = data.get("town_known", {})
	LehanQuests.sync_items()   # quest items for games saved before they were items
	var screen: String = data.get("screen", "inn")
	return {"city": "town", "create": "inn", "market": "streets"}.get(screen, screen)   # screens that were retired


# ---------------------------------------------------------------- world map / travel

## Known destinations reachable from `from`: [{"to": key, "days": n}].
func routes_from(from: String) -> Array:
	var out := []
	for r in ROUTES:
		var other: String = r[1] if r[0] == from else (r[0] if r[1] == from else "")
		if other != "" and other in known:
			out.append({"to": other, "days": r[2]})
	return out


## Travel to `dest`, a day at a time (road_day). Returns lines describing the trip.
func travel(dest: String, days: int) -> Array:
	var lines := ["After %d day%s on the road the party reaches %s." % [days, "" if days == 1 else "s", LOCATIONS[dest].name]]
	for d in days:
		lines.append_array(road_day())
	location = dest
	return lines


## One day on the road: everyone uses TRAVEL_COST Endurance; the best at Survival may forage;
## in the evening anyone running low eats from the packs (their own first); anyone still out of
## Endurance is starving and loses 1-3 hits (never below 1 on the road). A day passes.
func road_day() -> Array:
	var lines := []
	for c in party:
		c.health = maxi(0, c.health - TRAVEL_COST)
	var forager := _best_at("survival")
	if not forager.is_empty() and ability(forager, "survival") > 0 and check(forager, "survival", NORMAL):
		var hungriest: Dictionary = party[0]
		for c in party:
			if c.health * hungriest.max_health < hungriest.health * c.max_health:
				hungriest = c
		var got := my_random(10, 20)
		hungriest.health = mini(hungriest.max_health, hungriest.health + got)
		lines.append("%s forages roots and duck eggs along the way (+%d Endurance for %s)." % [
			forager.name.split(" ")[0], got, "them" if hungriest == forager else hungriest.name.split(" ")[0]])
	var ate := {}
	var starving := []
	for c in party:
		# Supper: one ration if there is room for it, and more if still too low for tomorrow.
		var meals := 0
		while (meals == 0 and c.health < c.max_health - 15) or c.health < TRAVEL_COST:
			var meal := _eat_ration(c)
			if meal == "":
				break
			meals += 1
			ate[meal] = int(ate.get(meal, 0)) + 1
		if c.health <= 0:
			var lost := mini(my_random(1, 3), c.hits - 1)
			if lost > 0:
				c.hits -= lost
			starving.append(c.name.split(" ")[0])
	if not ate.is_empty():
		var parts := []
		for k in ate:
			parts.append("%d %s" % [ate[k], k])
		lines.append("In the evening the party eats: %s." % ", ".join(parts))
	if not starving.is_empty():
		lines.append("%s %s nothing left to eat: weakened and starving." % [_and_list(starving),
			"has" if starving.size() == 1 else "have"])
	lines.append_array(pass_days(1))
	return lines


## Eats one ration (RATIONS order), from the character's own pack first, then a friend's.
## Returns the food's name, or "" if there is none in the party.
func _eat_ration(c: Dictionary) -> String:
	for id in RATIONS:
		for who in [c] + party:
			for s in range(PACK_FIRST, PACK_LAST + 1):
				if who.items[s] == id:
					take_from(who, s)
					var it := item(id)
					c.health = mini(c.max_health, c.health + my_random(it.health[0], it.health[1]))
					return it.name
	return ""


## Days of food the party carries: a ration a head each evening on the road.
func food_days() -> float:
	var total := 0
	for c in party:
		for s in range(PACK_FIRST, PACK_LAST + 1):
			if c.items[s] in RATIONS:
				total += qty(c, s)
	return float(total) / maxi(1, party.size())


## "A, B and C".
static func _and_list(names: Array) -> String:
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, -1)) + " and " + names[-1]


func _best_at(key: String) -> Dictionary:
	var best := {}
	for c in party:
		if best.is_empty() or ability(c, key) > ability(best, key):
			best = c
	return best


# ---------------------------------------------------------------- towns

## The places discovered so far in a town (the starting ones on the first visit).
func town_places(town: String) -> Array:
	if not town_known.has(town):
		town_known[town] = TOWNS[town].start.duplicate()
	return town_known[town]


## Returns true if the place was new.
func discover_place(town: String, place: String) -> bool:
	var known_here := town_places(town)
	if place in known_here:
		return false
	known_here.append(place)
	return true
