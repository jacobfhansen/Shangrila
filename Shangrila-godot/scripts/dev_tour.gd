extends Node
## Developer aid: `godot --path . -- --tour=<dir>` visits every screen and saves screenshots.
## Add `--part=quests` to run only the Lehan quests and the council (the whole tour is long), or
## `--part=mines` for the mines job, from the entrance to the report at the council.

var out := ""
var part := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tour="):
			out = a.substr(7)
		if a.begins_with("--part="):
			part = a.substr(7)
	if part == "quests":
		_quests_only.call_deferred()
	elif part == "mines":
		_mines_part.call_deferred()
	else:
		_run.call_deferred()


func _quests_only() -> void:
	await _shot("01_about")
	await _council_visits()
	await _lisbet_quest()
	await _boddo_quest()
	await _skee_quest()
	print("quests part done")
	get_tree().quit()


func _shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _make(nm: String, cls: int, icon: int, race := Game.HUMAN) -> Dictionary:
	return Game.make_character(nm, cls, race, icon)


## Plays many fights with default actions only, to check the balance.
func _simulate() -> void:
	var saved := Game.party.duplicate(true)
	for depth in [0, 7, 14, 20]:
		var t0 := Time.get_ticks_msec()
		var won := 0
		var rounds := 0
		var lost_hp := 0.0
		for n in 200:
			Game.party = saved.duplicate(true)
			for c in Game.party:
				c.hits = c.max_hits
				c.magic = c.max_magic
			var cb := Combat.new(depth)
			while cb.outcome() == "" and cb.round_no < 60:
				var o := {}
				for i in Game.party.size():
					if Game.party[i].hits > 0:
						o[i] = cb.default_order(i)
				for a in cb.begin_round(o):
					cb.act(a, o)
				cb.end_round()
			if cb.outcome() == "won":
				won += 1
			rounds += cb.round_no
			for c in Game.party:
				lost_hp += 1.0 - float(c.hits) / c.max_hits
		print("depth %d: won %d%%, avg %.1f rounds, avg hp lost %d%%" % [depth, won / 2, rounds / 200.0, lost_hp / (200 * Game.party.size()) * 100])
	Game.party = saved


## Rule checks for abilities, silver and experience, then the balance check with the real
## starting company. Restores the tour's party afterwards.
func _mechanics() -> void:
	var keep_party := Game.party
	var keep_roster := Game.roster
	var keep_story := Game.story.duplicate(true)
	var keep := [Game.location, Game.known.duplicate(), Game.town_known.duplicate(true), Game.pos]
	Game.start_company("joss", 0)
	for c in Game.party:
		var ab := []
		for k in Game.ABILITIES:
			if c.abilities[k] > 0:
				ab.append("%s %d" % [k, c.abilities[k]])
		print("%s: %s | hits %d mana %d enc %d silver %d power %d raise unit %d" % [c.name, ", ".join(ab),
			c.max_hits, c.max_magic, c.max_encum, c.silver, Game.power(c), Game.raise_unit(c)])
	var joss: Dictionary = Game.party[0]
	print("joss raise costs: combat %d toughness %d stealth %d (human -10%%)" % [Game.raise_cost(joss, "combat"),
		Game.raise_cost(joss, "toughness"), Game.raise_cost(joss, "stealth")])
	joss.xp = 300
	var hp0: int = joss.max_hits
	print("raise toughness: ", Game.raise_ability(joss, "toughness"), " -> ", joss.abilities.toughness,
		" hits ", hp0, " -> ", joss.max_hits, " xp left ", joss.xp, "; raise again (too poor): ", Game.raise_ability(joss, "toughness"))
	joss.abilities.toughness = 1
	Game.update_derived(joss)
	joss.xp = 0
	# Experience by fight level for Joss (power 3): even 1%, +1 doubles, -3 nothing.
	var cb := Combat.new(0, [{"key": "rat", "n": 1}])
	var row := []
	for lvl in range(0, 8):
		cb.level = lvl
		cb.seen = {0: true}
		row.append("L%d %.2f" % [lvl, cb.xp_for(0)])
	print("xp for joss by fight level: ", ", ".join(row))
	cb.level = 3
	cb.seen = {}
	cb.hidden = {0: 2}
	print("hid all fight: ", cb.xp_for(0), "; fell: ", (func(): cb.hidden = {}; cb.fell = {0: true}; return cb.xp_for(0)).call())
	var won := 0
	var xp_total := 0
	for n in 50:
		var fight := Combat.new(0)
		var keep_xp: Array = Game.party.map(func(c): return c.xp)
		for c in Game.party:
			c.hits = c.max_hits
		while fight.outcome() == "" and fight.round_no < 60:
			var o := {}
			for i in Game.party.size():
				if Game.party[i].hits > 0:
					o[i] = fight.default_order(i)
			for a in fight.begin_round(o):
				fight.act(a, o)
			fight.end_round()
		if fight.outcome() == "won":
			won += 1
			fight.rewards()
		for i in Game.party.size():
			xp_total += Game.party[i].xp - keep_xp[i]
	print("50 fights at the entrance: won %d, experience in total (all five) %d" % [won, xp_total])
	print("story xp, third of a raise: ", Game.story_xp(1.0 / 3.0), " -> ", Game.party.map(func(c): return c.xp))
	print("money: ", Game.money_string(Game.party_silver()), " pay 30: ", Game.pay(30), " -> ", Game.party_silver())
	for c in Game.party:
		c.xp = 0
	_simulate()
	Game.party = keep_party
	Game.roster = keep_roster
	Game.story = keep_story
	Game.location = keep[0]
	Game.known = keep[1]
	Game.town_known = keep[2]
	Game.pos = keep[3]


