extends Control
## DungeonWin - exploring the mines (MinesArea, MinesQuest), and fighting in them.
## Keys: W/Up forward, S/Down back, A/Left turn left, D/Right turn right,
## Q/E step sideways, Space use or examine what is ahead, M map, J quests.
## Args: {"resume": true} after a scene changed something (the view is rebuilt), {"arrived": how}
## after moving to another level.
## In combat: A Attack, P Parry, S Spell, U Use, E Equip, T Turn, F Flee, H Hide, X Pass,
## D Defaults, Esc back/cancel, Space hurry up.

const ENCOUNTER_CHANCE := 12      # percent per step
const QUIET_STEPS := 3            # steps after a fight before the next one can start
const ACTS := ["attack", "parry", "spells", "use", "equip", "turn", "rally", "flee", "hide", "pass"]
const ACT_LABELS := ["Attack", "Parry", "Spells", "Use", "Equip", "Turn", "Rally", "Flee", "Hide", "Pass"]
const ACT_KEYS := {KEY_A: "attack", KEY_P: "parry", KEY_S: "spells", KEY_U: "use", KEY_E: "equip",
	KEY_T: "turn", KEY_R: "rally", KEY_F: "flee", KEY_H: "hide", KEY_X: "pass"}
const ACT_TIPS := {
	"attack": "Attack a group with the weapon in hand (A)", "parry": "Defend: harder to hit this round (P)",
	"spells": "Cast this character's spell (S)", "use": "Eat or drink something from the pack (U)",
	"equip": "Ready a weapon from the pack (E)", "turn": "Turn undead - clerics and paladins (T)",
	"flee": "Try to get the party away (F)", "hide": "Slip into the shadows; next attack hits twice as hard (H)",
	"pass": "Do nothing (X)",
	"rally": "Steady a wavering friend, or call back one who has fled (R)",
}

var view: DungeonView
var view_rect: TextureRect
var automap: Automap
var compass: Compass
var log_lines: Array[String] = []
var log_view: LogView
var map_mode := false
var masked_in_map := []
var map_btn: Button

# party display
var ports: Array = []
var bars: Array = []
var order_labels: Array = []

# combat
var combat: Combat = null
var enemy_panel: EnemyPanel
var act_buttons := {}
var status_label: Label
var defaults_btn: Button
var tactics_btn: Button
var auto_btn: Button
var orders := {}
var cur := -1          # party index being given orders
var pending := ""      # action waiting for a target
var phase := ""        # "", "command", "target", "resolve"
var auto := false
var fast := false      # hurry the current round
var steps_quiet := 0
var last_pos := Game.pos
var area := MinesArea.new()
var talking := false
var came_from := Game.pos   # the square before the last step (running from a placed group goes back there)
var combat_tag := ""        # what the fight is: a placed group's key, "warden", or "" for wandering monsters
var after_scene := {}       # what a scene asked for, done when it closes: {"travel": [level, how]} / {"fight": "warden"}


