class_name Combat
extends RefCounted
## Turn-based combat rules. The 1997 game had the nine action buttons (Attack, Parry, Spells,
## Use, Equip, Turn, Flee, Hide, Pass), MaskCombat/UnMaskCombat and attack/damage fields on
## the items, but no rules - everything in here is new.
##
## A round: every living character gets an order, then everybody (party and monsters) acts in
## initiative order. The UI calls begin_round() and then act() for each actor, so it can pace
## the log and the status bars one action at a time.

## `lvl` is compared with a character's power for experience. `def` is what a party member
## must reach with d10 + Combat (or Missile Weapons) to hit; `atk` is added to the monster's
## d10 against the character's defence. Coins are in silver.
const MONSTERS := {
	"rat": {"name": "Giant Rat", "plural": "Giant Rats", "lvl": 1, "hp": [2, 4], "def": 6, "atk": 1, "dmg": [1, 2],
		"speed": 3, "coins": [0, 0], "max": 5, "shape": "rat", "col": "#7a6656", "verb": "bites"},
	"bat": {"name": "Cave Bat", "plural": "Cave Bats", "lvl": 1, "hp": [1, 3], "def": 8, "atk": 1, "dmg": [1, 2],
		"speed": 6, "coins": [0, 0], "max": 6, "shape": "bat", "col": "#5a4654", "verb": "bites"},
	"kobold": {"name": "Kobold", "plural": "Kobolds", "lvl": 2, "hp": [3, 6], "def": 6, "atk": 2, "dmg": [1, 3],
		"speed": 2, "coins": [0, 1], "max": 5, "shape": "kobold", "col": "#9a6a3a", "verb": "stabs"},
	"goblin": {"name": "Goblin", "plural": "Goblins", "lvl": 3, "hp": [4, 8], "def": 7, "atk": 3, "dmg": [1, 4],
		"speed": 2, "coins": [0, 2], "max": 4, "shape": "goblin", "col": "#5a7a3a", "verb": "slashes"},
	"spider": {"name": "Giant Spider", "plural": "Giant Spiders", "lvl": 4, "hp": [5, 9], "def": 8, "atk": 3, "dmg": [1, 5],
		"speed": 4, "coins": [0, 0], "max": 3, "shape": "spider", "col": "#4a3030", "verb": "bites"},
	"skeleton": {"name": "Skeleton", "plural": "Skeletons", "lvl": 5, "hp": [6, 10], "def": 8, "atk": 3, "dmg": [1, 6],
		"speed": 1, "coins": [0, 1], "max": 4, "shape": "skeleton", "col": "#d8d0b8", "verb": "hacks",
		"undead": true},
	"orc": {"name": "Orc", "plural": "Orcs", "lvl": 6, "hp": [9, 14], "def": 8, "atk": 4, "dmg": [2, 7],
		"speed": 2, "coins": [1, 4], "max": 3, "shape": "orc", "col": "#4a6a4a", "verb": "cleaves"},
	"brigand": {"name": "Brigand", "plural": "Brigands", "lvl": 3, "hp": [4, 8], "def": 6, "atk": 2, "dmg": [1, 4],
		"speed": 2, "coins": [0, 3], "max": 4, "shape": "brigand", "col": "#4a4038", "verb": "slashes"},
	"renegade": {"name": "Renegade", "plural": "Renegades", "lvl": 7, "hp": [8, 12], "def": 9, "atk": 5, "dmg": [2, 6],
		"speed": 3, "coins": [2, 8], "max": 2, "shape": "enemy", "col": "#6a2020", "verb": "strikes"},
	# The mines' second level: cave creatures drawn by the breach.
	"gloomweaver": {"name": "Gloomweaver", "plural": "Gloomweavers", "lvl": 3, "hp": [3, 7], "def": 7, "atk": 3, "dmg": [1, 4],
		"speed": 4, "coins": [0, 0], "max": 4, "shape": "spider", "col": "#c8c0b0", "verb": "bites"},
	"gloom_mother": {"name": "Gloomweaver Mother", "plural": "Gloomweaver Mothers", "lvl": 5, "hp": [12, 16], "def": 8,
		"atk": 4, "dmg": [2, 6], "speed": 3, "coins": [0, 0], "max": 1, "shape": "spider", "size": 1.35, "col": "#e4dccc",
		"verb": "bites"},
	"delver": {"name": "Delver", "plural": "Delvers", "lvl": 4, "hp": [7, 11], "def": 7, "atk": 3, "dmg": [2, 5],
		"speed": 2, "coins": [0, 0], "max": 3, "shape": "delver", "col": "#6a5a50", "verb": "claws"},
	"lurker": {"name": "Cave Lurker", "plural": "Cave Lurkers", "lvl": 4, "hp": [6, 10], "def": 8, "atk": 4, "dmg": [1, 6],
		"speed": 5, "coins": [0, 1], "max": 2, "shape": "lurker", "col": "#3e4846", "verb": "lashes"},
	# The third level: the jailers' oath-bound dead, guarding the tomb.
	"oathbound": {"name": "Oathbound", "plural": "Oathbound", "lvl": 5, "hp": [6, 10], "def": 8, "atk": 3, "dmg": [1, 6],
		"speed": 1, "coins": [0, 2], "max": 4, "shape": "oath", "col": "#b0aca0", "verb": "hacks", "undead": true, "oath": true},
	"oath_archer": {"name": "Oath-Archer", "plural": "Oath-Archers", "lvl": 5, "hp": [5, 8], "def": 7, "atk": 4, "dmg": [1, 5],
		"speed": 2, "coins": [0, 2], "max": 3, "shape": "oath_archer", "col": "#a8a498", "verb": "shoots", "undead": true,
		"oath": true},
	"sworn_knight": {"name": "Sworn Knight", "plural": "Sworn Knights", "lvl": 7, "hp": [12, 18], "def": 9, "atk": 5,
		"dmg": [2, 7], "speed": 1, "coins": [1, 5], "max": 1, "shape": "oath_knight", "col": "#9a9890", "verb": "cleaves",
		"undead": true, "oath": true},
	# It cannot be beaten (yet): blows do nothing, it can't be turned or put to sleep, and it
	# doesn't follow anyone who runs. See "The mines" in IDEAS.md.
	"warden": {"name": "Warden", "plural": "Wardens", "lvl": 12, "hp": [99, 99], "def": 6, "atk": 7, "dmg": [3, 9],
		"speed": 3, "coins": [0, 0], "max": 1, "shape": "warden", "col": "#7a7a84", "verb": "strikes", "undead": true,
		"oath": true, "invulnerable": true, "no_chase": true},
}