## The walkable market square: walk up to the crier by the well and hear the notice.
func _market_walk(shots: bool) -> void:
	var m: Node = Game.main
	m.current._on_place("market")
	await get_tree().create_timer(0.8).timeout
	var mk: Node = m.current
	if shots:
		await _shot("24a_market")
	for i in 3:
		mk._walk(0)
		await get_tree().create_timer(0.3).timeout
	if shots:
		await _shot("24b_market_crier")
	mk._walk(0)   # into the crier: a talk
	await get_tree().create_timer(0.4).timeout
	for ch in mk.get_children():
		for g in ch.get_children():
			if g is DialogueBox:
				g.skip_to_choice()
				if shots:
					await _shot("24c_market_talk")
				g.finished.emit()
				await get_tree().process_frame
				if is_instance_valid(g) and g.is_inside_tree():
					g.finished.emit()   # the Goodbye button
	await get_tree().create_timer(0.3).timeout
	print("market: at ", mk.area.pos, " known ", Game.known, " town ", Game.town_known.get("lehan", []))
	if shots:
		mk._turn(-1)
		await get_tree().create_timer(0.4).timeout
		await _shot("24d_market_west")
		mk._turn(-1)
		await get_tree().create_timer(0.4).timeout
		await _shot("24e_market_south")
		mk._turn(-1)
		await get_tree().create_timer(0.4).timeout
		mk._walk(0)
		mk._walk(0)
		await get_tree().create_timer(0.5).timeout
		await _shot("24f_market_east")
		mk.map_btn.button_pressed = true
		mk._on_map()
		await get_tree().create_timer(0.3).timeout
		await _shot("24g_town_plan")
		print("plan spots: ", mk.plan.spots.keys())
		mk._travel("inn")
		await get_tree().create_timer(0.4).timeout
		await _shot("24h_at_inn")
		print("travel inn: at ", mk.area.pos, " facing ", mk.area.facing, " ahead ", mk.area.thing_at(mk.area.ahead()))
		mk._travel("hideout")
		await get_tree().create_timer(0.4).timeout
		await _shot("24i_tanners_row")
		mk._turn(-1)
		await get_tree().create_timer(0.3).timeout
		mk._turn(-1)
		await get_tree().create_timer(0.4).timeout
		await _shot("24j_tanners_row_east")
		mk._travel("smith")
		await get_tree().create_timer(0.4).timeout
		await _shot("24k_at_smith")
		mk._travel("gate")
		await get_tree().create_timer(0.4).timeout
		await _shot("24l_at_gate")


func _run() -> void:
	var m: Node = Game.main
	await _shot("01_about")
	m.goto("title")
	await _shot("02_title")
	m.goto("prologue")
	await get_tree().create_timer(3.2).timeout   # the eyelids, half open
	await _shot("02a_prologue_waking")
	var box: DialogueBox = m.current.box
	for k in 6:
		box._next()
	await get_tree().create_timer(2.6).timeout
	await _shot("02b_prologue_chatter")
	box.skip_to_choice()
	await _shot("02c_prologue_host_choice")
	box.choose(PrologueData.ORDER.find("ithrae"))
	box.skip_to_choice()
	await get_tree().create_timer(1.6).timeout   # let the touch flash fade
	await _shot("02d_prologue_choice")
	box.choose(0)
	box._next()
	await _shot("02e_prologue_after")
	box.open_history()
	await _shot("02f_prologue_history")
	box.close_history()
	Game.new_game()
	Game.party = [_make("Brand", Game.WARRIOR, 0), _make("Oldo", Game.MAGE, 1), _make("Sira", Game.THIEF, 5),
		_make("Tavi", Game.RANGER, 9)]
	Game.roster = [_make("Morn", Game.CLERIC, 12), _make("Fen", Game.MONK, 3)]
	m.goto("inn")
	await _shot("03_inn")
	Game.party[0].items[Game.SLOT_RHAND] = 3
	Game.party[0].items[Game.SLOT_HEAD] = 4
	Game.party[0].items[Game.PACK_FIRST] = 0
	Game.party[0].items[Game.PACK_FIRST + 1] = 0
	m.goto("view", {"party": true, "index": 0})
	await _shot("05_view")
	var vw: Node = m.current
	var c0: Dictionary = Game.party[0]
	c0.items[12] = 30
	c0.items[Game.SLOT_FEET] = 0   # the boots start worn; take them off to test the drop
	c0.items[15] = 7
	var src := Slot.new(); src.slot_id = Game.SLOT_FEET; src.kind = "equip"
	print("fits boots on feet: ", vw.can_drop(vw.slots[Game.SLOT_FEET], {"from": "pack", "src": 15, "item": 7}), " helmet on feet: ", vw.can_drop(vw.slots[Game.SLOT_FEET], {"from": "pack", "src": 15, "item": 4}))
	vw.drop(vw.slots[Game.SLOT_FEET], {"from": "pack", "src": 15, "item": c0.items[15]})
	print("feet now ", c0.items[Game.SLOT_FEET], " pack15 ", c0.items[15])
	c0.health = 1
	var mouth: Slot = null
	for ch in vw.get_children():
		if ch is Slot and ch.kind == "mouth": mouth = ch
	vw.drop(mouth, {"from": "pack", "src": 12, "item": 30})
	print("after cheese health ", c0.health, " log: ", vw.log_label.text)
	src.free()
	Game.location = "lehan"
	m.goto("town")
	await _shot("06_town")
	m.goto("world")
	await _shot("06b_world")
	var hp0: Array = Game.party.map(func(c): return c.health)
	print("travel: ", Game.travel("mines", 1), " endurance ", hp0, " -> ", Game.party.map(func(c): return c.health), " at ", Game.location)
	for i in Game.party.size():
		Game.party[i].health = hp0[i]
	Game.location = "lehan"
	m.goto("shop")
	var sh: Node = m.current
	sh.drop(null, {"item": 32})
	sh.drop(null, {"item": 13})
	sh.drop(null, {"item": 13})
	await _shot("07_shop")
	var before := Game.party_silver()
	await sh._on_pay()
	print("paid: ", before - Game.party_silver(), " expected 14; brand pack: ", Game.party[0].items.slice(10, 28))
	Game.story["mines_entered"] = true   # no arrival scene over the screenshots
	Game.mine_level = 1
	Game.pos = MinesArea.START + Vector2i(2, 0)
	Game.facing = 1
	m.goto("dungeon")
	await _shot("08_dungeon")
	var dg: Node = m.current
	for step in [0, 0, 0]:
		dg._walk(step)
		await get_tree().create_timer(0.3).timeout
	await _shot("09_dungeon_corridor")
	dg._turn(1)
	await get_tree().create_timer(0.3).timeout
	dg._walk(0)
	await get_tree().create_timer(0.3).timeout
	await _shot("10_dungeon_room")
	dg.map_btn.button_pressed = true
	dg._on_map()
	await _shot("11_map")
	dg.map_btn.button_pressed = false
	dg._on_map()
	# --- combat
	_mechanics()
	Game.pos = MinesArea.START
	Game.rng.seed = 7
	dg.start_combat(Combat.new(12))
	await _shot("12_combat_command")
	dg._on_action("attack")
	await _shot("13_combat_target")
	dg._back()
	dg._on_tactics()
	await _shot("14_tactics")
	m._modal_done.emit(true)
	await get_tree().process_frame
	dg._on_defaults()
	await get_tree().create_timer(0.9).timeout
	await _shot("15_combat_resolve")
	dg.auto_btn.button_pressed = true
	dg._on_auto()
	var t := 0
	while dg.combat != null and t < 400:
		await get_tree().create_timer(0.1).timeout
		t += 1
	await _shot("16_combat_end")
	dg.log_view.rtl.get_v_scroll_bar().value = 0
	await _shot("16b_log_scrolled")
	print("combat over, phase '", dg.phase, "' log: ", dg.log_lines.slice(-4))
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().create_timer(0.2).timeout
	if m.current_name != "dungeon":
		print("party lost, now at ", m.current_name)
		get_tree().quit()
		return
	print("save ok: ", Game.save_game("dungeon"))
	var n := Game.party.size()
	Game.new_game()
	print("load -> ", Game.load_game(), " party ", Game.party.size(), "==", n, " pos ", Game.pos, " name ", Game.party[0].name, " items type ", typeof(Game.party[0].items[6]))
	await _new_game_route()
	get_tree().quit()