func _ready() -> void:
	Ui.stone_background(self)

	view = DungeonView.new()
	view.area = area
	add_child(view)
	view.moved.connect(_after_move)
	Ui.frame(self, Rect2(14, 14, 272, 272), Color.BLACK, Color("#a07a40"), 4)
	view_rect = TextureRect.new()
	view_rect.texture = view.get_texture()
	view_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view_rect.stretch_mode = TextureRect.STRETCH_SCALE
	view_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	view_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view_rect)
	Ui.place(view_rect, Rect2(20, 20, 260, 260))
	automap = Automap.new()
	automap.visible = false
	add_child(automap)
	Ui.place(automap, Rect2(20, 20, 260, 260))
	enemy_panel = EnemyPanel.new()
	enemy_panel.visible = false
	enemy_panel.picked.connect(_on_group_picked)
	add_child(enemy_panel)
	Ui.place(enemy_panel, Rect2(20, 20, 260, 260))

	# Party (DungeonWin 27-32, 50-55).
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		var x := 300 + (i % 2) * 168
		var y := 18 + (i / 2) * 84
		Ui.label(self, c.name, Vector2(x, y), 13, Ui.TEXT, 150)
		var p := Portrait.new()
		add_child(p)
		Ui.place(p, Rect2(x, y + 20, 48, 48))
		p.index = c.icon
		p.tooltip_text = "%s, %s %s (click for the character sheet)" % [c.name, Game.RACES[c.race], Game.CLASSES[c.cls]]
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(_on_portrait_input.bind(i))
		ports.append(p)
		var sb := StatusBars.new()
		add_child(sb)
		Ui.place(sb, Rect2(x + 56, y + 20, 64, 48))
		sb.who = c
		bars.append(sb)
		var ol := Ui.label(self, "", Vector2(x + 122, y + 22), 10, Ui.GOLD, 44)
		ol.clip_text = false
		ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		order_labels.append(ol)

	# Encounters / messages (DungeonWin 9).
	Ui.frame(self, Rect2(10, 292, 266, 128))
	log_view = LogView.new()
	log_view.font_size = 11
	Ui.place(log_view, Rect2(16, 296, 256, 120))   # sized before _ready builds it
	add_child(log_view)
	log_view.tooltip_text = "Mouse wheel: scroll back  ·  Click: hurry the round along"
	log_view.clicked.connect(func(): fast = true)

	compass = Compass.new()
	compass.area = area
	add_child(compass)
	Ui.place(compass, Rect2(289, 276, 101, 101))

	# Movement arrows (DungeonWin 20-25).
	var mv := [["↶", 286, 386, _turn.bind(-1), "Turn left (A / Left)"],
		["↑", 323, 386, _walk.bind(0), "Forward (W / Up)"],
		["↷", 360, 386, _turn.bind(1), "Turn right (D / Right)"],
		["←", 286, 423, _walk.bind(3), "Step left (Q)"],
		["↓", 323, 423, _walk.bind(2), "Back (S / Down)"],
		["→", 360, 423, _walk.bind(1), "Step right (E)"]]
	for m in mv:
		var b := Ui.btn(self, m[0], Rect2(m[1], m[2], 34, 33), m[3], m[4])
		b.add_theme_font_size_override("font_size", 18)
		masked_in_map.append(b)

	# Actions box with the nine combat buttons (DungeonWin 10-18).
	Ui.frame(self, Rect2(416, 290, 216, 62))
	Ui.label(self, "Actions", Vector2(424, 293), 14, Ui.GOLD)
	defaults_btn = _small_btn("Defaults", Rect2(482, 294, 52, 20), _on_defaults,
		"Give everyone who has no order yet their default action, then fight the round (D)")
	tactics_btn = _small_btn("Tactics", Rect2(537, 294, 48, 20), _on_tactics, "Set each character's default action")
	auto_btn = _small_btn("Auto", Rect2(588, 294, 40, 20), _on_auto,
		"Auto-combat: every round uses the default actions and plays out fast")
	auto_btn.toggle_mode = true
	status_label = Ui.label(self, "No enemies in sight.", Vector2(424, 316), 11, Ui.DIM, 204)
	status_label.clip_text = false
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in ACTS.size():
		var b := Ui.btn(self, ACT_LABELS[i], Rect2(419 + (i % 4) * 54, 358 + (i / 4) * 39, 51, 34),
			_on_action.bind(ACTS[i]), ACT_TIPS[ACTS[i]])
		b.add_theme_font_size_override("font_size", 13)
		act_buttons[ACTS[i]] = b

	# Bottom-left buttons (DungeonWin 1-8, 39).
	var bl := [["Close", 10, 36, _on_close, "Leave the mines (from the entrance)"],
		["Save", 48, 32, _on_save, "Save the game"],
		["Load", 82, 32, _on_load, "Load a saved game (what isn't saved is lost)"],
		["Examine", 116, 48, _on_examine, "Use what is ahead, or search the walls around you (Space)"],
		["Sleep", 166, 36, _on_sleep, "Rest: turns endurance into hit points and restores mana (safe at a camp)"],
		["Quests", 204, 40, QuestLog.open, "The quest log: every quest and what was said (J)"]]
	for e in bl:
		var b := Ui.btn(self, e[0], Rect2(e[1], 430, e[2], 32), e[3], e[4])
		b.add_theme_font_size_override("font_size", 10)
		masked_in_map.append(b)
	map_btn = Ui.btn(self, "Map", Rect2(246, 430, 30, 32), _on_map, "Toggle the map (M)")
	map_btn.add_theme_font_size_override("font_size", 10)
	map_btn.toggle_mode = true

	_explore_ui()
	_refresh_party()
	var args: Dictionary = get_meta("args", {})
	Game.visited[Vector3i(Game.pos.x, Game.pos.y, Game.mine_level)] = true
	came_from = Game.pos
	last_pos = Game.pos
	if args.get("resume", false):
		_hint()
		return
	var lv := Game.mine_level
	say("Level %d: %s." % [lv, MinesArea.NAMES[lv - 1].to_lower()] if args.has("arrived") else "You enter the mines. Daylight fades behind you.")
	_hint()
	var first := not Game.mines_entered() if lv == 1 else LehanQuests.get_q("m_reached_%d" % lv) == ""
	if first:
		Game.story["mines_entered"] = true
		LehanQuests.apply("q:m_reached_%d=1" % lv)
		_scene.call_deferred(MinesArea.NAMES[lv - 1], MinesQuest.arrival(lv))


