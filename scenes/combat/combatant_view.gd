class_name CombatantView
extends Node2D
## One fighter on the combat screen: sprite (or a placeholder shape), name, HP bar, status line,
## and small effects (lunge, shake, floating numbers). The origin is at the fighter's feet.

const SPRITE_DIR := "res://assets/sprites/characters/"
const SPRITE_SCALE := 2
const SMALL_FONT := 10
const PARTY_COLOR := Color("#5d7a99")
const ENEMY_COLOR := Color("#8e3b2b")
const HP_GOOD := Color("#7b8a48")
const HP_LOW := Color("#c2622f")
const DOWNED_COLOR := Color("#ff4fd8")

var fighter_id := ""
var body: Node2D                  # sprite/placeholder holder, moved by effects
var _sprite: AnimatedSprite2D
var _placeholder: ColorRect
var _name: Label
var _hp_back: ColorRect
var _hp_fill: ColorRect
var _hp_text: Label
var _status: Label
var _marker: Label
var _intent: Label
var _is_enemy := false


func setup(f: Combatant) -> void:
	fighter_id = f.id
	_is_enemy = f.is_enemy()
	body = Node2D.new()
	add_child(body)
	var frames_path := SPRITE_DIR + f.art_id + ".tres"
	# A sprite that exists but doesn't load (e.g. its PNG isn't imported yet) also gets the placeholder.
	var frames := load(frames_path) as SpriteFrames if ResourceLoader.exists(frames_path) else null
	if frames != null:
		_sprite = AnimatedSprite2D.new()
		_sprite.sprite_frames = frames
		_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		_sprite.position = Vector2(0, -16 * SPRITE_SCALE)
		_sprite.flip_h = _is_enemy
		body.add_child(_sprite)
		play("combat_idle")
	elif f.kind != "alien":
		# Contract fallback: a colored shape until the character is drawn.
		_placeholder = ColorRect.new()
		_placeholder.color = ENEMY_COLOR if _is_enemy else PARTY_COLOR
		_placeholder.size = Vector2(22, 50)
		_placeholder.position = Vector2(-11, -50)
		body.add_child(_placeholder)
	_name = _label(f.short_name(), Vector2(-50, 2), 100)
	_hp_back = _rect(Vector2(-20, 17), Vector2(40, 4), Color("#14101a"))
	_hp_fill = _rect(Vector2(-20, 17), Vector2(40, 4), HP_GOOD)
	_hp_text = _label("", Vector2(-50, 21), 100)
	_status = _label("", Vector2(-60, -86), 120)
	_marker = _label("▼", Vector2(-10, -74), 20)
	_marker.visible = false
	_intent = _label("!", Vector2(4, -74), 20)
	_intent.add_theme_color_override("font_color", DOWNED_COLOR)
	_intent.visible = false
	if f.kind == "alien":
		_hp_back.visible = false
		_hp_fill.visible = false
		_hp_text.visible = false
	refresh(f)


func refresh(f: Combatant) -> void:
	_name.text = f.short_name()
	_hp_fill.size.x = 40.0 * clampf(f.hp_ratio(), 0.0, 1.0)
	_hp_fill.color = HP_LOW if f.hp_ratio() < 0.35 else HP_GOOD
	_hp_text.text = "%d/%d" % [f.hp, f.max_hp]
	var status := ""
	var status_color := Color.WHITE
	if f.dead:
		status = tr("COMBAT_DEAD")
		status_color = Color("#77727a")
	elif f.downed:
		if f.is_player:
			status = tr("COMBAT_DOWNED_PLAYER")
		elif f.downed_turns_left > 0:
			status = tr("COMBAT_DOWNED") % f.downed_turns_left
		else:
			status = tr("COMBAT_KO")
		status_color = DOWNED_COLOR
	elif f.stunned > 0:
		status = tr("COMBAT_STUNNED")
	elif f.defending:
		status = tr("COMBAT_DEFENDING")
	elif f.guard > 0.0:
		status = tr("COMBAT_GUARDED")
	elif f.exposed_rounds > 0:
		status = tr("COMBAT_EXPOSED")
	_status.text = status
	_status.add_theme_color_override("font_color", status_color)
	if f.dead:
		body.modulate = Color(0.25, 0.22, 0.28, 1.0)
		play("downed")
	elif f.downed:
		body.modulate = Color(0.8, 0.7, 0.8, 1.0)
		play("downed")
	elif f.defeated or f.fled:
		body.modulate = Color(1, 1, 1, 0.0)
		_name.modulate.a = 0.35
		_hp_back.visible = false
		_hp_fill.visible = false
		_hp_text.visible = false
	else:
		body.modulate = Color.WHITE
		if _sprite and (_sprite.animation == &"downed"):
			play("combat_idle")


func set_active(active: bool) -> void:
	_marker.visible = active


func set_intent(marked: bool) -> void:
	_intent.visible = marked


## Plays an animation, falling back to combat_idle, idle, default (AGENTS.md § Art).
func play(anim: String) -> void:
	if _sprite == null:
		return
	for candidate in [anim, "combat_idle", "idle", "default"]:
		if _sprite.sprite_frames.has_animation(candidate):
			_sprite.play(candidate)
			return


func lunge() -> void:
	play("attack")
	var direction := -1.0 if _is_enemy else 1.0
	var tween := create_tween()
	tween.tween_property(body, "position:x", 14.0 * direction, 0.08)
	tween.tween_property(body, "position:x", 0.0, 0.14)
	tween.tween_callback(play.bind("combat_idle"))


func hurt() -> void:
	play("hurt")
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color(1.6, 0.6, 0.6), 0.05)
	for offset in [4.0, -4.0, 2.0, 0.0]:
		tween.tween_property(body, "position:x", offset, 0.04)
	tween.tween_property(body, "modulate", Color.WHITE, 0.1)
	tween.tween_callback(play.bind("combat_idle"))


func float_text(text: String, color: Color) -> void:
	var label := _label(text, Vector2(-30, -76), 60)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	var tween := create_tween()
	tween.tween_property(label, "position:y", -100.0, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(label.queue_free)


func _label(text: String, at: Vector2, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = Vector2(width, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", SMALL_FONT)
	label.add_theme_color_override("font_outline_color", Color("#14101a"))
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label


func _rect(at: Vector2, rect_size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = rect_size
	rect.color = color
	add_child(rect)
	return rect
