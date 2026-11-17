extends Node
## Global game state and rules. Started as a port of Shangrila.p / ShangrilaUtils.p (1997); the
## character rules are now the simpler ones in IDEAS.md: ten abilities from 0 to 10, silver only.

const SAVE_PATH := "user://shangrila_save.json"

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

## Dungeon "The Mines": "x,y,exits". Extracted verbatim from InitData.
const MINES_DATA := [
	"16,11,ES", "17,11,NESW", "18,11,SW", "16,12,NESW", "17,12,NESW", "18,12,NESW", "19,12,EW", "20,12,EW",
	"21,12,EW", "22,12,EW", "23,12,NSW", "16,13,NE", "17,13,NESW", "18,13,NW", "23,13,NS", "17,14,NS",
	"23,14,NS", "17,15,NS", "23,15,NS", "17,16,NS", "20,16,ES", "21,16,ESW", "22,16,ESW", "23,16,NW", "16,17,EW",
	"17,17,NESW", "18,17,EW", "19,17,EW", "20,17,NESW", "21,17,NESW", "22,17,NSW", "8,18,ES", "9,18,SW",
	"17,18,NS", "20,18,NE", "21,18,NESW", "22,18,NW", "8,19,NES", "9,19,NSW", "12,19,ES", "13,19,ESW",
	"14,19,SW", "17,19,NS", "8,20,NESW", "9,20,NESW", "10,20,EW", "11,20,EW", "12,20,NESW", "13,20,NESW",
	"14,20,NESW", "15,20,EW", "16,20,EW", "17,20,NW", "8,21,NES", "9,21,NSW", "12,21,NE", "13,21,NESW",
	"14,21,NW", "8,22,NES", "9,22,NSW", "13,22,NS", "8,23,NE", "9,23,NW", "13,23,NS", "13,24,NS", "13,25,N",
]
const MINES_START := Vector2i(13, 25)
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
	}},
}

## Routes between locations, with the number of days on the road.
const ROUTES := [["lehan", "mines", 1], ["shrine", "lehan", 1]]
## Endurance each character uses per day of travel (food is what refills it).
const TRAVEL_COST := 8

var main: Node            # set by main.gd, used for modal dialogs
var items := {}           # id -> item dictionary (templates, never mutated)
var mines := {}           # Vector2i -> Array[bool] exits [N, E, S, W]
var city := {}

var roster: Array = []    # "Mob" - characters waiting at the inn
var party: Array = []     # up to 6 characters
var visited := {}         # Vector2i -> true
var pos := MINES_START
var facing := 0           # 0 N, 1 E, 2 S, 3 W
var location := "lehan"   # key in LOCATIONS: where the party is on the world map
var known: Array = ["lehan", "mines"]   # discovered locations
var story := {}           # story state, e.g. {"host": "ithrae", "prologue_reply": 0}
var town_known := {}      # town key -> [discovered place keys]

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_make_items()
	_make_world()
	for s in MINES_DATA:
		var p: PackedStringArray = s.split(",")
		var ex: String = p[2]
		mines[Vector2i(int(p[0]), int(p[1]))] = [ex.contains("N"), ex.contains("E"), ex.contains("S"), ex.contains("W")]
	new_game()


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
	_it(33, "Crowned Head", "stonehead", "#a8a090", 150, 0, {"dims": true}, "The stone head from the old shrine. Its face is worn smooth, but the crown is still clear, and it is faintly warm.")


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
		"abilities": ab, "max_encum": 0, "xp": 0, "tactic": "", "silver": 0, "items": it,
	}


func ability(c: Dictionary, key: String) -> int:
	return c.get("abilities", {}).get(key, 0)


## A check: d10 + ability + bonus against a difficulty (EASY 6, NORMAL 9, HARD 12).
func check(c: Dictionary, key: String, difficulty: int, bonus := 0) -> bool:
	return my_random(1, 10) + ability(c, key) + bonus >= difficulty


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


## How strong a fighter the character is, to compare with a monster's level.
func power(c: Dictionary) -> int:
	return ability(c, best_fighting(c)) + ability(c, "toughness")


## One raise's worth of experience for this character (their next raise in their best fighting
## ability). Fights pay a small part of it, story moments a bigger one.
func raise_unit(c: Dictionary) -> int:
	return maxi(100, raise_cost(c, best_fighting(c)))