## New game: prologue -> the road to Lehan with the ambush -> the town map of Lehan.
func _new_game_route() -> void:
	var m: Node = Game.main
	m.goto("prologue", {"new_game": true})
	var box: DialogueBox = m.current.box
	box.skip_to_choice()
	box.choose(PrologueData.ORDER.find("tikkat"))
	box.skip_to_choice()
	box.choose(1)
	box.skip_to_choice()
	await get_tree().create_timer(1.6).timeout
	await _shot("17_prologue_end")
	m.current._on_continue()
	print("company: ", Game.party.map(func(c): return "%s %s %s" % [c.name, Game.RACES[c.race], Game.CLASSES[c.cls]]),
		" at ", Game.location, " known ", Game.known, " story ", Game.story)
	await get_tree().create_timer(3.0).timeout
	await _shot("18_road_chatter")
	var world: Node = m.current
	var rb: DialogueBox = null
	for ch in world.get_children():
		if ch is DialogueBox:
			rb = ch
	rb.skip_to_choice()
	await _shot("19_road_choice")
	rb.choose(0)
	rb.skip_to_choice()
	await get_tree().create_timer(0.5).timeout
	var battle: BattleWindow = null
	for ch in world.get_children():
		if ch is BattleWindow:
			battle = ch
	await _shot("20_ambush")
	var rounds := 0
	while is_instance_valid(battle) and battle.is_inside_tree() and rounds < 40:
		if not battle.spirit_btns[2].disabled:
			# With the host down only "none" is left.
			battle._on_spirit(("ward" if rounds % 2 == 0 else "bless") if not battle.spirit_btns[1].disabled else "none")
			rounds += 1
			if rounds == 2:
				await get_tree().create_timer(0.4).timeout
				await _shot("21_ambush_fight")
		await get_tree().create_timer(0.2).timeout
	print("ambush over after ", rounds, " rounds, hits: ", Game.party.map(func(c): return c.hits))
	await get_tree().create_timer(0.5).timeout
	rb.skip_to_choice()
	await _shot("22a_consent")
	rb.choose(2)    # a pitch that does not suit the host
	rb.skip_to_choice()
	await _shot("22b_consent_retry")
	rb.choose(0)    # one that does
	rb.skip_to_choice()
	await get_tree().create_timer(0.3).timeout
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().create_timer(0.3).timeout
	await _shot("22_road_after")
	print("story after road: ", Game.story, " at ", Game.location)
	await _lehan_arrival()
	m.goto("town")
	await _shot("23_town")
	await _market_walk(true)
	m.goto("town")
	await get_tree().create_timer(0.3).timeout
	await _shot("25_town_smith")
	print("known after market: ", Game.known, " town: ", Game.town_known)
	# Checkpoints (title screen "Start at..." / --start=): each lands where it should.
	for cp in Checkpoints.keys():
		if m.modal_open:
			m._modal_done.emit(true)
		Checkpoints.start(cp, "maera")
		await get_tree().create_timer(1.5).timeout
		await _shot("30_checkpoint_" + cp)
		print("checkpoint %s: screen %s, party %s, roster %d, known %s" % [cp, m.current.get_script().resource_path.get_file(),
			Game.party.map(func(c): return c.name.split(" ")[0]), Game.roster.size(), Game.known])
		if cp.begins_with("mines"):
			print("  level %d at %s: " % [Game.mine_level, Game.pos], Game.party.map(func(c): return "%s %s=%d tough=%d hp=%d xp=%d R=%s H=%s" % [
				c.name.split(" ")[0], Game.best_fighting(c), Game.ability(c, Game.best_fighting(c)), Game.ability(c, "toughness"),
				c.max_hits, c.xp, Game.item(c.items[Game.SLOT_RHAND]).get("name", "-") if c.items[Game.SLOT_RHAND] else "-",
				Game.item(c.items[Game.SLOT_HEAD]).get("name", "-") if c.items[Game.SLOT_HEAD] else "-"]))
	if m.modal_open:
		m._modal_done.emit(true)
	await _council_visits()
	await _lisbet_quest()
	await _boddo_quest()
	await _skee_quest()
	print("tour done")
	get_tree().quit()


