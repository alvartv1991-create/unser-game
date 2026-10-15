class_name CombatScreen
extends CanvasLayer
## The combat screen. Presentation only: the rules live in scripts/combat/ (see handouts/H1).
## SceneRouter calls start(encounter_id); at the end this emits EventBus.combat_finished.
## Layout for 640×360: fighters in the middle, turn order on top, log + menu at the bottom.

signal _choice_made(action: CombatAction)

const SWARM_SCENE := "res://scenes/fx/alien_swarm.tscn"
const SWARM_PLACEHOLDER := preload("res://scenes/combat/swarm_placeholder.gd")
const PARTY_SLOTS := [Vector2(240, 155), Vector2(180, 108), Vector2(180, 202), Vector2(115, 155), Vector2(58, 108)]
const ALIEN_SLOT := Vector2(455, 170)
const LOG_LINES := 40
const LOG_FONT := 10
const DEATH_COLOR := "#ff4fd8"

## Multiplies every pause; tests set it to 0.
var speed := 1.0
## Test hook: the party plays itself (CombatAutoPilot) instead of asking the player.
var autopilot := false
## Test hooks for fights started by SceneRouter (e.g. H5's automated walkthrough):
## every new combat screen plays itself and/or uses this speed (negative = keep its own).
static var force_autopilot := false
static var force_speed := -1.0
var state: CombatState

var _encounter_id := ""
var _rng := RandomNumberGenerator.new()
var _views: Dictionary = {}            # fighter id -> CombatantView
var _background: ColorRect
var _fighter_layer: Node2D
var _order_bar: HBoxContainer
var _log: RichTextLabel
var _menu_title: Label
var _menu: VBoxContainer
var _overlay: Control = null
var _swarm: Node = null
var _cheats: CheatListener
var _pending_cheat := ""
var _asking: Combatant = null


func start(encounter_id: String) -> void:
	_encounter_id = encounter_id
	layer = 40
	autopilot = autopilot or force_autopilot
	if force_speed >= 0.0:
		speed = force_speed
	_build_ui()
	_begin()


func _begin() -> void:
	_rng.randomize()
	state = CombatSetup.from_game(_encounter_id, _rng)
	_cheats = CheatListener.new(state.encounter.get("cheats", []))
	_pending_cheat = ""
	_spawn_views()
	_log.clear()
	AudioManager.play_music(str(state.encounter.get("music", "music_combat")))
	state.start()
	await _play(state.take_events())
	await _loop()


func _loop() -> void:
	while not state.is_over():
		var actor := state.next_turn()
		await _play(state.take_events())
		if state.is_over():
			break
		if _pending_cheat != "":
			state.perform(CombatAction.cheat_code("player", _pending_cheat))
			_pending_cheat = ""
		elif actor == null:
			continue
		elif actor.is_enemy():
			await _wait(0.45)
			state.perform(EnemyAI.choose(state, actor))
		elif autopilot:
			state.perform(CombatAutoPilot.choose(state, actor))
		else:
			state.perform(await _ask(actor))
		await _play(state.take_events())
	await _end()


func _end() -> void:
	_set_active("")
	if state.outcome == "lose":
		_show_game_over()
		return
	await _wait(1.0)
	var result := CombatSetup.apply_result(state)
	EventBus.combat_finished.emit(result)


# --- Player input ----------------------------------------------------------

func _ask(actor: Combatant) -> CombatAction:
	_asking = actor
	_show_main_menu(actor)
	var action: CombatAction = await _choice_made
	_asking = null
	_menu_title.text = ""
	_clear(_menu)
	return action


## Language switched mid-fight: rebuild everything that shows text.
func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or state == null or _menu == null:
		return
	_refresh_views()
	_refresh_order(state.order.filter(func(f: Combatant) -> bool: return not f.is_out()).map(func(f: Combatant) -> String: return f.id))
	if _asking:
		_show_main_menu(_asking)


func _input(event: InputEvent) -> void:
	if _cheats == null or state == null or state.is_over():
		return
	var cheat_id := _cheats.feed(CheatListener.input_from_event(event))
	if cheat_id == "":
		return
	AudioManager.play_sfx("sfx_cheat")
	if _asking:
		_choice_made.emit(CombatAction.cheat_code(_asking.id, cheat_id))
	else:
		_pending_cheat = cheat_id