## The wandering monsters on each level of the mines (depth / 7, see Game.depth).
const TIERS := [
	["rat", "bat", "kobold"],
	["gloomweaver", "lurker", "delver", "bat"],
	["oathbound", "oath_archer", "gloomweaver"],
]

## Things monsters sometimes drop.
const LOOT := [30, 30, 28, 29, 13, 31, 22]

const ACTION_NAMES := {
	"attack": "Attack", "parry": "Parry", "spells": "Spell", "use": "Use", "equip": "Equip",
	"turn": "Turn", "flee": "Flee", "hide": "Hide", "pass": "Pass",
}

var groups: Array = []   # [{key, def, members: [{hp, max_hp, sleep, coins}]}]
var hidden := {}         # party index -> rounds left hidden
var parry := {}          # party index -> true, this round only
var fled := false
var round_no := 0
var blessed := {}        # party index -> true: the spirit guides their blow this round
var warded := {}         # party index -> true: the spirit turns aside the next blow this round
var seen := {}           # party index -> true: was out in the open at the end of a round
var fell := {}           # party index -> true: went down at some point
var dark := true         # the mines are dark (Aeldroes hide better); the road is not
var level := 1           # the fight's level, for experience


## `fixed` sets the monsters instead of rolling them: [{"key": "brigand", "n": 3}, ...].
func _init(depth := 0, fixed: Array = []) -> void:
	dark = fixed.is_empty()
	if not fixed.is_empty():
		for f in fixed:
			var def: Dictionary = MONSTERS[f.key]
			var members := []
			for i in f.n:
				var hp := Game.my_random(def.hp[0], def.hp[1])
				members.append({"hp": hp, "max_hp": hp, "sleep": 0})
			groups.append({"key": f.key, "def": def, "members": members})
		_set_level()
		return
	var tier := clampi(depth / 7, 0, TIERS.size() - 1)
	var pool: Array = TIERS[tier].duplicate()
	pool.shuffle()
	var n_groups := 1
	if Game.my_random(1, 100) <= 25 + depth * 3:
		n_groups += 1
	if depth >= 12 and Game.my_random(1, 100) <= 35:
		n_groups += 1
	var cap := 1 + Game.party.size() / 2 + tier
	for g in mini(n_groups, pool.size()):
		var key: String = pool[g]
		var def: Dictionary = MONSTERS[key]
		var members := []
		for i in Game.my_random(1, mini(def.max, cap)):
			var hp := Game.my_random(def.hp[0], def.hp[1])
			members.append({"hp": hp, "max_hp": hp, "sleep": 0})
		groups.append({"key": key, "def": def, "members": members})
	_set_level()