func _small_btn(text: String, r: Rect2, cb: Callable, tip: String) -> Button:
	var b := Ui.btn(self, text, r, cb, tip)
	b.add_theme_font_size_override("font_size", 11)
	return b


func say(t: String) -> void:
	log_lines.append(t)
	while log_lines.size() > 12:
		log_lines.pop_front()
	log_view.add_line(t)


func _refresh_party() -> void:
	for i in Game.party.size():
		var c: Dictionary = Game.party[i]
		bars[i].who = c
		ports[i].modulate = Color(0.45, 0.3, 0.3) if c.hits <= 0 else Color.WHITE
		ports[i].star = combat == null and Game.can_raise(c)
		var t := ""
		if combat == null and c.get("wounded", false):
			t = "Wounded"
		if combat:
			if combat.dead.has(i):
				t = "Dead"
				ports[i].modulate = Color(0.25, 0.22, 0.22)
			elif combat.gone.has(i):
				t = "Coming back" if combat.returning.has(i) else "Fled"
				ports[i].modulate = Color(1, 1, 1, 0.3)
			elif c.hits <= 0:
				t = "Down"
			elif orders.has(i):
				t = Combat.order_text(orders[i], combat)
			if combat.waver.has(i):
				t = ("Wavering\n" + t).strip_edges()
				ports[i].modulate = Color(1.0, 0.62, 0.25)
			if combat.hidden.has(i):
				t = ("Hidden\n" + t).strip_edges()
		order_labels[i].text = t


# ---------------------------------------------------------------- exploring

func _after_move() -> void:
	compass.queue_redraw()
	if talking:
		return
	if Game.pos == last_pos:
		_hint()
		return
	came_from = last_pos
	last_pos = Game.pos
	steps_quiet += 1
	var t := area.thing_at(Game.pos)
	match t.get("kind", ""):
		"group":
			var g: Dictionary = MinesQuest.GROUPS[t.key]
			say(g.intro)
			combat_tag = t.key
			var c := Combat.new(0, g.m)
			c.dark = true
			start_combat(c)
			return
		"note", "trap", "breach":
			_scene.call_deferred({"note": "Something written", "trap": "Careful!", "breach": "The breach"}[t.kind],
				MinesQuest.scene(Game.mine_level, t))
			return
		"camp":
			say("A camp. The party can rest here safely (Sleep).")
			if Game.reach_checkpoint("dungeon"):
				say("(Checkpoint: the game is saved, and you will wake here if the party falls.)")
	if t.get("kind", "") != "camp" and Game.pos != MinesArea.START and steps_quiet > QUIET_STEPS \
			and Game.my_random(1, 100) <= ENCOUNTER_CHANCE:
		combat_tag = ""
		start_combat(Combat.new(Game.depth()))
		return
	_hint()