## Rounds a fraction up or down at random, so small amounts still add up on average.
func round_random(v: float) -> int:
	var whole := floori(v)
	return whole + (1 if rng.randf() < v - whole else 0)


## Story experience: everyone in the party gets `fraction` of a raise.
func story_xp(fraction: float) -> int:
	var total := 0
	for c in party:
		var x := roundi(raise_unit(c) * fraction)
		c.xp += x
		total = maxi(total, x)
	return total


## Hit points, mana and carrying limit, from race and abilities.
func update_derived(c: Dictionary) -> void:
	c.max_hits = RACE_HITS[c.race] + 3 * ability(c, "toughness")
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
	THIEF: [2, 5, 16, 24, 25, 27],
	WARRIOR: [3, 4, 15, 10, 9, 7],
}


func set_class(c: Dictionary, k: int) -> void:
	c.cls = k
	var list: Array = CLASS_ITEMS[k]
	for i in 6:
		c.items[PACK_FIRST + i] = list[i]


func finish_character(c: Dictionary, nm: String) -> void:
	c.name = nm
	update_derived(c)


func encumbrance(c: Dictionary) -> int:
	var e := 0
	for i in range(1, 31):
		if c.items[i] != 0:
			e += item(c.items[i]).weight
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
	return ability(c, weapon_ability(c, slot)) + (item(id).attack if id != 0 else 0)


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


## How far into the mines the party is - deeper means tougher monsters.
func depth() -> int:
	return absi(pos.x - MINES_START.x) + absi(pos.y - MINES_START.y)


## The whole party fell: they wake up at the inn, robbed of half their coins.
func party_defeated() -> void:
	for c in party:
		c.hits = 1
		add_silver(c, -c.silver / 2)
	pos = MINES_START
	facing = 0
	location = "lehan"


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


# ---------------------------------------------------------------- dungeon

func can_move(from: Vector2i, dir: int) -> bool:
	var ex: Array = mines.get(from, [false, false, false, false])
	return ex[dir] and mines.has(from + DIR_VEC[dir])


func exit_open(cell: Vector2i, dir: int) -> bool:
	return can_move(cell, dir)


# ---------------------------------------------------------------- game / save

func new_game() -> void:
	roster = []
	party = []
	visited = {MINES_START: true}
	pos = MINES_START
	facing = 0
	location = "lehan"
	known = ["lehan", "mines"]
	story = {}
	town_known = {}


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


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(screen: String) -> bool:
	var v := []
	for k in visited:
		v.append([k.x, k.y])
	var data := {
		"version": 3, "screen": screen, "roster": roster, "party": party,
		"visited": v, "pos": [pos.x, pos.y], "facing": facing,
		"location": location, "known": known, "story": story, "town_known": town_known,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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
func load_game() -> String:
	if not has_save():
		return ""
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
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
	for c in roster + party:
		update_derived(c)
	visited = {}
	for p in data.get("visited", []):
		visited[Vector2i(p[0], p[1])] = true
	var p: Array = data.get("pos", [MINES_START.x, MINES_START.y])
	pos = Vector2i(p[0], p[1])
	if not mines.has(pos):
		pos = MINES_START
	facing = data.get("facing", 0)
	location = data.get("location", "lehan")
	if not LOCATIONS.has(location):
		location = "lehan"
	known = data.get("known", ["lehan", "mines"])
	story = data.get("story", {})
	town_known = data.get("town_known", {})
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


## Travel to `dest`. Every character uses Endurance for each day on the road.
## Returns lines describing the trip.
func travel(dest: String, days: int) -> Array:
	var lines := ["After %d day%s on the road the party reaches %s." % [days, "" if days == 1 else "s", LOCATIONS[dest].name]]
	var hungry := []
	for c in party:
		c.health = maxi(0, c.health - TRAVEL_COST * days)
		if c.health == 0:
			hungry.append(c.name)
	if not hungry.is_empty():
		lines.append("%s %s starving and need%s food." % [", ".join(hungry), "is" if hungry.size() == 1 else "are", "s" if hungry.size() == 1 else ""])
	location = dest
	return lines


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