## The fight's level: its strongest monster, +1 if they outnumber the party two to one.
func _set_level() -> void:
	var n := 0
	level = 1
	for g in groups:
		level = maxi(level, g.def.lvl)
		n += g.members.size()
	var up := Game.party.filter(func(c): return c.hits > 0).size()
	if n >= 2 * maxi(1, up):
		level += 1


# ---------------------------------------------------------------- queries

func living(gi: int) -> Array:
	if gi < 0 or gi >= groups.size():
		return []
	return groups[gi].members.filter(func(m): return m.hp > 0)


func alive_groups() -> Array:
	var a := []
	for gi in groups.size():
		if not living(gi).is_empty():
			a.append(gi)
	return a


static func count_name(def: Dictionary, n: int) -> String:
	if n == 1:
		var art := "an" if "AEIOU".contains(def.name[0]) else "a"
		return "%s %s" % [art, def.name]
	return "%d %s" % [n, def.plural]


func group_label(gi: int) -> String:
	var n := living(gi).size()
	var def: Dictionary = groups[gi].def
	return def.name if n == 1 else "%d %s" % [n, def.plural]


func describe() -> String:
	var parts := []
	for gi in alive_groups():
		parts.append(count_name(groups[gi].def, living(gi).size()))
	if parts.size() == 1:
		return parts[0]
	return ", ".join(parts.slice(0, -1)) + " and " + parts[-1]


func is_undead(gi: int) -> bool:
	return gi >= 0 and gi < groups.size() and groups[gi].def.get("undead", false) and not living(gi).is_empty()


func undead_groups() -> Array:
	return alive_groups().filter(func(gi): return is_undead(gi))


func party_alive() -> bool:
	for c in Game.party:
		if c.hits > 0:
			return true
	return false


## "" while the fight goes on, otherwise "won", "lost" or "fled".
func outcome() -> String:
	if fled:
		return "fled"
	if not party_alive():
		return "lost"
	if alive_groups().is_empty():
		return "won"
	return ""


func food_slots(c: Dictionary) -> Array:
	var a := []
	for s in range(1, 31):
		if c.items[s] != 0 and Game.item(c.items[s]).food:
			a.append(s)
	return a


## Weapons in the backpack that can be drawn into the right hand.
func weapon_slots(c: Dictionary) -> Array:
	var a := []
	for s in range(Game.PACK_FIRST, Game.PACK_LAST + 1):
		var id: int = c.items[s]
		if id != 0 and (Game.item(id).weapon or Game.item(id).gun):
			a.append(s)
	return a


func has_arrows(c: Dictionary) -> bool:
	for s in range(1, 31):
		if c.items[s] == 13:
			return true
	return false