## What lies ahead, in the status line while exploring.
func _hint() -> void:
	if combat:
		return
	var t := area.thing_at(area.ahead())
	var k: String = t.get("kind", "")
	var text: String = {
		"exit": "Ahead: daylight. The way out (walk on, or Space).",
		"down": "Ahead: a shaft, with a ladder going down.",
		"up": "Ahead: a ladder going up.",
		"lift": "Ahead: the lift.",
		"chest": "Ahead: an open chest." if t.get("done", false) else "Ahead: a chest.",
		"lever": "Ahead: a lever.",
		"cart": "Ahead: an ore cart, jammed across the rails.",
		"air": "Ahead: the air smells wrong.",
		"door": "Ahead: a locked door.",
		"water": "Ahead: the passage is flooded.",
		"ward": "Ahead: a carved stone slab blocks the way.",
		"npc": "Ahead: someone is there.",
		"warden": "Ahead: the Warden, before the gate.",
		"vein": "Ahead: a seam of ore in the rock." if not t.get("done", false) else "",
		"pillar": "Ahead: a carved pillar.",
		"words": "Ahead: words carved in the wall.",
	}.get(k, "")
	status_label.text = text if text != "" else "No enemies in sight."
	status_label.add_theme_color_override("font_color", Ui.TEXT if text != "" else Ui.DIM)


func _turn(d: int) -> void:
	if map_mode or combat or Game.main.modal_open:
		return
	view.turn(d)


## rel: 0 forward, 1 right, 2 back, 3 left - relative to facing.
func _walk(rel: int) -> void:
	if map_mode or combat or talking or Game.main.modal_open or view.busy:
		return
	var dir := (Game.facing + rel) % 4
	if view.step(dir):
		return
	var t := area.thing_at(Game.pos + Game.DIR_VEC[dir])
	if rel == 0 and not t.has("looks") and t.get("kind", "wall") != "wall":
		_use(t)
	else:
		say("A wall blocks the way %s." % Game.DIR_NAMES[dir].to_lower())


## Uses a thing in front of the party.
func _use(t: Dictionary) -> void:
	match t.get("kind", ""):
		"exit":
			_on_close()
		"down", "up":
			var to: int = Game.mine_level + (1 if t.kind == "down" else -1)
			_travel(to, t.kind)
		"", "wall", "secret", "tomb":
			pass
		_:
			_scene(_title(t), MinesQuest.scene(Game.mine_level, t))


func _title(t: Dictionary) -> String:
	return {"chest": "A chest", "lever": "A lever", "cart": "The ore cart", "air": "Bad air", "door": "A locked door",
		"water": "The flooded passage", "ward": "The ward door", "npc": "Survivors" if t.get("ch", "") == "S" else "Saelen",
		"warden": "The Warden", "vein": "A seam of ore", "pillar": "A carved pillar", "words": "Carved words",
		"lift": "The lift"}.get(t.kind, "In the mines")


## Moves the party to another level: down or up a ladder (arriving by the matching way), or by lift.
func _travel(to: int, how: String) -> void:
	var near: String = {"down": "<", "up": ">", "lift": "L"}[how]
	var spot := MinesArea.arrive_near(to, near)
	if spot.is_empty():
		say("At the top of the ladder an ore cart stands jammed across the way. You can't get past it from here." if how == "up"
			else "The way is blocked.")
		return
	say({"down": "You climb down the ladder...", "up": "You climb up the ladder...", "lift": "The lift sinks and rises through the dark..."}[how])
	Game.mine_level = to
	Game.pos = spot[0]
	Game.facing = spot[1]
	Game.main.goto("dungeon", {"arrived": how})


func _unhandled_key_input(e: InputEvent) -> void:
	if not e.is_pressed() or Game.main.modal_open or talking:
		return
	if combat:
		_combat_key(e)
		return
	match e.keycode:
		KEY_W, KEY_UP: _walk(0)
		KEY_S, KEY_DOWN: _walk(2)
		KEY_A, KEY_LEFT: _turn(-1)
		KEY_D, KEY_RIGHT: _turn(1)
		KEY_Q: _walk(3)
		KEY_E: _walk(1)
		KEY_M:
			map_btn.button_pressed = not map_btn.button_pressed
			_on_map()
		KEY_J: QuestLog.open()
		KEY_ESCAPE:
			if not map_mode:
				return
			map_btn.button_pressed = false
			_on_map()
		_: return
	get_viewport().set_input_as_handled()


func _on_map() -> void:
	map_mode = map_btn.button_pressed
	automap.visible = map_mode
	view_rect.visible = not map_mode
	for b in masked_in_map:
		b.disabled = map_mode


