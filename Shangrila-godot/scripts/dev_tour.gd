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


func _make(nm: String, cls: int, icon: int) -> Dictionary:
	var c := Game.blank_character()
	c.icon = icon
	for i in 500:
		Game.roll_character(c)
		if Game.class_allowed(c, cls):
			break
	Game.set_class(c, cls)
	Game.finish_character(c, nm)
	return c


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
	var before := Game.party_copper()
	await sh._on_pay()
	print("paid: ", before - Game.party_copper(), " expected 740; brand pack: ", Game.party[0].items.slice(10, 28))
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
	_simulate()
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
		if not battle.spirit_btns[1].disabled:
			battle._on_spirit("ward" if rounds % 2 == 0 else "bless")
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
