extends Node
## Global game state and rules, ported from Shangrila.p / ShangrilaUtils.p (1997).

const SAVE_PATH := "user://shangrila_save.json"

const RACES := ["Human", "Thuug", "Aeldroe", "Nisk"]
enum { HUMAN, THUUG, AELDROE, NISK }
const RACE_INFO := [
	"Humans: adaptable and strong-armed.",
	"Thuugs: slow, turtle-like folk. Their shell gives +1 armour class.",
	"Aeldroes: slim, half-transparent beings with a gift for magic and hiding.",
	"Nisk: quick, wiry rat-folk who climb well and miss little.",
]
## Saves before version 2 used the original 1997 races; map them onto the new ones.
const OLD_RACE_MAP := [THUUG, AELDROE, HUMAN, NISK, HUMAN]  # Dwarf, Elf, Half Elf, Halfling, Human

const CLASSES := ["Cleric", "Enchanter", "Mage", "Monk", "Paladin", "Ranger", "Thief", "Warrior"]
enum { CLERIC, ENCHANTER, MAGE, MONK, PALADIN, RANGER, THIEF, WARRIOR }
const NO_CLASS := -1

## Skill names in the original order (Skills[1..22] -> index 0..21).
const SKILLS := [
	"Axes", "Blunt", "Bows", "Daggers", "Hands & Feet", "Pole Arms", "Swords", "Thrown",
	"Climb", "Disarm Traps", "Evaluate", "First Aid", "Foraging", "Haggle", "Herb Lore",
	"Hide", "Magic Arts", "Perception", "Pick Locks", "Read & Write", "Steal", "Tracking",
]

const MAX_ROSTER := 23
const MAX_PARTY := 6
const PORTRAITS := 32

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

var main: Node            # set by main.gd, used for modal dialogs
var items := {}           # id -> item dictionary (templates, never mutated)
var mines := {}           # Vector2i -> Array[bool] exits [N, E, S, W]
var city := {}

var roster: Array = []    # "Mob" - characters waiting at the inn
var party: Array = []     # up to 6 characters
var visited := {}         # Vector2i -> true
var pos := MINES_START
var facing := 0           # 0 N, 1 E, 2 S, 3 W

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
	# Same pool, same numbers as InitData. Prices of 111 were placeholders in the original.
	_it(2, "Red Shirt", "shirt", "#b02a20", 20, 111, {"armor": true, "chest": true}, "A plain shirt of red linen.")
	_it(3, "Longsword", "sword", "#d0d4dc", 60, 1500, {"dmg": [2, 7], "weapon": true, "sword": true}, "A fine straight blade, balanced for one hand.")
	_it(4, "Iron Helmet", "helmet", "#8a8f99", 45, 111, {"armor": true, "head": true, "defense": 2}, "Dented, but it has saved a skull or two.")
	_it(5, "Small Sack", "sack", "#a08050", 5, 111, {"dims": true}, "Holds a few odds and ends.")
	_it(6, "Heavy Robe", "robe", "#5a4a7a", 50, 111, {"armor": true, "chest": true, "defense": 1}, "Thick wool, warm in cold halls.")
	_it(7, "Heavy Boots", "boots", "#5a3a20", 60, 111, {"armor": true, "feet": true, "defense": 1}, "Iron-shod boots for long marches.")
	_it(8, "Sandals", "sandals", "#b08850", 10, 111, {"armor": true, "feet": true}, "Light and cool, little protection.")
	_it(9, "Leather Pants", "pants", "#7a5030", 20, 111, {"armor": true, "legs": true, "defense": 1}, "Supple boiled leather.")
	_it(10, "Leather Armor", "armor", "#8a5a30", 200, 111, {"armor": true, "chest": true, "defense": 3}, "A studded leather jerkin.")
	_it(11, "Longbow", "bow", "#8a6030", 50, 6000, {"dmg": [1, 6], "gun": true, "bow": true}, "Tall yew bow. Needs arrows.")
	_it(12, "Quiver", "quiver", "#6a4020", 30, 111, {"dims": true, "quiver": true}, "A leather quiver for arrows.")
	_it(13, "Arrow", "arrow", "#c0a070", 2, 20, {"misil": true, "quiver": true}, "Goose-feathered, iron tipped.")
	_it(14, "Mace", "mace", "#9aa0aa", 50, 400, {"dmg": [2, 5], "weapon": true, "blunt": true}, "A flanged iron head on an ash haft.")
	_it(15, "Wooden Shield", "shield", "#8a6234", 30, 111, {"armor": true, "defense": 1}, "Oak planks bound with iron.")
	_it(16, "Dark Pants", "pants", "#2a2a35", 20, 111, {"armor": true, "legs": true}, "Dark cloth trousers.")
	_it(17, "Yellow Robe", "robe", "#c8a020", 40, 111, {"armor": true, "chest": true}, "The saffron robe of a monk.")
	_it(18, "Staff", "staff", "#7a5530", 50, 3, {"dmg": [1, 4], "weapon": true, "blunt": true}, "A sturdy walking staff.")
	_it(19, "Spell Book", "book", "#5a2030", 100, 111, {"dims": true}, "Pages full of crabbed arcane script.")
	_it(20, "Magicuser Hat", "hat", "#30307a", 15, 111, {"armor": true, "head": true}, "Tall, pointed and starry.")
	_it(21, "Holy Symbol", "symbol", "#d4a830", 10, 111, {"neck": true, "dims": true}, "Blessed by the temple priests.")
	_it(22, "Holy Water", "flask", "#80b0e0", 20, 111, {"dims": true}, "A vial of blessed water.")
	_it(23, "First Aid Kit", "kit", "#e8e0d0", 100, 111, {"dims": true}, "Bandages, salves and a needle.")
	_it(24, "Lockpick Kit", "lockpick", "#6a4a2a", 100, 111, {"dims": true}, "Picks and tension tools. Not strictly legal.")
	_it(25, "Shoes", "shoes", "#4a3020", 25, 111, {"armor": true, "feet": true}, "Soft leather shoes.")
	_it(26, "Wood Axe", "axe", "#9aa0aa", 50, 100, {"dmg": [1, 6], "weapon": true, "axe": true}, "Meant for trees, works on other things.")
	_it(27, "Rope", "rope", "#c0a060", 50, 111, {"dims": true}, "Fifty feet of hemp rope.")
	_it(28, "Alnon Leaf", "leaf", "#40a040", 1, 111, {"dims": true, "food": true, "health": [10, 30]}, "A healing herb. Chew it.")
	_it(29, "Alman Root", "root", "#a07040", 1, 111, {"dims": true, "food": true, "hits": [1, 4]}, "Bitter root that closes wounds.")
	_it(30, "Cheese", "cheese", "#e8c040", 15, 111, {"dims": true, "food": true, "health": [20, 25]}, "A good wedge of hard cheese.")
	_it(31, "Clasp Knife", "knife", "#c8ccd4", 5, 110, {"dmg": [1, 3], "weapon": true, "dagger": true}, "A folding knife.")
	_it(32, "Bardiche", "bardiche", "#a0a6b0", 125, 700, {"dmg": [2, 8], "weapon": true, "axe": true}, "A long-hafted axe with a crescent blade.")