func _on_close() -> void:
	if talking or combat:
		return
	if Game.mine_level != 1 or (Game.pos - MinesArea.START).length() > 1.5:
		say("The way out is at the mouth of the mines, on the first level.")
		return
	if await Game.main.confirm("Do you really want to leave the mines?"):
		Game.pos = MinesArea.START   # next time, in again at the entrance
		Game.facing = MinesArea.START_FACING
		Game.main.goto("world")


func _on_save() -> void:
	if talking or combat:
		return
	if await Game.main.save_menu("dungeon"):
		say("Game saved.")


func _on_load() -> void:
	if talking or combat:
		return
	await Game.main.load_menu()


## Uses what is ahead; with nothing there, searches the walls around for anything hidden.
func _on_examine() -> void:
	if talking or combat or view.busy or Game.main.modal_open:
		return
	var t := area.thing_at(area.ahead())
	if t.get("kind", "") not in ["", "wall", "secret", "tomb"]:
		_use(t)
		return
	for d in 4:
		var n: Vector2i = Game.pos + Game.DIR_VEC[d]
		var h := area.thing_at(n)
		if h.get("kind", "") == "secret":
			var eyes := LehanQuests.best("perception")
			if Game.check(eyes, "perception", Game.NORMAL):
				LehanQuests.apply("q:m_secret=1")
				LehanQuests.apply("xp:%s" % LehanQuests.CHECK_XP)
				await Game.main.message("%s taps the wall to the %s. It sounds hollow: loose boards, painted to look like rock. Behind them is a small hidden space." % [eyes.name.split(" ")[0], Game.DIR_NAMES[d].to_lower()])
				Game.main.goto("dungeon", {"resume": true})
				return
	var open := []
	for d in 4:
		if area.can_move(Game.pos, d):
			open.append(Game.DIR_NAMES[d].to_lower())
	say("You search around and find nothing hidden. Passages lead %s." % (", ".join(open) if not open.is_empty() else "nowhere"))


func _on_sleep() -> void:
	if talking or combat:
		return
	var camp: bool = area.thing_at(Game.pos).get("kind", "") == "camp"
	if not camp and Game.my_random(1, 100) <= 30:
		say("The party settles down to rest... but something finds you first!")
		combat_tag = ""
		start_combat(Combat.new(Game.depth()))
		return
	var hungry := []
	for c in Game.party:
		var gain := mini(c.max_hits - c.hits, c.health / 2)
		c.hits += gain
		c.health -= gain * 2
		c.magic = c.max_magic
		if c.hits < c.max_hits:
			hungry.append(c.name)
	_refresh_party()
	say("The party rests by the camp's old fire. Wounds close and mana returns." if camp else "The party rests. Wounds close and mana returns.")
	for l in Game.pass_days(1):
		say(l)
	if Game.party.any(func(c): return c.get("wounded", false)):
		say("A night's sleep doesn't mend a bad wound. That takes days of rest at the inn.")
	if not hungry.is_empty():
		say("%s too hungry to heal fully - eat something." % (" and ".join(hungry) + (" is" if hungry.size() == 1 else " are")))


# ---------------------------------------------------------------- scenes

## A scene in the dialogue window, over the screen. Afterwards the view is rebuilt if anything
## changed in the mines, and whatever the scene asked for (another level, a fight) happens.
func _scene(title: String, lines: Array) -> void:
	if talking or lines.is_empty():
		return
	talking = true
	after_scene = {}
	var host: String = Game.story.get("host", "")
	if host == "":
		lines = lines.filter(func(st): return not st.has("i") and not st.has("sp") and not (st.has("s") and st.s == ""))
	var before := _state()
	var ov := Control.new()
	add_child(ov)
	Ui.place(ov, Rect2(0, 0, 640, 480))
	Ui.frame(ov, Rect2(10, 150, 620, 322), Color("#1a120a"), Color("#a07a40"), 2)
	Ui.label(ov, title, Vector2(22, 156), 15, Ui.GOLD)
	var box := DialogueBox.new()
	box.cast = MinesQuest.cast()
	box.host = host
	box.journal = "mines"
	box.journal_place = "The mines, level %d: %s" % [Game.mine_level, title.to_lower()]
	Ui.place(box, Rect2(20, 180, 600, 286))   # sized before _ready builds it
	ov.add_child(box)
	box.effect.connect(_on_effect)
	box.play(lines)
	await box.finished
	box.show_buttons([["Go on", func(): box.finished.emit()]])
	await box.finished
	ov.queue_free()
	talking = false
	_refresh_party()
	if after_scene.has("travel"):
		_travel(after_scene.travel[0], after_scene.travel[1])
	elif after_scene.has("fight"):
		combat_tag = "warden"
		var c := Combat.new(0, [{"key": "warden", "n": 1}])
		c.lethal = false   # he keeps the gate; he does not hunt the fallen
		c.dark = true
		start_combat(c)
	elif _state() != before:
		Game.main.goto("dungeon", {"resume": true})
	else:
		_hint()