## What the character fights with: {name, dmg, skill, ranged, verb}.
func weapon_info(c: Dictionary) -> Dictionary:
	for slot in [Game.SLOT_RHAND, Game.SLOT_LHAND]:
		var id: int = c.items[slot]
		if id == 0:
			continue
		var it := Game.item(id)
		if it.gun and has_arrows(c):
			return {"name": it.name, "dmg": it.dmg, "skill": Game.to_hit(c, slot), "ranged": true, "verb": "shoots",
				"ability": "missile"}
		if it.weapon:
			var verb := "stabs" if it.dagger else ("swings the %s" % it.name)
			return {"name": it.name, "dmg": it.dmg, "skill": Game.to_hit(c, slot), "ranged": false, "verb": verb,
				"ability": Game.weapon_ability(c, slot), "bane": it.get("bane", "")}
	var monk: bool = c.cls == Game.MONK
	return {"name": "fists", "dmg": [1, 4] if monk else [1, 2], "skill": Game.ability(c, "combat"), "ranged": false,
		"verb": "punches", "ability": "combat"}


## d10 + bonus against a target number. A 10 always succeeds and a 1 always fails.
static func roll(bonus: int, target: int) -> bool:
	var r := Game.my_random(1, 10)
	return r == 10 or (r != 1 and r + bonus >= target)


## What a monster's d10 + atk must reach to hit this character.
func defence(i: int) -> int:
	var c: Dictionary = Game.party[i]
	return 8 + Game.ability(c, "combat") + Game.armor(c) / 2 + (2 if parry.has(i) else 0)


func available(i: int) -> Dictionary:
	var c: Dictionary = Game.party[i]
	var sp := Game.spell_for(c)
	return {
		"attack": true,
		"parry": true,
		"spells": not sp.is_empty() and c.magic >= sp.cost,
		"use": not food_slots(c).is_empty(),
		"equip": not weapon_slots(c).is_empty(),
		"turn": (c.cls == Game.CLERIC or c.cls == Game.PALADIN) and not undead_groups().is_empty(),
		"flee": true,
		"hide": not hidden.has(i),
		"pass": true,
	}


## "enemy", "ally" or "" - what an action has to be aimed at.
func target_kind(i: int, act: String) -> String:
	match act:
		"attack", "turn":
			return "enemy"
		"spells":
			return Game.spell_for(Game.party[i]).get("target", "")
	return ""


func most_wounded() -> int:
	var best := -1
	var worst := 1.0
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		var f := float(c.hits) / maxf(1.0, c.max_hits)
		if f < worst:
			worst = f
			best = i
	return best if worst < 0.65 else -1


func _biggest_group() -> int:
	var best := -1
	var n := 0
	for gi in alive_groups():
		if living(gi).size() > n:
			n = living(gi).size()
			best = gi
	return best


func _front_group() -> int:
	var a := alive_groups()
	return a[0] if not a.is_empty() else -1


## The order a character gets from their default action (tactic).
func default_order(i: int) -> Dictionary:
	var c: Dictionary = Game.party[i]
	var av := available(i)
	match Game.tactic(c):
		"parry":
			return {"act": "parry"}
		"pass":
			return {"act": "pass"}
		"hide":
			if av.hide:
				return {"act": "hide"}
		"turn":
			if av.turn:
				return {"act": "turn", "target": undead_groups()[0]}
		"spell":
			if av.spells:
				var sp := Game.spell_for(c)
				if sp.target == "ally":
					var w := most_wounded()
					if w >= 0:
						return {"act": "spells", "target": w, "ally": true}
				elif sp.name == "Slumber":
					return {"act": "spells", "target": _biggest_group()}
				else:
					return {"act": "spells", "target": _front_group()}
	return {"act": "attack", "target": _front_group()}


static func order_text(o: Dictionary, combat: Combat) -> String:
	var t: String = ACTION_NAMES.get(o.get("act", ""), "")
	if o.has("target") and combat:
		var tg: int = o.target
		if combat.target_kind_of(o) == "ally":
			t += "\n" + Game.party[tg].name
		elif tg >= 0 and tg < combat.groups.size():
			t += "\n" + (combat.groups[tg].def.name if combat.living(tg).size() == 1 else combat.groups[tg].def.plural)
	elif o.has("slot"):
		t += "\n" + Game.item(o.item).name
	return t


func target_kind_of(o: Dictionary) -> String:
	if o.get("act", "") == "spells":
		return "ally" if o.has("ally") else "enemy"
	return "enemy"


# ---------------------------------------------------------------- the round