func _choose(action: CombatAction) -> void:
	_set_target_highlight("")
	_choice_made.emit(action)


func _show_main_menu(actor: Combatant) -> void:
	_set_target_highlight("")
	_menu_title.text = tr("COMBAT_TURN") % actor.short_name()
	_clear(_menu)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu.add_child(grid)
	_button(grid, tr("COMBAT_ATTACK"), _choose_target.bind(actor, "enemy",
		func(target_id: String) -> void: _choose(CombatAction.attack(actor.id, target_id))))
	_button(grid, tr("COMBAT_SKILL"), _show_skills.bind(actor), actor.skills.is_empty())
	_button(grid, tr("COMBAT_ITEM"), _show_items.bind(actor), state.usable_items().is_empty())
	_button(grid, tr("COMBAT_DEFEND"), func() -> void: _choose(CombatAction.make(CombatAction.Type.DEFEND, actor.id)))
	_button(grid, tr("COMBAT_TALK"), _show_talk.bind(actor), state.talkable_enemies().is_empty())
	_button(grid, tr("COMBAT_FLEE"), func() -> void: _choose(CombatAction.make(CombatAction.Type.FLEE, actor.id)))
	_focus_first(_menu)


func _show_skills(actor: Combatant) -> void:
	_clear(_menu)
	for skill_id in actor.skills:
		var skill := Data.skill(skill_id)
		var label := Data.text(skill.name)
		var reason := state.skill_block_reason(actor, skill_id)
		if reason == "COMBAT_COOLDOWN":
			label = tr("COMBAT_COOLDOWN") % [label, int(actor.cooldowns.get(skill_id, 0))]
		elif reason != "":
			label += " – " + tr(reason)
		var button := _button(_menu, label, _use_skill.bind(actor, skill_id), reason != "")
		button.tooltip_text = Data.text(skill.description)
	_back_button(actor)


func _use_skill(actor: Combatant, skill_id: String) -> void:
	match str(Data.skill(skill_id).get("target", "none")):
		"ally":
			_choose_target(actor, "ally", func(target_id: String) -> void: _choose(CombatAction.skill(actor.id, skill_id, target_id)))
		"enemy":
			_choose_target(actor, "enemy", func(target_id: String) -> void: _choose(CombatAction.skill(actor.id, skill_id, target_id)))
		_:
			_choose(CombatAction.skill(actor.id, skill_id))


func _show_items(actor: Combatant) -> void:
	_clear(_menu)
	for item_id in state.usable_items():
		var item := Data.item(item_id)
		var label := "%s ×%d" % [Data.text(item.name), int(state.inventory[item_id])]
		var button: Button
		if item.get("tags", []).has("alien_signal"):
			button = _button(_menu, label, func() -> void: _choose(CombatAction.item(actor.id, item_id)))
		else:
			button = _button(_menu, label, _choose_target.bind(actor, "ally",
				func(target_id: String) -> void: _choose(CombatAction.item(actor.id, item_id, target_id))))
		button.tooltip_text = Data.text(item.description)
	_back_button(actor)


func _show_talk(actor: Combatant) -> void:
	_clear(_menu)
	var job_id := str(GameState.player.get("job_id", "")) if actor.is_player else ""
	var approaches: Dictionary = Data.all("talk")
	for approach_id in approaches:
		var approach: Dictionary = approaches[approach_id]
		if approach.has("job") and approach.job != job_id:
			continue
		var label := Data.text(approach.name)
		if not approach.get("always_fails", false):
			var chance := CombatRules.talk_chance(actor, approach_id, approach, state.enemies(), state.rules)
			label = tr("COMBAT_WITH_CHANCE") % [label, chance]
		_button(_menu, label, func() -> void: _choose(CombatAction.talk(actor.id, approach_id)))
	_back_button(actor)