func _on_effect(fx: String) -> void:
	if fx.begins_with("travel:"):
		var p := fx.split(":")
		after_scene = {"travel": [int(p[1]), p[2]]}
	elif fx.begins_with("fight:"):
		after_scene = {"fight": fx.substr(6)}
	else:
		MinesQuest.apply(fx)


## The mines' quest values, to see whether a scene changed anything that shows in the view.
func _state() -> String:
	var parts := []
	var st := LehanQuests.state()
	for k in st:
		if str(k).begins_with("m_"):
			parts.append("%s=%s" % [k, st[k]])
	parts.sort()
	return ",".join(parts)


# ---------------------------------------------------------------- combat UI state

## Exploring: combat buttons masked (MaskCombat), the rest usable.
func _explore_ui() -> void:
	for k in act_buttons:
		act_buttons[k].disabled = true
	defaults_btn.disabled = true
	auto_btn.disabled = true
	tactics_btn.disabled = Game.party.is_empty()
	for b in masked_in_map:
		b.disabled = map_mode
	map_btn.disabled = false
	status_label.text = "No enemies in sight."
	status_label.add_theme_color_override("font_color", Ui.DIM)


func start_combat(c: Combat) -> void:
	combat = c
	orders = {}
	auto = false
	auto_btn.set_pressed_no_signal(false)
	if map_mode:
		map_btn.button_pressed = false
		_on_map()
	for b in masked_in_map:
		b.disabled = true
	map_btn.disabled = true
	auto_btn.disabled = false
	enemy_panel.combat = c
	enemy_panel.visible = true
	status_label.add_theme_color_override("font_color", Ui.TEXT)
	say(("You face %s." if combat_tag != "" else "Something stirs in the dark! You face %s.") % c.describe())
	var host := LehanQuests.host_char() if Game.story.get("host", "") != "" else {}
	if not host.is_empty() and (host.items[Game.SLOT_RHAND] in [46, 47] or host.items[Game.SLOT_LHAND] in [46, 47]):
		say("The jailers' steel is cold in %s's hands. Something inside them recoils from it." % host.name.split(" ")[0])
	for ch in Game.party:
		var w := c.weapon_info(ch)
		if w.name == "fists" and not c.weapon_slots(ch).is_empty():
			say("(%s has no weapon in hand - use Equip.)" % ch.name)
	_new_round()


func _new_round() -> void:
	orders = {}
	_refresh_party()
	if auto:
		_fill_defaults(0)
		_resolve()
		return
	_next_character(-1)


func _next_character(after: int) -> void:
	for i in range(after + 1, Game.party.size()):
		if combat.can_act(i):
			cur = i
			_show_command()
			return
	_resolve()


func _show_command() -> void:
	phase = "command"
	pending = ""
	enemy_panel.targeting = false
	for i in ports.size():
		ports[i].highlight = i == cur
	var av := combat.available(cur)
	for k in act_buttons:
		act_buttons[k].disabled = not av[k]
	var sp := Game.spell_for(Game.party[cur])
	act_buttons["spells"].tooltip_text = ("%s (%d mana): %s (S)" % [sp.name, sp.cost, sp.desc]) if not sp.is_empty() \
		else "%s knows no spells" % Game.party[cur].name
	defaults_btn.disabled = false
	tactics_btn.disabled = false
	status_label.text = "%s: choose an action." % Game.party[cur].name
	_refresh_party()


func _lock_buttons() -> void:
	for k in act_buttons:
		act_buttons[k].disabled = true
	defaults_btn.disabled = true
	tactics_btn.disabled = true