## The council house: Joss alone, then Tikkat with the whole company. Tries every argument,
## then accepts.
func _council_visits() -> void:
	var m: Node = Game.main
	for setup in [["joss", false], ["tikkat", true]]:
		Checkpoints.start("council", setup[0])
		await get_tree().create_timer(1.0).timeout
		if setup[1]:
			for c in Game.roster.duplicate():
				for k in ["rejoin", "grudge", "owed"]:
					c.erase(k)
				Game.roster.erase(c)
				Game.party.append(c)
			var st: Node = m.current
			st.area.place_at("market", true)
			st.view.snap()
			await get_tree().create_timer(0.6).timeout
			await _shot("31a_council_front")
		m.goto("council")
		await get_tree().create_timer(1.0).timeout
		var box: DialogueBox = m.current.box
		await _until_choice(box)
		await _shot("31b_council_%s" % setup[0])
		for round in 8:
			var opts: Array = box.choice_step.options
			print("council %s: offer %d patience %d options %s" % [setup[0], Game.story.council.offer,
				Game.story.council.patience, opts.map(func(o): return o.key)])
			var pick := 0
			for i in opts.size():
				if not opts[i].key in ["accept", "leave"]:
					pick = i
					break
			box.choose(pick)
			if opts[pick].key == "accept":
				break
			await _until_choice(box)
		for i in 100:
			if not box.running:
				break
			box.skip_to_choice()
			await get_tree().create_timer(0.1).timeout
		await _shot("31c_council_done_%s" % setup[0])
		print("council %s done: job %s, mines known %s, host silver %d, xp %d" % [setup[0], Game.story.get("mines_job"),
			"mines" in Game.known, Game.party[0].silver, Game.party[0].xp])
		m.goto("council")   # a second visit after the job is taken
		await get_tree().create_timer(1.0).timeout
		m.current.box.skip_to_choice()
		print("council revisit: ", m.current.box.history.slice(-2))


## Drives the newest dialogue box under `node`: skips to each choice and picks from `picks`
## (0 when they run out), until the conversation ends; then presses its closing button.
func _drive(node: Node, picks: Array, shot := "") -> void:
	var box: DialogueBox = null
	for i in 40:
		box = _find_box(node)
		if box:
			break
		await get_tree().create_timer(0.1).timeout
	if box == null:
		print("drive: no dialogue box")
		return
	for i in 400:
		box.skip_to_choice()
		if box.choosing != "":
			if shot != "":
				await _shot(shot)
				shot = ""
			var p: int = picks.pop_front() if picks.size() > 0 else 0
			print("  choice %s: %s" % [box.choosing, box.choice_step.options[p].t])
			box.choose(p)
		elif not box.running:
			break
		await get_tree().create_timer(0.05).timeout
	print("  said: ", box.history.slice(-3))
	if is_instance_valid(box):
		box.finished.emit()   # the Goodbye / closing button
	await get_tree().create_timer(0.4).timeout


func _find_box(node: Node) -> DialogueBox:
	var found: DialogueBox = null
	for ch in node.get_children():
		if ch is DialogueBox and ch.running:
			found = ch
		var deeper := _find_box(ch)
		if deeper:
			found = deeper
	return found


## Lisbet's letter with Tikkat as host: the crier has no news, the offer, the tail on the gate
## road, opening the letter at the gate, back to Lisbet, the crier's notice, mustering Lisbet.
func _lisbet_quest() -> void:
	var m: Node = Game.main
	Checkpoints.start("market", "tikkat")
	await get_tree().create_timer(1.0).timeout
	var st: Node = m.current
	st._talk("1")
	await _drive(st, [])
	print("lisbet: notice before quest? ", Game.story.get("job_notice", false))
	st._talk("2")
	await _drive(st, [0], "32a_lisbet_offer")
	print("lisbet: state ", LehanQuests.state(), " letter with ", Game.holder_of(34).get("name", "nobody"))
	st.area.pos = Vector2i(11, 11)
	st.area.facing = 2
	st.view.snap()
	st._walk(0)
	await get_tree().create_timer(0.8).timeout
	await _drive(st, [3], "32b_lisbet_tail")   # the spirit's help
	print("lisbet: after tail ", LehanQuests.state())
	st.area.pos = Vector2i(11, 17)
	st.area.facing = 1
	st.view.snap()
	st._talk("7")
	await _drive(st, [1], "32c_lisbet_seal")   # open it
	print("lisbet: after gate ", LehanQuests.state(), " purse ", Game.story.get("council_purse", false),
		" letter with ", Game.holder_of(34).get("name", "nobody"))
	st._travel("market")
	st._talk("2")
	await _drive(st, [0], "32d_lisbet_back")
	await get_tree().create_timer(1.0).timeout
	st = m.current
	print("lisbet: done ", LehanQuests.state(), " roster ", Game.roster.map(func(c): return [c.name, c.get("fee", -1)]),
		" silver ", Game.party_silver(), " gone ", st.gone_at_start, " at ", st.area.pos)
	st.area.pos = Vector2i(13, 6)
	st.area.facing = 0
	st.view.snap()
	await get_tree().create_timer(0.6).timeout
	await _shot("32e_square_without_lisbet")
	st._on_party()
	await get_tree().create_timer(0.6).timeout
	await _shot("32e2_party_from_streets")
	m.current._on_leave()
	await get_tree().create_timer(1.0).timeout
	st = m.current
	print("party button: back at ", st.area.pos, " facing ", st.area.facing)
	st._talk("1")
	await _drive(st, [])
	print("lisbet: notice after quest? ", Game.story.get("job_notice", false), " town ", Game.town_places("lehan"))
	m.goto("inn")
	await get_tree().create_timer(0.6).timeout
	var inn: Node = m.current
	for i in Game.roster.size():
		if Game.roster[i].name == "Lisbet Farrow":
			inn.chosen = i
	inn._on_muster()
	await _drive(inn, [0], "32f_lisbet_muster")
	await get_tree().create_timer(0.4).timeout
	await _shot("32g_inn_with_lisbet")
	print("lisbet: party ", Game.party.map(func(c): return c.name), " silver ", Game.party_silver())
	m.goto("council")
	await get_tree().create_timer(1.0).timeout
	var box: DialogueBox = m.current.box
	await _until_choice(box)
	print("lisbet: council options ", box.choice_step.options.map(func(o): return o.key))
	var pi := 0
	for i in box.choice_step.options.size():
		if box.choice_step.options[i].key == "purse":
			pi = i
	box.choose(pi)
	await _until_choice(box)
	await _shot("32h_council_purse")
	print("lisbet: council offer after purse ", Game.story.council.offer)