## Returns the actors in initiative order: {side: "p", i} or {side: "m", g, m}.
func begin_round(orders: Dictionary) -> Array:
	round_no += 1
	parry.clear()
	for i in orders:
		if orders[i].act == "parry":
			parry[i] = true
	var list := []
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		if c.hits > 0 and orders.has(i):
			var slow := 3 if c.race == Game.THUUG else 0
			list.append({"side": "p", "i": i, "init": Game.my_random(1, 20) + Game.ability(c, "perception") * 2 - slow})
	for gi in groups.size():
		for m in living(gi):
			list.append({"side": "m", "g": gi, "m": m, "init": Game.my_random(1, 20) + groups[gi].def.speed})
	list.sort_custom(func(a, b): return a.init > b.init)
	return list


func end_round() -> void:
	for i in Game.party.size():
		if Game.party[i].hits > 0 and not hidden.has(i):
			seen[i] = true
	blessed.clear()
	warded.clear()
	for i in hidden.keys():
		hidden[i] -= 1
		if hidden[i] <= 0:
			hidden.erase(i)


## Performs one actor's turn and returns the log lines.
func act(a: Dictionary, orders: Dictionary) -> Array:
	if outcome() != "":
		return []
	if a.side == "m":
		return _monster(a.g, a.m)
	var c: Dictionary = Game.party[a.i]
	if c.hits <= 0:
		return []
	var o: Dictionary = orders[a.i]
	match o.act:
		"attack": return _attack(a.i, o.get("target", -1))
		"parry": return ["%s stands guard." % c.name]
		"spells": return _cast(a.i, o)
		"use": return _use(a.i, o)
		"equip": return _equip(a.i, o)
		"turn": return _turn(a.i, o.get("target", -1))
		"flee": return _flee(a.i)
		"hide": return _hide(a.i)
	return ["%s waits." % c.name]


func _valid_group(gi: int) -> int:
	if not living(gi).is_empty():
		return gi
	return _front_group()


## Deals damage to a monster; returns the extra text for a kill.
func _hurt(gi: int, m: Dictionary, dmg: int) -> String:
	if groups[gi].def.get("invulnerable", false):
		return " It does nothing. The %s does not even slow." % groups[gi].def.name
	m.hp = maxi(0, m.hp - dmg)
	m.sleep = 0
	if m.hp == 0:
		return " The %s dies!" % groups[gi].def.name
	return ""


func _attack(i: int, gi: int) -> Array:
	var c: Dictionary = Game.party[i]
	gi = _valid_group(gi)
	if gi < 0:
		return []
	var w := weapon_info(c)
	var m: Dictionary = living(gi)[0]
	var def: Dictionary = groups[gi].def
	var bonus: int = w.skill + (3 if m.sleep > 0 else 0)
	var sneak := hidden.has(i)
	if sneak:
		bonus += 10
		hidden.erase(i)
	var guided := blessed.has(i)
	if guided:
		bonus += 3
	var verb: String = w.verb
	if not roll(bonus, def.def):
		if w.ranged:
			return ["%s shoots at the %s and misses." % [c.name, def.name]]
		return ["%s %s at the %s, but misses." % [c.name, verb, def.name]]
	var dmg := Game.my_random(w.dmg[0], w.dmg[1]) + Game.ability(c, w.ability) / 3
	if w.get("bane", "") != "" and def.get(w.bane, false):
		dmg += 2   # the jailers' arms bite deeper into their own dead
	var how := ""
	if sneak:
		dmg *= 2
		how = " from the shadows"
	if guided:
		dmg += 2
		how = " with uncanny sureness"
	var line := "%s %s%s and hits the %s for %d." % [c.name, verb, how, def.name, dmg]
	if w.ranged:
		line = "%s shoots%s and hits the %s for %d." % [c.name, how, def.name, dmg]
	return [line + _hurt(gi, m, dmg)]