## kind "enemy": enemies still in the fight. kind "ally": the party, downed included (to revive them).
func _choose_target(actor: Combatant, kind: String, on_chosen: Callable) -> void:
	_clear(_menu)
	_menu_title.text = tr("COMBAT_CHOOSE_TARGET")
	var targets := state.enemies() if kind == "enemy" else state.party()
	for f in targets:
		if f.is_out():
			continue
		var label := f.short_name()
		if f.kind != "alien":
			label += "  %d/%d" % [f.hp, f.max_hp]
		if f.downed:
			label += "  ✚"
		var button := _button(_menu, label, func() -> void: on_chosen.call(f.id))
		button.focus_entered.connect(_set_target_highlight.bind(f.id))
		button.mouse_entered.connect(_set_target_highlight.bind(f.id))
	_back_button(actor)


func _back_button(actor: Combatant) -> void:
	_button(_menu, tr("COMBAT_BACK"), _show_main_menu.bind(actor))
	_focus_first(_menu)


# --- Playing events --------------------------------------------------------

func _play(events: Array[Dictionary]) -> void:
	for event in events:
		var line := CombatText.line(event, state, _rng)
		if line != "":
			_log_line(line, event.type)
		await _show_event(event)
		_refresh_views()
		if line != "":
			await _wait(0.35)


func _show_event(event: Dictionary) -> void:
	var actor := _view(str(event.get("actor", "")))
	var target := _view(str(event.get("target", "")))
	match event.type:
		"round":
			_refresh_order(event.order)
		"turn":
			_set_active(event.actor)
		"attack":
			if actor:
				actor.lunge()
			await _wait(0.12)
			AudioManager.play_sfx("sfx_hit")
			if target:
				target.hurt()
				target.float_text(str(event.amount), Color.WHITE)
		"hit":
			if target:
				target.hurt()
				target.float_text(str(event.amount), Color.WHITE)
		"alien_ignores":
			if actor:
				actor.lunge()
			if target:
				target.float_text("0", Color("#3ff0f0"))
		"swarm_hit":
			EventBus.device_glitch.emit(0.8, 0.6)
			AudioManager.play_sfx("sfx_glitch")
			if _swarm and _swarm.has_method("set_mood"):
				_swarm.set_mood("agitated")
		"swarm_idle":
			EventBus.device_glitch.emit(0.3, 0.4)
			if _swarm and _swarm.has_method("set_mood"):
				_swarm.set_mood("idle")
		"heal", "revive":
			AudioManager.play_sfx("sfx_heal")
			if target:
				target.float_text("+%d" % int(event.get("amount", 0)), Color("#b4bb7c"))
		"downed", "downed_player", "ko":
			AudioManager.play_sfx("sfx_ko")
		"died":
			await _wait(0.5)
			AudioManager.play_sfx("sfx_death")
			if target:
				target.float_text("†", Color(DEATH_COLOR))
			await _wait(1.0)
		"weapon_broke":
			AudioManager.play_sfx("sfx_sword_break")
			if actor:
				actor.hurt()
				actor.float_text("!!", Color("#e0a94a"))
		"intent":
			_refresh_intent()
		"signal", "cheat_code":
			EventBus.device_glitch.emit(1.0, 1.2)
			AudioManager.play_sfx("sfx_cheat")
			if _swarm and _swarm.has_method("set_mood"):
				_swarm.set_mood("dispersed")
			await _wait(0.8)


func _log_line(line: String, type: String) -> void:
	if type == "died":
		_log.append_text("[color=%s]%s[/color]\n" % [DEATH_COLOR, line])
	else:
		_log.append_text(line + "\n")
	if _log.get_paragraph_count() > LOG_LINES:
		_log.remove_paragraph(0)


func _wait(seconds: float) -> void:
	if seconds * speed <= 0.0:
		return
	await get_tree().create_timer(seconds * speed).timeout


# --- Views -----------------------------------------------------------------

func _spawn_views() -> void:
	_clear(_fighter_layer)
	_views.clear()
	_swarm = null
	var party := state.party()
	for i in party.size():
		_add_view(party[i], PARTY_SLOTS[mini(i, PARTY_SLOTS.size() - 1)])
	var foes := state.enemies()
	for i in foes.size():
		var f := foes[i]
		if f.kind == "alien":
			_add_view(f, ALIEN_SLOT)
			_add_swarm(_views[f.id])
		else:
			var slot: Vector2 = PARTY_SLOTS[mini(i, PARTY_SLOTS.size() - 1)]
			_add_view(f, Vector2(640 - slot.x, slot.y))
	_background.color = Color("#1c2238") if state.has_aliens() else Color("#2b2532")
	_refresh_intent()


