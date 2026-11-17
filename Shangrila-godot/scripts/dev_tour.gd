extends Node
## Developer aid: `godot --path . -- --tour=<dir>` visits every screen and saves screenshots.

var out := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tour="):
			out = a.substr(7)
	_run.call_deferred()


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
	Game.pos = Vector2i(17, 17)
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
	m.current._on_place("market")
	await get_tree().create_timer(0.3).timeout
	await _shot("24_market_notice")
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().create_timer(0.2).timeout
	if m.modal_open:
		m._modal_done.emit(true)
	await get_tree().create_timer(0.3).timeout
	await _shot("25_town_smith")
	print("known after market: ", Game.known, " town: ", Game.town_known)


## Arrival in Lehan with Tikkat as host: the walk, the meeting, palming coins, the split, and
## talking a companion round at the inn.
func _lehan_arrival() -> void:
	var m: Node = Game.main
	m.goto("town")
	await get_tree().create_timer(3.0).timeout
	await _shot("23a_lehan_walk")
	var town: Node = m.current
	var box: DialogueBox = null
	for ch in town.get_children():
		if ch is DialogueBox:
			box = ch
	box.skip_to_choice()
	await _shot("23b_lehan_night")
	box.choose(1)     # "The stone was warm."
	box.skip_to_choice()
	await _shot("23c_lehan_pocket")
	box.choose(0)     # palm a few coins
	box.skip_to_choice()
	await get_tree().create_timer(4.0).timeout
	box.skip_to_choice()
	await get_tree().create_timer(1.0).timeout
	await _shot("23d_lehan_parting")
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
	# Hear the crier in the market, then try again.
	m.goto("town")
	await get_tree().process_frame
	m.current._on_place("market")
	for i in 2:
		await get_tree().create_timer(0.3).timeout
		if m.modal_open:
			m._modal_done.emit(true)
	await get_tree().create_timer(0.2).timeout
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