func _cast(i: int, o: Dictionary) -> Array:
	var c: Dictionary = Game.party[i]
	var sp := Game.spell_for(c)
	if sp.is_empty() or c.magic < sp.cost:
		return ["%s tries to cast, but has no mana left." % c.name]
	c.magic -= sp.cost
	match sp.name:
		"Fire Dart":
			var gi := _valid_group(o.get("target", -1))
			if gi < 0:
				return []
			var m: Dictionary = living(gi)[0]
			var dmg := Game.my_random(2, 7) + Game.ability(c, "magic") / 2
			return ["%s hurls a Fire Dart at the %s for %d!%s" % [c.name, groups[gi].def.name, dmg, _hurt(gi, m, dmg)]]
		"Slumber":
			var gi := _valid_group(o.get("target", -1))
			if gi < 0:
				return []
			var def: Dictionary = groups[gi].def
			if def.get("undead", false):
				return ["%s casts Slumber, but the %s never sleep." % [c.name, def.plural]]
			var n := 0
			for m in living(gi):
				if roll(Game.ability(c, "magic"), 5 + def.lvl / 2):
					m.sleep = Game.my_random(2, 3)
					n += 1
			if n == 0:
				return ["%s casts Slumber, but the %s shrug it off." % [c.name, def.plural]]
			return ["%s casts Slumber - %s fall%s asleep." % [c.name, count_name(def, n), "s" if n == 1 else ""]]
		"Mend":
			var t: int = o.get("target", i)
			var tc: Dictionary = Game.party[t]
			var was_down: bool = tc.hits <= 0
			var heal := Game.my_random(2, 6) + Game.ability(c, "magic") / 2
			heal = mini(heal, tc.max_hits - tc.hits)
			tc.hits += heal
			var line := "%s casts Mend, healing %d." % [c.name, heal] if t == i \
				else "%s casts Mend on %s, healing %d." % [c.name, tc.name, heal]
			if was_down and tc.hits > 0:
				line += " %s gets back up!" % tc.name
			return [line]
	return []


func _use(i: int, o: Dictionary) -> Array:
	var c: Dictionary = Game.party[i]
	var slot: int = o.get("slot", 0)
	if slot == 0 or c.items[slot] != o.get("item", -1):
		return ["%s fumbles in the backpack and finds nothing." % c.name]
	c.items[slot] = 0
	return [Game.eat(c, o.item)]


func _equip(i: int, o: Dictionary) -> Array:
	var c: Dictionary = Game.party[i]
	var slot: int = o.get("slot", 0)
	if slot == 0 or c.items[slot] != o.get("item", -1):
		return ["%s fumbles in the backpack and finds nothing." % c.name]
	var old: int = c.items[Game.SLOT_RHAND]
	c.items[Game.SLOT_RHAND] = c.items[slot]
	c.items[slot] = old
	return ["%s readies the %s." % [c.name, Game.item(o.item).name]]


func _turn(i: int, gi: int) -> Array:
	var c: Dictionary = Game.party[i]
	if not is_undead(gi):
		var u := undead_groups()
		if u.is_empty():
			return ["%s raises the holy symbol, but nothing here is undead." % c.name]
		gi = u[0]
	var def: Dictionary = groups[gi].def
	if def.get("invulnerable", false):
		return ["%s raises the holy symbol. The %s looks at it, and comes on." % [c.name, def.name]]
	var bonus := Game.ability(c, "magic") + (2 if c.cls == Game.CLERIC else 0)
	if not roll(bonus, 6 + def.lvl / 2):
		return ["%s calls on the gods, but the %s keep coming." % [c.name, def.plural]]
	var n := 0
	for m in living(gi).slice(0, Game.my_random(1, 3)):
		m.hp = 0
		n += 1
	return ["%s turns the undead! %s crumble%s to dust." % [c.name, count_name(def, n).capitalize(), "s" if n == 1 else ""]]


func _flee(i: int) -> Array:
	var c: Dictionary = Game.party[i]
	for gi in alive_groups():
		if groups[gi].def.get("no_chase", false):
			fled = true
			return ["%s turns and runs, and the rest follow. The %s does not chase you: it goes back to its place, and waits." % [c.name, groups[gi].def.name]]
	var foes := 0
	for gi in alive_groups():
		foes += living(gi).filter(func(m): return m.sleep == 0).size()
	if roll(Game.ability(c, "stealth"), 4 + foes / 2):
		fled = true
		return ["%s finds a way out - the party flees!" % c.name]
	return ["%s looks for a way out, but the monsters block the way." % c.name]