func _add_view(f: Combatant, at: Vector2) -> void:
	var view := CombatantView.new()
	view.position = at
	_fighter_layer.add_child(view)
	view.setup(f)
	_views[f.id] = view


func _add_swarm(view: CombatantView) -> void:
	if ResourceLoader.exists(SWARM_SCENE):
		_swarm = (load(SWARM_SCENE) as PackedScene).instantiate()
	else:
		_swarm = SWARM_PLACEHOLDER.new()
	view.body.add_child(_swarm)
	if _swarm.has_method("set_mood"):
		_swarm.set_mood("idle")


func _view(id: String) -> CombatantView:
	return _views.get(id)


func _refresh_views() -> void:
	for f in state.fighters:
		var view := _view(f.id)
		if view:
			view.refresh(f)


func _set_active(id: String) -> void:
	for view_id in _views:
		_views[view_id].set_active(view_id == id)


func _set_target_highlight(id: String) -> void:
	for view_id in _views:
		_views[view_id].modulate = Color(1.3, 1.3, 1.0) if view_id == id else Color.WHITE


func _refresh_intent() -> void:
	var marked := {}
	for f in state.enemies():
		if not f.is_out() and f.intent_target != "":
			marked[f.intent_target] = true
	for view_id in _views:
		_views[view_id].set_intent(marked.has(view_id))


func _refresh_order(ids: Array) -> void:
	_clear(_order_bar)
	for id in ids:
		var f := state.fighter(id)
		var tag := Label.new()
		tag.text = f.short_name().left(10)
		tag.add_theme_font_size_override("font_size", LOG_FONT)
		tag.add_theme_color_override("font_color", Color("#c2622f") if f.is_enemy() else Color("#9db4c4"))
		_order_bar.add_child(tag)


# --- Game over -------------------------------------------------------------

func _show_game_over() -> void:
	_overlay = PanelContainer.new()
	_overlay.position = Vector2(170, 90)
	_overlay.custom_minimum_size = Vector2(300, 0)
	add_child(_overlay)
	var box := VBoxContainer.new()
	_overlay.add_child(box)
	var title := Label.new()
	title.text = tr("COMBAT_GAME_OVER")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_button(box, tr("COMBAT_RETRY"), _retry)
	if SaveSystem.has_save(0):
		_button(box, tr("COMBAT_LOAD"), func() -> void: SaveSystem.load_game(0))
	if OS.is_debug_build():
		_button(box, tr("COMBAT_GIVE_UP"), _give_up)
	_focus_first(box)


func _retry() -> void:
	_overlay.queue_free()
	_overlay = null
	_begin()


func _give_up() -> void:
	_overlay.queue_free()
	_overlay = null
	EventBus.combat_finished.emit(CombatSetup.apply_result(state))


# --- Building the screen ---------------------------------------------------

func _build_ui() -> void:
	_background = ColorRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)
	var ground := ColorRect.new()
	ground.color = Color("#3b2a24")
	ground.position = Vector2(0, 226)
	ground.size = Vector2(640, 10)
	add_child(ground)
	_fighter_layer = Node2D.new()
	add_child(_fighter_layer)

	_order_bar = HBoxContainer.new()
	_order_bar.position = Vector2(8, 4)
	_order_bar.add_theme_constant_override("separation", 10)
	add_child(_order_bar)

	var panel := PanelContainer.new()
	panel.position = Vector2(0, 236)
	panel.size = Vector2(640, 124)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", LOG_FONT)
	row.add_child(_log)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(250, 0)
	row.add_child(right)
	_menu_title = Label.new()
	_menu_title.add_theme_font_size_override("font_size", LOG_FONT)
	right.add_child(_menu_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_menu = VBoxContainer.new()
	_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_menu)


func _button(parent: Node, text: String, on_pressed: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx("sfx_ui_click")
		on_pressed.call())
	parent.add_child(button)
	return button


func _focus_first(parent: Node) -> void:
	for button in parent.find_children("*", "Button", true, false):
		if not button.disabled:
			button.grab_focus.call_deferred()
			return


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