## Boddo's debt with Joss as host: the offer, the warehouse (tried until it ends), back to Boddo.
## Then, with the job cried, Maera grumbles about errands at Lisbet's offer.
func _boddo_quest() -> void:
	var m: Node = Game.main
	Checkpoints.start("market", "joss")
	await get_tree().create_timer(1.0).timeout
	var st: Node = m.current
	st._talk("4")
	await _drive(st, [0], "33a_boddo_offer")
	print("boddo: state ", LehanQuests.state(), " places ", Game.town_places("lehan"))
	for visit in 6:
		var q := LehanQuests.get_q("boddo")
		if q != "proof" and q != "found":
			break
		st._travel("warehouse")
		await get_tree().create_timer(0.5).timeout
		if visit == 0:
			await _shot("33b_warehouse_door")
		st._use_ahead()
		await _drive(st, [0], "33c_warehouse_%d" % visit)
		print("boddo: visit %d -> %s" % [visit, LehanQuests.state()])
	st._travel("market")
	st._talk("4")
	await _drive(st, [0], "33d_boddo_back")
	await get_tree().create_timer(1.0).timeout
	st = m.current
	print("boddo: end ", LehanQuests.state(), " roster ", Game.roster.map(func(c): return c.name),
		" silver ", Game.party_silver(), " hits ", Game.party.map(func(c): return c.hits))
	st._talk("1")
	await _drive(st, [])
	for c in Game.roster.duplicate():
		if c.name == "Maera Vell":
			for k in ["rejoin", "grudge", "owed"]:
				c.erase(k)
			Game.roster.erase(c)
			Game.party.append(c)
	st._talk("2")
	await _drive(st, [3], "33e_errand_comment")


## Skee's lights with Ithrae as host (Lore and Magic): the offer, the tannery, the tunnels (the
## bag, the rats, the collapse, the lights), climbing out, and persuading Skee.
func _skee_quest() -> void:
	var m: Node = Game.main
	Checkpoints.start("market", "ithrae")
	await get_tree().create_timer(1.0).timeout
	var st: Node = m.current
	st._talk("3")
	await _drive(st, [0], "34a_skee_offer")
	for visit in 6:
		if SkeeQuest.way_open():
			break
		st = m.current
		st._travel("tannery")
		await get_tree().create_timer(0.4).timeout
		if visit == 0:
			await _shot("34b_tannery_door")
		st._use_ahead()
		await _drive(st, [0], "34c_tannery" if visit == 0 else "")
		await get_tree().create_timer(0.8).timeout
		print("skee: tannery visit %d -> %s" % [visit, LehanQuests.state()])
	await get_tree().create_timer(1.0).timeout
	print("skee: screen ", m.current.get_script().resource_path.get_file())
	await _shot("34d_tunnels_start")
	# Skee's bag.
	await _tunnel_step(Vector2i(9, 7), 2)
	await _drive(m.current, [])
	await get_tree().create_timer(1.0).timeout
	await _quest_item_check(36)
	# The rats, until they're dealt with.
	for i in 6:
		if SkeeQuest.rats_done():
			break
		await _tunnel_step(Vector2i(7, 3), 1)
		await _drive(m.current, [i % 3], "34e_rats" if i == 0 else "")
		await get_tree().create_timer(1.0).timeout
		print("skee: rats try %d -> done %s at %s" % [i, SkeeQuest.rats_done(), m.current.area.pos])
	# The collapse.
	for i in 6:
		if SkeeQuest.collapse_passed():
			break
		await _tunnel_step(Vector2i(11, 5), 2)
		await _drive(m.current, [i % 2], "34f_collapse" if i == 0 else "")
		await get_tree().create_timer(1.0).timeout
		print("skee: collapse try %d -> passed %s" % [i, SkeeQuest.collapse_passed()])
	await _tunnel_step(Vector2i(11, 9), 2)
	await get_tree().create_timer(0.6).timeout
	await _drive(m.current, [0], "34g_lights")
	await get_tree().create_timer(1.0).timeout
	print("skee: after lights ", LehanQuests.state(), " hits ", Game.party.map(func(c): return c.hits))
	await _tunnel_step(Vector2i(2, 1), 3)   # climb the ladder
	await get_tree().create_timer(1.0).timeout
	st = m.current
	print("skee: climbed out to ", st.get_script().resource_path.get_file(), " at ", st.area.pos)
	for i in 6:
		if LehanQuests.done("skee"):
			break
		st = m.current
		st._travel("market")
		st._talk("3")
		await _drive(st, [0], "34h_skee_persuade" if i == 0 else "")
		await get_tree().create_timer(1.0).timeout
	print("skee: end ", LehanQuests.state(), " roster ", Game.roster.map(func(c): return c.name),
		" bag with ", Game.holder_of(36).get("name", "nobody"), " shard with ", Game.holder_of(37).get("name", "nobody"))
	await _quest_log_check()


## A quest item: who carries it, the pack on the character screen, and that Trash refuses it.
func _quest_item_check(id: int) -> void:
	var m: Node = Game.main
	var c := Game.holder_of(id)
	print("item %d (%s) with %s" % [id, Game.item(id).name, c.get("name", "nobody")])
	if c.is_empty():
		return
	var back: String = m.current_name
	var back_args := {}
	if "area" in m.current:
		back_args = {"at_cell": [m.current.area.pos.x, m.current.area.pos.y], "facing": m.current.area.facing}
	m.goto("view", {"party": true, "index": Game.party.find(c), "back": back, "back_args": back_args})
	await get_tree().create_timer(0.6).timeout
	var v: Node = m.current
	await _shot("35a_quest_item_in_pack")
	var trash: Slot = null
	for ch in v.get_children():
		if ch is Slot and ch.kind == "trash":
			trash = ch
	await v.drop(trash, {"item": id, "src": c.items.find(id), "from": "pack"})
	print("trash quest item: '%s' still with %s" % [v.log_label.text, Game.holder_of(id).get("name", "nobody")])
	v._on_leave()
	await get_tree().create_timer(1.0).timeout


