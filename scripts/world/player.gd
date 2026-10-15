class_name WorldPlayer
extends CharacterBody2D

@export var speed: float = 125.0
@export var acceleration: float = 850.0
@export var jump_speed: float = 260.0
@export var gravity: float = 800.0
@export var camera_bounds: Rect2i = Rect2i(0, 0, 1920, 360)
var coyote: float = 0.0
var buffered: float = 0.0
var drop_time: float = 0.0
var home: Vector2
var trail: Array[Vector2] = []
var followers: Array[Node2D] = []
var visual: AnimatedSprite2D
var camera: Camera2D

func _ready() -> void:
	add_to_group("player")
	home = position
	visual = make_visual("player")
	add_child(visual)
	camera = Camera2D.new()
	camera.position = Vector2(0, -48)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = camera_bounds.position.x
	camera.limit_top = camera_bounds.position.y
	camera.limit_right = camera_bounds.end.x
	camera.limit_bottom = camera_bounds.end.y
	add_child(camera)
	EventBus.party_changed.connect(rebuild_followers)
	rebuild_followers()

static func make_visual(id: String) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.position.y = -16
	var path := "res://assets/sprites/characters/%s.tres" % id
	if ResourceLoader.exists(path):
		sprite.sprite_frames = load(path) as SpriteFrames
		sprite.play("idle")
	else:
		var shape := Polygon2D.new()
		shape.polygon = PackedVector2Array([Vector2(-6, -12), Vector2(6, -12), Vector2(6, 16), Vector2(-6, 16)])
		shape.color = Color("c9a26b") if id == "cook" else Color("5d7a99")
		sprite.add_child(shape)
	return sprite

func rebuild_followers() -> void:
	for follower in followers:
		follower.queue_free()
	followers.clear()
	trail.clear()
	for id in GameState.party:
		var follower := Node2D.new()
		follower.set_meta("companion_id", id)
		follower.add_child(make_visual(id))
		add_child(follower)
		followers.append(follower)

func blocked() -> bool:
	return DialogueRunner.is_running() or SceneRouter.is_in_combat() or SceneRouter.is_changing_scene() or get_tree().paused or is_instance_valid(SceneRouter.get("_debug_menu"))

func _physics_process(delta: float) -> void:
	var locked := blocked()
	var axis := 0.0 if locked else Input.get_axis("move_left", "move_right")
	velocity.x = 0.0 if locked else move_toward(velocity.x, axis * speed, acceleration * delta)
	coyote = 0.11 if is_on_floor() else maxf(0.0, coyote - delta)
	buffered = maxf(0.0, buffered - delta)
	drop_time = maxf(0.0, drop_time - delta)
	set_collision_mask_value(2, drop_time <= 0.0)
	if locked:
		buffered = 0.0
	elif Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("move_down") and is_on_floor():
			drop_time = 0.22
			set_collision_mask_value(2, false)
			coyote = 0.0
		else:
			buffered = 0.12
	if buffered > 0.0 and coyote > 0.0 and drop_time <= 0.0:
		velocity.y = -jump_speed
		buffered = 0.0
		coyote = 0.0
		AudioManager.play_sfx("sfx_jump")
	if not locked and Input.is_action_just_released("jump") and velocity.y < -100.0:
		velocity.y = -100.0
	velocity.y = minf(velocity.y + gravity * delta, 450.0)
	var landed_before := is_on_floor()
	move_and_slide()
	if is_on_floor() and not landed_before:
		AudioManager.play_sfx("sfx_land")
	if position.y > camera_bounds.end.y + 160:
		position = home
		velocity = Vector2.ZERO
		trail.clear()
	if absf(velocity.x) > 1:
		visual.flip_h = velocity.x < 0
	var anim := "idle" if absf(velocity.x) < 5 else "walk"
	if not is_on_floor():
		anim = "jump" if velocity.y < 0 else "fall"
	if visual.sprite_frames and visual.sprite_frames.has_animation(anim):
		visual.play(anim)
	if trail.is_empty() or trail[0].distance_to(global_position) > 2:
		trail.push_front(global_position)
		if trail.size() > 100:
			trail.pop_back()
	for i in followers.size():
		var target := trail[mini((i + 1) * 12, trail.size() - 1)]
		if trail.size() < (i + 1) * 12:
			target.x -= (i + 1) * 18
		followers[i].global_position = target.round()
		var follower_visual := followers[i].get_child(0) as AnimatedSprite2D
		follower_visual.flip_h = visual.flip_h
		if follower_visual.sprite_frames:
			follower_visual.play(anim if follower_visual.sprite_frames.has_animation(anim) else "idle")