func _hide(i: int) -> Array:
	var c: Dictionary = Game.party[i]
	var bonus := Game.ability(c, "stealth") + (2 if dark and c.race == Game.AELDROE else 0)
	if roll(bonus, Game.EASY):
		hidden[i] = 3
		return ["%s slips into the shadows." % c.name]
	return ["%s tries to hide, but is spotted." % c.name]


func _monster(gi: int, m: Dictionary) -> Array:
	if m.hp <= 0:
		return []
	var def: Dictionary = groups[gi].def
	if m.sleep > 0:
		m.sleep -= 1
		return ["A %s wakes up." % def.name] if m.sleep == 0 else []
	var cand := []
	for i in Game.party.size():
		if Game.party[i].hits > 0 and not hidden.has(i):
			cand.append(i)
	if cand.is_empty():
		return ["The %s looks around, but finds no one." % def.name]
	# The first three party members form the front rank and take most of the blows.
	var front := cand.slice(0, 3)
	var t: int = front.pick_random() if Game.my_random(1, 100) <= 75 else cand.pick_random()
	var c: Dictionary = Game.party[t]
	var art := "An" if "AEIOU".contains(def.name[0]) else "A"
	if not roll(def.atk, defence(t)):
		if parry.has(t):
			return ["%s %s %s at %s, who parries." % [art, def.name, def.verb, c.name]]
		return ["%s %s %s at %s, but misses." % [art, def.name, def.verb, c.name]]
	if warded.has(t):
		warded.erase(t)
		return ["%s %s %s %s, but the blow turns aside as if caught by an unseen hand." % [art, def.name, def.verb, c.name]]
	var dmg := Game.my_random(def.dmg[0], def.dmg[1])
	c.hits = maxi(0, c.hits - dmg)
	var line := "%s %s %s %s for %d." % [art, def.name, def.verb, c.name, dmg]
	if c.hits == 0:
		line += " %s falls!" % c.name
		fell[t] = true
	return [line]


# ---------------------------------------------------------------- after the fight

## True if the character spent the whole fight hidden.
func hid_all_fight(i: int) -> bool:
	return not seen.has(i) and hidden.has(i)


## Experience for one character: 1% of a raise for a fight at their own power, doubled for each
## level above it, halved for each level below, nothing three or more below. Hiding the whole
## fight gives nothing, falling halves it.
func xp_for(i: int) -> float:
	var c: Dictionary = Game.party[i]
	var diff := level - Game.power(c)
	if diff <= -3 or hid_all_fight(i):
		return 0.0
	var x := Game.raise_unit(c) * 0.01 * pow(2.0, diff)
	if fell.has(i) or c.hits <= 0:
		x /= 2.0
	return x


## Hands out experience, coins and the odd item. Returns the log lines.
func rewards() -> Array:
	var coins := 0
	for g in groups:
		for m in g.members:
			if m.hp <= 0:
				coins += Game.my_random(g.def.coins[0], g.def.coins[1])
	var gains := []
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		var x := Game.round_random(xp_for(i))
		c.xp += x
		var note := ""
		if level - Game.power(c) <= -3:
			note = " (too easy)"
		elif hid_all_fight(i):
			note = " (hid)"
		gains.append("%s %d%s" % [c.name.split(" ")[0], x, note])
	var up := Game.party.filter(func(c): return c.hits > 0)
	var lines := []
	for c in Game.party:
		if c.hits <= 0:
			c.hits = 1
			lines.append("%s comes around, badly bruised." % c.name)
	lines.push_front("Experience: " + ", ".join(gains) + ".")
	if up.is_empty():
		return lines
	var each := coins / up.size()
	for c in up:
		Game.add_silver(c, each)
	lines.push_front("Victory!" + (" Each survivor finds %s." % Game.money_string(each) if each > 0 else ""))
	if Game.my_random(1, 100) <= 30:
		var id: int = LOOT.pick_random()
		for c in up:
			var s := Game.free_pack_slot(c)
			if s >= 0:
				c.items[s] = id
				lines.append("%s finds %s." % [c.name, "some Arrows" if id == 13 else "a " + Game.item(id).name])
				break
	return lines