## The quest log over the streets: the first quest, then Lisbet's.
func _quest_log_check() -> void:
	var m: Node = Game.main
	m.current._on_quests()
	await get_tree().create_timer(0.6).timeout
	var log: QuestLog = null
	for ch in m.get_children():
		if ch is QuestLog:
			log = ch
	print("quest log: ", Journal.listed().map(func(q): return [q.key, Journal.status(q.key), Journal.scenes(q.key).size()]))
	await _shot("35b_quest_log")
	for sc in Journal.scenes("skee"):
		for l in sc.lines:
			if "▸" in l:
				print("  log choice [%s]: %s" % [sc.place, l])
	log.text.scroll_to_line(log.text.get_line_count() - 1)
	await get_tree().create_timer(0.4).timeout
	await _shot("35c_quest_log_end")
	log.close()


## In the tunnels: stand at `from` facing `dir`, and walk forward (into whatever is there).
func _tunnel_step(from: Vector2i, dir: int) -> void:
	var t: Node = Game.main.current
	t.area.pos = from
	t.area.facing = dir
	t.view.snap()
	await get_tree().create_timer(0.3).timeout
	t._walk(0)
	await get_tree().create_timer(0.8).timeout


## Arrival in Lehan with Tikkat as host: the walk, the meeting, palming coins, the split, and
## talking a companion round at the inn.
## Runs the dialogue on until it waits for a choice (the company may still be walking).
func _until_choice(box: DialogueBox) -> void:
	for i in 300:
		box.skip_to_choice()
		if box.choosing != "":
			return
		await get_tree().create_timer(0.1).timeout


func _lehan_arrival() -> void:
	var m: Node = Game.main
	m.goto("streets")
	await get_tree().create_timer(4.0).timeout
	await _shot("23a_lehan_walk")
	var town: Node = m.current
	var box: DialogueBox = null
	for ch in town.get_children():
		if ch is DialogueBox:
			box = ch
	# A left click on the conversation moves it on (as Space does).
	var before: int = box.idx
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = box.global_position + Vector2(300, 50)
		click.global_position = click.position
		get_viewport().push_input(click)
	await get_tree().process_frame
	print("click on dialogue: line ", before, " -> ", box.idx)
	await _until_choice(box)
	await _shot("23b_lehan_night")
	box.choose(1)     # "The stone was warm."
	await _until_choice(box)
	await _shot("23c_lehan_pocket")
	box.choose(0)     # palm a few coins
	# On through the meeting and the walk to the inn, to the "Go into the inn" button.
	for i in 400:
		box.skip_to_choice()
		if town.area.pos == LehanStreets.PATH_TO_INN[-1] and not box.running:
			break
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(1.0).timeout
	await _shot("23d_lehan_parting")
	print("arrival walk ended at ", town.area.pos, " facing ", town.area.facing)
	print("lehan: ", Game.story.get("lehan"), " party ", Game.party.map(func(c): return c.name),
		" roster ", Game.roster.map(func(c): return "%s:%s:%s" % [c.name, c.get("rejoin", ""), c.get("owed", 0)]))
	m.goto("inn", {"split": true})
	await get_tree().create_timer(0.4).timeout
	await _shot("23e_inn_split")
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().process_frame
	# No job yet: they turn the host down.
	var inn: Node = m.current
	inn.chosen = 0
	inn._on_muster()
	await get_tree().create_timer(0.3).timeout
	await _shot("23e2_no_job")
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().create_timer(0.3).timeout
	print("before the job: party ", Game.party.map(func(c): return c.name))
	# Hear the crier in the market (after a Lehan quest, here just marked done), then try again.
	LehanQuests.state()["lisbet"] = "done"
	m.goto("town")
	await get_tree().process_frame
	await _market_walk(false)
	m.goto("inn")
	await get_tree().process_frame
	inn = m.current
	inn.chosen = 0
	inn._on_muster()
	await get_tree().create_timer(0.3).timeout
	var tb: DialogueBox = null
	for ch in inn.get_children():
		for g in ch.get_children():
			if g is DialogueBox:
				tb = g
	tb.skip_to_choice()
	await _shot("23f_rejoin_talk")
	tb.choose(0)
	tb.skip_to_choice()
	await get_tree().create_timer(0.3).timeout
	tb.finished.emit()
	await get_tree().create_timer(0.3).timeout
	await _shot("23g_rejoined")
	print("after talk: party ", Game.party.map(func(c): return c.name), " purse ", Game.party_silver())
	_lehan_all_hosts()


## Runs the settle/parting/talk code for every host and twist, to catch errors.
func _lehan_all_hosts() -> void:
	var saved_party := Game.party
	var saved_roster := Game.roster
	var saved_story := Game.story
	var saved := [Game.location, Game.known, Game.town_known, Game.visited, Game.pos, Game.facing]
	var cases := {
		"joss": [{}, {"split": "double"}, {"split": "docked", "answer": "lie"}],
		"maera": [{"stood_up": "calm", "split": "even"}, {"stood_up": "angry", "split": "even"}, {"saw_cart": "yes"}],
		"ommuk": [{"proof": "head", "gift": "tikkat"}, {"proof": "kept", "gift": "temple"}, {"calmed": "yes"}],
		"ithrae": [{"mark": "yes", "called_out": "yes", "split": "even"}, {}],
		"tikkat": [{"pocket": "yes", "noticer": "joss"}, {"pocket": "yes", "noticer": "ithrae"}, {}],
	}
	for host in cases:
		for fx in cases[host]:
			Game.start_company(host, 1)
			LehanData.walk(host)
			LehanData.meeting(host)
			for k in fx:
				LehanData.record("%s=%s" % [k, fx[k]])
			LehanData.settle(host)
			LehanData.parting(host)
			var moods := []
			for c in Game.party:
				if c.has("rejoin"):
					var key := ""
					for k2 in PrologueData.ORDER:
						if PrologueData.CAST[k2].name == c.name:
							key = k2
					LehanData.rejoin_talk(key, c, host, 5000)
					moods.append("%s:%s%s" % [key, c.rejoin, (":" + c.grudge) if c.grudge != "" else ""])
			print("host %s %s -> shares %s moods %s" % [host, fx, Game.story.lehan.shares, moods])
	Game.party = saved_party
	Game.roster = saved_roster
	Game.story = saved_story
	Game.location = saved[0]
	Game.known = saved[1]
	Game.town_known = saved[2]
	Game.visited = saved[3]
	Game.pos = saved[4]
	Game.facing = saved[5]