func _on_action(act: String) -> void:
	if phase != "command" or Game.main.modal_open:
		return
	var c: Dictionary = Game.party[cur]
	match act:
		"use", "equip":
			var slots := combat.food_slots(c) if act == "use" else combat.weapon_slots(c)
			var names := slots.map(func(s): return Game.item(c.items[s]).name + (" (%d)" % Game.qty(c, s) if Game.qty(c, s) > 1 else ""))
			var q := "What should %s eat or drink?" % c.name if act == "use" else "Which weapon should %s ready?" % c.name
			var pick: int = await Game.main.choose(q, names)
			if pick < 0 or combat == null:
				return
			orders[cur] = {"act": act, "slot": slots[pick], "item": c.items[slots[pick]]}
			_commit()
		"rally":
			var who := combat.rally_targets(cur)
			if who.size() == 1:
				orders[cur] = {"act": "rally", "target": who[0], "ally": true}
				_commit()
				return
			_ask_target(act, "ally")
		"attack", "spells", "turn":
			var kind := combat.target_kind(cur, act)
			if kind == "enemy":
				var choices := combat.undead_groups() if act == "turn" else combat.alive_groups()
				if choices.size() == 1:
					orders[cur] = {"act": act, "target": choices[0]}
					_commit()
					return
				enemy_panel.filter = combat.is_undead if act == "turn" else Callable()
			_ask_target(act, kind)
		_:
			orders[cur] = {"act": act}
			_commit()


func _ask_target(act: String, kind: String) -> void:
	phase = "target"
	pending = act
	_lock_buttons()
	if kind == "enemy":
		enemy_panel.targeting = true
		status_label.text = "%s: click the monsters to %s. (Esc to go back)" % [Game.party[cur].name, "attack" if act == "attack" else "target"]
	elif act == "rally":
		status_label.text = "%s: click the portrait of the one to rally. (Esc to go back)" % Game.party[cur].name
	else:
		status_label.text = "%s: click the portrait of the one to heal. (Esc to go back)" % Game.party[cur].name


func _on_group_picked(gi: int) -> void:
	if phase != "target":
		return
	orders[cur] = {"act": pending, "target": gi}
	enemy_panel.targeting = false
	_commit()


## A click on a portrait: in a fight, while choosing whom to heal, it picks the target; while
## exploring it opens that character's sheet.
func _on_portrait_input(e: InputEvent, i: int) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	if combat == null:
		if not talking and not view.busy and not Game.main.modal_open:
			Game.main.goto("view", {"party": true, "index": i, "back": "dungeon", "back_args": {"resume": true}})
		return
	if phase != "target" or enemy_panel.targeting:
		return
	if pending == "rally" and not i in combat.rally_targets(cur):
		return
	if pending != "rally" and (combat.dead.has(i) or combat.gone.has(i)):
		return
	orders[cur] = {"act": pending, "target": i, "ally": true}
	_commit()


func _commit() -> void:
	_refresh_party()
	_next_character(cur)


## Esc: cancel targeting, or take back the previous character's order.
func _back() -> void:
	if phase == "target":
		_show_command()
		return
	if phase != "command":
		return
	for i in range(cur - 1, -1, -1):
		if combat.can_act(i):
			orders.erase(i)
			cur = i
			_show_command()
			return


func _combat_key(e: InputEvent) -> void:
	var k: int = e.keycode
	if phase == "resolve":
		if k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			fast = true
			get_viewport().set_input_as_handled()
		return
	if k == KEY_ESCAPE:
		_back()
	elif k == KEY_D and phase == "command":
		_on_defaults()
	elif ACT_KEYS.has(k) and phase == "command" and not act_buttons[ACT_KEYS[k]].disabled:
		_on_action(ACT_KEYS[k])
	else:
		return
	get_viewport().set_input_as_handled()


func _fill_defaults(from: int) -> void:
	for i in range(from, Game.party.size()):
		if combat.can_act(i) and not orders.has(i):
			orders[i] = combat.default_order(i)


func _on_defaults() -> void:
	if phase != "command" and phase != "target":
		return
	enemy_panel.targeting = false
	_fill_defaults(cur)
	_resolve()


func _on_tactics() -> void:
	if phase == "resolve":
		return
	await Game.main.tactics()


func _on_auto() -> void:
	auto = auto_btn.button_pressed
	if auto and (phase == "command" or phase == "target"):
		_on_defaults()
	elif auto:
		fast = true