func item(id: int) -> Dictionary:
	return items.get(id, {})


func _make_world() -> void:
	# World[1] 'Lehan', Shops[2] (weapon smith). Duplicated longswords are as in the original.
	city = {
		"name": "Lehan",
		"shop": {"name": "Weapon Smith", "price_mod": 1.0, "stock": [3, 14, 26, 18, 11, 12, 13, 31, 3, 3, 3, 32]},
	}


# ---------------------------------------------------------------- bonus tables (ShangrilaUtils.p)

func stat_bonus(v: int) -> int:
	var t := [-30, -25, -20, -15, -10, -5, -2, -1, 0, 0, 0, 0, 1, 2, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
	return t[clampi(v, 1, 25) - 1]


func hits_bonus(con: int) -> int:
	var t := [-5, -5, -5, -5, -4, -3, -2, -1, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 7, 7, 7, 7, 7, 7]
	return t[clampi(con, 1, 25) - 1]


func armor_bonus(dex: int) -> int:
	var t := [-7, -6, -5, -3, -2, -1, -1, -1, 0, 0, 0, 0, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	return t[clampi(dex, 1, 25) - 1]


func weight_bonus(str_: int) -> int:
	var t := [-1500, -1000, -350, -250, -250, -150, -150, -50, -50, 0, 0, 100, 100, 200, 200,
		350, 500, 750, 1000, 1250, 1500, 2000, 3000, 4000, 5000]
	return t[clampi(str_, 1, 25) - 1]


# ---------------------------------------------------------------- characters

func blank_character() -> Dictionary:
	var it := []
	it.resize(31)
	it.fill(0)
	var sk := []
	sk.resize(22)
	sk.fill(-25)
	return {
		"name": "", "icon": 2, "level": 0, "race": HUMAN, "cls": NO_CLASS,
		"max_health": 0, "health": 0, "max_hits": 0, "hits": 0, "max_magic": 0, "magic": 0,
		"strength": 0, "dexterity": 0, "constitution": 0, "intelligence": 0, "will": 0, "charisma": 0,
		"max_encum": 0, "xp": 0, "tactic": "", "skills": sk, "gold": 0, "silver": 0, "copper": 0, "items": it,
	}


func _d(lo: int, hi: int, n: int) -> int:
	var s := 0
	for i in n:
		s += my_random(lo, hi)
	return s


## MakeRandomCharacter + the extra rolls done by the Reroll button.
func roll_character(c: Dictionary) -> void:
	c.strength = _d(2, 6, 3); c.dexterity = _d(2, 6, 3); c.constitution = _d(2, 6, 3)
	c.intelligence = _d(2, 6, 3); c.will = _d(2, 6, 3); c.charisma = _d(2, 6, 3)
	c.max_hits = _d(2, 5, 3) + hits_bonus(c.constitution)
	c.hits = c.max_hits
	match c.race:
		HUMAN:
			c.strength += 1
		THUUG:
			c.strength += 1; c.constitution += 2; c.dexterity -= 2; c.charisma -= 1
		AELDROE:
			c.intelligence += 2; c.will += 1; c.strength -= 1; c.constitution -= 2
		NISK:
			c.dexterity += 2; c.constitution += 1; c.strength -= 1; c.charisma -= 1
	c.max_health = c.will + (c.strength + c.constitution) * 4
	c.health = c.max_health / 2
	c.max_magic = 0
	c.magic = 0
	c.gold = my_random(1, 10)
	c.silver = my_random(1, 20)
	c.copper = my_random(1, 40)


func class_allowed(c: Dictionary, k: int) -> bool:
	if c.strength == 0:
		return false
	match k:
		CLERIC: return c.will >= 13
		ENCHANTER: return c.intelligence >= 14 and c.will >= 13 and c.dexterity >= 12
		MAGE: return c.intelligence >= 13 and c.dexterity >= 12
		MONK: return c.strength >= 13 and c.will >= 14 and c.dexterity >= 13 and c.constitution >= 11
		PALADIN: return c.strength >= 12 and c.intelligence >= 9 and c.will >= 13 and c.constitution >= 9 and c.charisma >= 15
		RANGER: return c.strength >= 12 and c.intelligence >= 10 and c.will >= 10 and c.constitution >= 12
		THIEF: return c.dexterity >= 12
		WARRIOR: return c.strength >= 12 and c.constitution >= 10
	return false


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
	update_skills(c)


## UpdateSkills.
func update_skills(c: Dictionary) -> void:
	var sk: Array = c.skills
	for i in 22:
		sk[i] = -25
	var s := stat_bonus(c.strength)
	var d := stat_bonus(c.dexterity)
	var n := stat_bonus(c.intelligence)
	var w := stat_bonus(c.will)
	sk[8] = 5 + roundi((s + d) / 2.0)
	sk[10] = 5 + n
	sk[13] = 5 + stat_bonus(c.charisma)
	sk[15] = 5
	sk[17] = 5
	var ssd := roundi((s + s + d) / 3.0)
	var sdd := roundi((s + d + d) / 3.0)
	match c.cls:
		CLERIC:
			sk[1] = 5 + ssd; sk[11] = 10; sk[16] = 5 + roundi((n + w) / 2.0); sk[19] = 40 + n
		ENCHANTER:
			sk[14] = 5 + n; sk[16] = 10 + roundi((n + w) / 2.0); sk[19] = 40 + n
		MAGE:
			sk[16] = 10 + roundi((n + w) / 2.0); sk[19] = 40 + n
		MONK:
			sk[4] = 10 + roundi((s + d) / 2.0); sk[7] = 5 + sdd; sk[8] = 15 + roundi((s + d) / 2.0)
			sk[14] = 7 + n; sk[19] = 30 + n
		PALADIN:
			sk[6] = 10 + ssd; sk[11] = 5; sk[19] = 25 + n
		RANGER:
			sk[0] = 5 + ssd; sk[2] = 10 + sdd; sk[12] = 7; sk[21] = 10
		THIEF:
			sk[3] = 5 + ssd; sk[8] = 10 + roundi((s + d) / 2.0); sk[9] = 5 + d; sk[18] = 7 + d; sk[20] = 10 + d
		WARRIOR:
			sk[0] = 5 + ssd; sk[5] = 2 + ssd; sk[6] = 10 + ssd
	match c.race:
		AELDROE:
			sk[15] += 10  # Hide: hard to see
			if sk[16] > -25:
				sk[16] += 10  # Magic Arts
		NISK:
			sk[8] += 10  # Climb
			sk[17] += 5  # Perception


func finish_character(c: Dictionary, nm: String) -> void:
	c.name = nm
	c.max_encum = 1500 + weight_bonus(c.strength)
	refresh_magic(c)


func encumbrance(c: Dictionary) -> int:
	var e := 0
	for i in range(1, 31):
		if c.items[i] != 0:
			e += item(c.items[i]).weight
	return e + c.gold + c.silver + c.copper


func armor_class(c: Dictionary) -> int:
	var ac: int = 7 + armor_bonus(c.dexterity)
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


func to_hit(c: Dictionary, slot: int) -> int:
	var id: int = c.items[slot]
	if id == 0:
		return c.skills[4]
	var it := item(id)
	var t := 0
	var kinds := ["axe", "blunt", "bow", "dagger", "unarm", "pole", "sword", "throw"]
	for k in kinds.size():
		if it[kinds[k]]:
			t += c.skills[k]
	return t


## Damage range of the weapon in a hand, as text for the View Character screen.
func damage_string(c: Dictionary, slot: int) -> String:
	var id: int = c.items[slot]
	if id == 0:
		return "1-4" if c.cls == MONK else "1-2"
	var d: Array = item(id).dmg
	return "-" if d[1] == 0 else "%d-%d" % [d[0], d[1]]


# ---------------------------------------------------------------- combat helpers (new)

## One spell per spell-casting class. The 1997 game kept max magic at 0 and had no spells,
## only a "Spells" button and the Magic Arts skill.
const SPELLS := {
	MAGE: {"name": "Fire Dart", "cost": 2, "target": "enemy", "desc": "A bolt of flame that never misses."},
	ENCHANTER: {"name": "Slumber", "cost": 3, "target": "enemy", "desc": "Puts a whole group of foes to sleep."},
	CLERIC: {"name": "Mend", "cost": 2, "target": "ally", "desc": "Heals wounds and can raise the fallen."},
}

const TACTICS := {
	"attack": "Attack", "parry": "Parry", "spell": "Cast spell", "turn": "Turn undead",
	"hide": "Hide", "pass": "Pass",
}


func spell_for(c: Dictionary) -> Dictionary:
	return SPELLS.get(c.cls, {})


## Gives spell casters a mana pool based on Magic Arts.
func refresh_magic(c: Dictionary) -> void:
	if spell_for(c).is_empty() or c.max_magic > 0:
		return
	c.max_magic = 4 + maxi(0, c.skills[16]) / 4
	c.magic = c.max_magic


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


func add_copper(c: Dictionary, amount: int) -> void:
	var have := char_copper(c) + amount
	c.gold = have / 100
	c.silver = (have % 100) / 10
	c.copper = have % 10


## How far into the mines the party is - deeper means tougher monsters.
func depth() -> int:
	return absi(pos.x - MINES_START.x) + absi(pos.y - MINES_START.y)


## The whole party fell: they wake up at the inn, robbed of half their coins.
func party_defeated() -> void:
	for c in party:
		c.hits = 1
		add_copper(c, -char_copper(c) / 2)
	pos = MINES_START
	facing = 0


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


# ---------------------------------------------------------------- money (1 G = 10 S = 100 C)

func char_copper(c: Dictionary) -> int:
	return c.gold * 100 + c.silver * 10 + c.copper


func party_copper() -> int:
	var t := 0
	for c in party:
		t += char_copper(c)
	return t


func money_string(copper: int) -> String:
	var g := copper / 100
	var s := (copper % 100) / 10
	return "%dG, %dS, %dC" % [g, s, copper % 10]


## Takes `amount` copper from the party, member by member, making change where needed.
func pay(amount: int) -> bool:
	if party_copper() < amount:
		return false
	var left := amount
	for c in party:
		if left <= 0:
			break
		var have := char_copper(c)
		var take := mini(have, left)
		have -= take
		left -= take
		c.gold = have / 100
		c.silver = (have % 100) / 10
		c.copper = have % 10
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


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(screen: String) -> bool:
	var v := []
	for k in visited:
		v.append([k.x, k.y])
	var data := {
		"version": 2, "screen": screen, "roster": roster, "party": party,
		"visited": v, "pos": [pos.x, pos.y], "facing": facing,
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
	for c in roster + party:
		refresh_magic(c)
	visited = {}
	for p in data.get("visited", []):
		visited[Vector2i(p[0], p[1])] = true
	var p: Array = data.get("pos", [MINES_START.x, MINES_START.y])
	pos = Vector2i(p[0], p[1])
	if not mines.has(pos):
		pos = MINES_START
	facing = data.get("facing", 0)
	return data.get("screen", "inn")