# ---------------------------------------------------------------- the mines

## The mines job on the real dungeon screen: every level, the puzzles, a few fights, the miners,
## Saelen, the Warden (and running from it), then the report at the council.
func _mines_part() -> void:
	var m: Node = Game.main
	Checkpoints.start("mines", "ithrae")
	for c in Game.party:   # a sturdier company, so the tour doesn't end at the inn
		c.abilities.combat += 2
		c.abilities.toughness += 2
		Game.update_derived(c)
		c.hits = c.max_hits
	await get_tree().create_timer(1.0).timeout
	await _drive(m.current, [], "40a_mines_arrival")
	await _shot("40b_mines_entrance")
	var dg: Node = m.current
	dg.map_btn.button_pressed = true
	dg._on_map()
	await _shot("40c_mines_map")
	dg.map_btn.button_pressed = false
	dg._on_map()
	# A click on a portrait opens the character sheet; Leave comes back to the same square.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var was: Vector2i = Game.pos
	dg._on_portrait_input(click, 1)
	await get_tree().create_timer(0.6).timeout
	await _shot("40c2_sheet_from_mines")
	m.current._on_leave()
	await get_tree().create_timer(0.6).timeout
	print("mines: sheet and back: ", m.current.name, " at ", Game.pos, " (was ", was, ")")
	# Esc closes things: the map, the character sheet, a dialog.
	var esc := func() -> void:
		var k := InputEventKey.new()
		k.keycode = KEY_ESCAPE
		k.pressed = true
		Input.parse_input_event(k)
		await get_tree().create_timer(0.3).timeout
	m.current.map_btn.button_pressed = true
	m.current._on_map()
	await get_tree().create_timer(0.3).timeout
	await esc.call()
	print("esc: map open after Esc: ", m.current.map_mode)
	m.current._on_portrait_input(click, 0)
	await get_tree().create_timer(0.6).timeout
	await esc.call()
	await get_tree().create_timer(0.4).timeout
	print("esc: back from the sheet on ", m.current.get_script().resource_path.get_file())
	m.choose.call("Esc test", ["One", "Two"])   # not awaited: Esc should close it
	await get_tree().create_timer(0.3).timeout
	await esc.call()
	print("esc: dialog open after Esc: ", m.modal_open)
	# Level 1: the kobolds, their chest, the camp chest, the points lever and the cart, the stash.
	await _mine_step(1, Vector2i(5, 1), 3)
	await _mine_fight("40d_kobolds")
	await _mine_use(1, Vector2i(2, 1), 3, [])
	await _mine_use(1, Vector2i(14, 7), 0, [], "40e_camp_chest")
	await _mine_use(1, Vector2i(3, 10), 3, [2], "40f_cart")
	await _mine_use(1, Vector2i(14, 10), 1, [0])
	await _mine_use(1, Vector2i(3, 10), 3, [])
	for i in 8:
		if LehanQuests.get_q("m_secret") != "":
			break
		await _mine_at(1, Vector2i(16, 3), 0)
		m.current._on_examine()
		await get_tree().create_timer(0.4).timeout
		if m.modal_open:
			m._modal_done.emit(true)
		await get_tree().create_timer(0.8).timeout
	await _mine_use(1, Vector2i(16, 2), 0, [])
	print("mines L1: ", _mines_state(), " items ", _mine_items())
	# The tour jumps from place to place; mark every square walked over, as a player would have.
	for y in 18:
		for x in 18:
			if MinesArea.walkable(1, Vector2i(x, y)):
				Game.visited[Vector3i(x, y, 1)] = true
	m.current.map_btn.button_pressed = true
	m.current._on_map()
	await _shot("40h_map_explored")
	m.current.map_btn.button_pressed = false
	m.current._on_map()
	# Down to level 2.
	await _mine_at(1, Vector2i(2, 10), 3)
	m.current._walk(0)
	await get_tree().create_timer(1.2).timeout
	await _drive(m.current, [], "41a_level2_arrival")
	await _mine_at(2, Vector2i(7, 7), 0)
	await _shot("41b_bad_air")
	m.current._walk(0)
	await _drive(m.current, [])
	await get_tree().create_timer(1.0).timeout
	await _mine_step(2, Vector2i(14, 16), 1)
	await _drive(m.current, [], "41c_breach")
	await get_tree().create_timer(1.0).timeout
	await _mine_use(2, Vector2i(14, 3), 0, [])
	await _mine_use(2, Vector2i(15, 1), 1, [], "41d_stores")
	await _mine_use(2, Vector2i(3, 5), 1, [])
	await _mine_use(2, Vector2i(9, 15), 3, [0])   # the drain first: it floods back
	await _mine_use(2, Vector2i(11, 15), 2, [0])
	await _mine_use(2, Vector2i(9, 15), 3, [0])
	await _mine_at(2, Vector2i(12, 15), 0)
	await _shot("41e_drained")
	await _mine_use(2, Vector2i(11, 13), 3, [0], "41f_survivors")
	await _mine_step(2, Vector2i(5, 11), 1)
	await _mine_fight("41g_delvers")
	print("mines L2: ", _mines_state(), " items ", _mine_items())
	# Up the ladder, fit the crank to the lift, and ride it back down.
	await _mine_at(2, Vector2i(2, 1), 3)
	m.current._walk(0)
	await get_tree().create_timer(1.5).timeout
	print("mines: up the ladder to level ", Game.mine_level, " at ", Game.pos)
	await _mine_use(1, Vector2i(16, 14), 0, [], "40g_lift")
	await _mine_use(1, Vector2i(16, 14), 0, [0])
	await get_tree().create_timer(1.5).timeout
	print("mines: the lift took us to level ", Game.mine_level, " at ", Game.pos)
	# Level 3.
	await _mine_at(2, Vector2i(15, 16), 1)
	m.current._walk(0)
	await get_tree().create_timer(1.5).timeout
	await _drive(m.current, [], "42a_level3_arrival")
	await _mine_use(3, Vector2i(6, 7), 2, [0])
	await _mine_use(3, Vector2i(1, 7), 0, [0], "42b_pillar")
	await _mine_use(3, Vector2i(5, 7), 0, [0])
	await _mine_use(3, Vector2i(3, 7), 0, [0])
	await _mine_use(3, Vector2i(14, 5), 1, [], "42c_armoury")
	await _mine_use(3, Vector2i(14, 5), 3, [])
	for i in 4:
		if LehanQuests.get_q("m_saelen") == "home":
			break
		await _mine_use(3, Vector2i(6, 5), 3, [1 if i < 2 else 3], "42d_saelen" if i == 0 else "")
	await _mine_at(3, Vector2i(8, 3), 0)
	await _shot("42e_warden")
	m.current._walk(0)
	await _drive(m.current, [0])
	await get_tree().create_timer(1.0).timeout
	dg = m.current
	var fled := false
	for i in 200:
		if dg.combat == null:
			break
		if dg.phase == "command":
			if i > 0 and not fled:
				await _shot("42f_warden_fight")
				dg._on_action("flee")
				fled = true
			dg._on_defaults()
		if m.modal_open:
			m._modal_done.emit(true)
		await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(0.8).timeout
	await _drive(m.current, [])
	print("mines L3: ", _mines_state(), " warden ", LehanQuests.get_q("m_warden"), " hits ", Game.party.map(func(c): return c.hits))
	# Out by the lift and the entrance, and to the council.
	await _mine_use(3, Vector2i(15, 11), 1, [0])
	await get_tree().create_timer(1.5).timeout
	await _mine_at(1, Vector2i(12, 16), 2)
	m.current._walk(0)
	await get_tree().create_timer(0.6).timeout
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().create_timer(1.0).timeout
	print("mines: left to ", m.current.get_script().resource_path.get_file(), " marsh known ", "marsh_shrine" in Game.known)
	await _shot("43a_world_marsh")
	Game.location = "lehan"
	m.goto("council")
	await _drive(m.current, [0], "43b_report")
	print("mines: report -> roster ", Game.roster.map(func(c): return c.name), " journal ", Journal.status("mines"),
		" seal told ", LehanQuests.get_q("m_seal_told"), " fails ", LehanQuests.fails("mines"))
	await _mines_will()
	print("mines part done")