# ---------------------------------------------------------------- combat round

func _pause(t: float) -> void:
	var d := t
	if auto:
		d = 0.07
	elif fast:
		d = 0.0
	if d > 0.0:
		await get_tree().create_timer(d).timeout
	else:
		await get_tree().process_frame


func _resolve() -> void:
	phase = "resolve"
	fast = false
	_lock_buttons()
	enemy_panel.targeting = false
	for p in ports:
		p.highlight = false
	_refresh_party()
	status_label.text = "Auto-combat: untoggle Auto to take over." if auto else "Fighting... (click the log or press Space to hurry)"
	var list := combat.begin_round(orders)
	await _pause(0.3)
	for a in list:
		if not is_inside_tree() or combat.outcome() != "":
			break
		var lines := combat.act(a, orders)
		if lines.is_empty():
			continue
		if a.side == "p":
			ports[a.i].highlight = true
			var o: Dictionary = orders[a.i]
			if o.has("target") and not o.has("ally"):
				enemy_panel.hit(o.target)
		for l in lines:
			say(l)
		_refresh_party()
		await _pause(0.75)
		if a.side == "p":
			ports[a.i].highlight = false
	if not is_inside_tree():
		return
	var after := combat.end_round()
	for l in after:
		say(l)
	if not after.is_empty():
		_refresh_party()
		await _pause(0.75)
	var result := combat.outcome()
	if result == "":
		_new_round()
	else:
		_end_combat(result)


func _end_combat(result: String) -> void:
	phase = ""
	var c := combat
	var tag := combat_tag
	combat_tag = ""
	var size_before := Game.party.size()
	if result == "lost" and c.dead.has(c.host_index()):
		combat = null
		await _game_over(Game.party[c.host_index()])
		return
	match result:
		"won":
			if tag != "" and tag != "warden":
				LehanQuests.apply("q:m_grp_%s=1" % tag)
			var lines := c.rewards()
			for l in lines:
				say(l)
			combat = null
			_refresh_party()
			await Game.main.message("\n".join(lines))
		"fled":
			say("You get away. Your hearts are still pounding.")
			var lines := c.after_fight()
			for l in lines:
				say(l)
			combat = null
			if not lines.is_empty():
				_refresh_party()
				await Game.main.message("\n".join(lines))
			if tag != "" and tag != "warden" and came_from != Game.pos:
				Game.pos = came_from   # the placed monsters still hold their ground
				last_pos = Game.pos
				view.snap()
		"lost":
			combat = null
			if tag == "warden":
				LehanQuests.apply("q:m_warden=met")
			say("The last of the party falls...")
			await _pause(0.6)
			var mourned := []
			var bodies := []
			for i in c.dead:
				bodies.append(Game.party[i])
			for b in bodies:
				Game.bury(b)
				mourned.append(b.name)
			var t := "The party has fallen.\nYou wake up %s, bruised and robbed of half your coins." % Game.checkpoint_name()
			if c.lethal:
				t += " Everyone is badly wounded."
			if not mourned.is_empty():
				t += "\n%s did not wake." % " and ".join(mourned)
			await Game.main.message(t)
			var screen := Game.party_defeated(c.lethal)
			Game.main.goto(screen, {"resume": true} if screen == "dungeon" else {})
			return
	steps_quiet = 0
	enemy_panel.visible = false
	enemy_panel.combat = null
	auto = false
	auto_btn.set_pressed_no_signal(false)
	for p in ports:
		p.highlight = false
	_refresh_party()
	_explore_ui()
	_hint()
	if Game.party.size() != size_before:
		Game.main.goto("dungeon", {"resume": true})   # someone died: rebuild the party panel
		return
	if result == "fled" and tag == "warden" and LehanQuests.get_q("m_warden") == "":
		_scene("The Warden", MinesQuest.warden_after())


## The host has died: the spirit is torn loose, and the game is over. Load a save, or start again.
func _game_over(host: Dictionary) -> void:
	say("%s is dead." % host.name)
	await _pause(0.8)
	await Game.main.message("%s is dead.\n\nThe body you lived in grows cold, and the spirit is torn loose into the dark.\n\nThe game is over. Load a saved game, or begin again." % host.name)
	Game.main.goto("title")