## Daring to stay and death, on the dungeon screen: a companion wavering, one fled, one dead, the
## Rally button; then a fight lost with the host dead ends the game.
func _mines_will() -> void:
	var m: Node = Game.main
	Game.location = "mines"
	Game.mine_level = 1
	Game.pos = MinesArea.START + Vector2i(2, 0)
	Game.facing = 1
	m.goto("dungeon", {"resume": true})
	await get_tree().create_timer(0.8).timeout
	var dg: Node = m.current
	var c := Combat.new(0, [{"key": "sworn_knight", "n": 1}, {"key": "oathbound", "n": 3}])
	dg.start_combat(c)
	await get_tree().create_timer(0.5).timeout
	var host := c.host_index()
	var others := []
	for i in Game.party.size():
		if i != host:
			others.append(i)
	c.waver[others[0]] = true
	c.gone[others[1]] = true
	Game.party[others[2]].hits = -2
	c.fell[others[2]] = true
	dg._refresh_party()
	dg._show_command()
	await get_tree().create_timer(0.4).timeout
	await _shot("44a_will_states")
	print("will: rally targets for ", Game.party[dg.cur].name, ": ", c.rally_targets(dg.cur).map(func(i): return Game.party[i].name),
		" rally enabled ", not dg.act_buttons["rally"].disabled, " pressure ", others.map(func(i): return c.pressure(i)),
		" nerve ", others.map(func(i): return c.nerve(i)))
	# The host dies: the game is over.
	Game.party[host].hits = -20
	c.dead[host] = true
	dg._end_combat("lost")
	await get_tree().create_timer(0.8).timeout
	await _shot("44b_game_over")
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().create_timer(0.6).timeout
	print("will: after the host died: ", m.current.get_script().resource_path.get_file())
	get_tree().quit()


## Stands the party on a square of a level, facing a way, with the view rebuilt.
func _mine_at(lv: int, cell: Vector2i, dir: int) -> void:
	Game.mine_level = lv
	Game.pos = cell
	Game.facing = dir
	Game.main.goto("dungeon", {"resume": true})
	await get_tree().create_timer(0.6).timeout


## Steps forward from a square (onto a placed group, a breach, ...).
func _mine_step(lv: int, from: Vector2i, dir: int) -> void:
	await _mine_at(lv, from, dir)
	Game.main.current._walk(0)
	await get_tree().create_timer(0.8).timeout


## Uses what is ahead and plays the scene with the given choices.
func _mine_use(lv: int, cell: Vector2i, dir: int, picks: Array, shot := "") -> void:
	await _mine_at(lv, cell, dir)
	Game.main.current._on_examine()
	await _drive(Game.main.current, picks, shot)
	await get_tree().create_timer(1.0).timeout


## Lets a fight play out on its own (Auto), closing the victory message.
func _mine_fight(shot := "") -> void:
	var dg: Node = Game.main.current
	if dg.combat == null:
		print("mines: no fight")
		return
	if shot != "":
		await _shot(shot)
	dg.auto_btn.button_pressed = true
	dg._on_auto()
	for i in 300:
		if Game.main.current != dg or dg.combat == null:
			break
		if dg.phase == "command":
			dg._on_defaults()
		await get_tree().create_timer(0.2).timeout
	for i in 10:
		if Game.main.modal_open:
			Game.main._modal_done.emit(true)
		await get_tree().create_timer(0.2).timeout
	print("mines: fight over, screen ", Game.main.current.get_script().resource_path.get_file(), " hits ", Game.party.map(func(c): return c.hits))


func _mines_state() -> Dictionary:
	var st := {}
	for k in LehanQuests.state():
		if str(k).begins_with("m_"):
			st[k] = LehanQuests.state()[k]
	return st


func _mine_items() -> Array:
	var out := []
	for c in Game.party:
		for s in range(1, 31):
			if c.items[s] >= 38:
				out.append(Game.item(c.items[s]).name)
	return out
