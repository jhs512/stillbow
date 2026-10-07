extends Node2D

const ARENA := Rect2(30, 168, 480, 582)
const TEAL := Color("65efd0")
const GOLD := Color("ffc875")
const RED := Color("fc7284")
const ARCHER_IMAGE := preload("res://assets/images/archer-v1.png")
const ARENA_IMAGE := preload("res://assets/images/arena-v1.png")
var archer_texture: AtlasTexture
var facing := PI
var player := Vector2(270, 650)
var hp := 6
var wave := 1
var kills := 0
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var state := "play"
var cooldown := 0.0
var invincible := 0.0
var elapsed := 0.0
var damage := 1
var fire_interval := 0.48
var speed := 220.0
var drag := false
var origin := Vector2.ZERO
var stick := Vector2.ZERO
var moving := false
var aim := Vector2.UP
var paused := false
var font := ThemeDB.fallback_font
var capture_frames := 0

func _ready() -> void:
	archer_texture = AtlasTexture.new()
	archer_texture.atlas = ARCHER_IMAGE
	# Crop alpha padding without modifying the source PNG. The painted bow points down.
	var image := ARCHER_IMAGE.get_image()
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i.ZERO
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.1:
				minimum = minimum.min(Vector2i(x, y))
				maximum = maximum.max(Vector2i(x, y))
	archer_texture.region = Rect2(Vector2(minimum), Vector2(maximum - minimum + Vector2i.ONE))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	reset_run()
	if "--capture" in OS.get_cmdline_user_args():
		capture_frames = 100

func reset_run() -> void:
	player = Vector2(270, 650)
	hp = 6
	wave = 1
	kills = 0
	damage = 1
	fire_interval = 0.48
	speed = 220
	invincible = 0
	cooldown = 0.2
	shots.clear()
	sparks.clear()
	state = "play"
	paused = false
	drag = false
	stick = Vector2.ZERO
	aim = Vector2.UP
	facing = PI
	spawn_wave()

func spawn_wave() -> void:
	enemies.clear()
	shots.clear()
	for i in range(3 + wave):
		var pos := Vector2(90 + (i % 4) * 120, 240 + (i / 4) * 105)
		enemies.append({"p": pos, "hp": 2 + wave, "max": 2 + wave, "cd": 1.1 + i * 0.34, "kind": i % 2, "phase": float(i)})

func movement() -> Vector2:
	var v := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if drag:
		v = stick.limit_length(55) / 55.0
	return v.limit_length(1)

func _physics_process(dt: float) -> void:
	elapsed += dt
	if state == "play" and not paused:
		simulate(dt, movement())
	for s in sparks:
		s.life -= dt
	sparks = sparks.filter(func(s): return s.life > 0)
	queue_redraw()
	if capture_frames > 0:
		capture_frames -= 1
		if capture_frames == 0:
			capture.call_deferred()

func capture() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	get_viewport().get_texture().get_image().save_png("res://artifacts/gameplay-art-v1.png")
	print("CAPTURE_SAVED artifacts/gameplay-art-v1.png")

func simulate(dt: float, motion: Vector2) -> void:
	moving = motion.length() > 0.08
	player += motion * speed * dt
	player = player.clamp(ARENA.position + Vector2(44,44), ARENA.end - Vector2(44,44))
	invincible = maxf(0, invincible - dt)
	cooldown -= dt
	if not enemies.is_empty():
		var target: Dictionary = enemies[0]
		for e in enemies:
			if player.distance_squared_to(e.p) < player.distance_squared_to(target.p):
				target = e
		aim = player.direction_to(target.p)
		facing = lerp_angle(facing, aim.angle() - PI / 2, minf(1.0, dt * 15.0))
		if not moving and cooldown <= 0:
			shots.append({"p": player + aim * 22, "v": aim * 570, "friendly": true})
			cooldown = fire_interval
	for e in enemies:
		var direction := (e.p as Vector2).direction_to(player)
		if e.kind == 0:
			e.p += direction * (28 + wave * 3) * dt
		else:
			e.p += Vector2(sin(elapsed + e.phase) * 22, 0) * dt
		e.p = (e.p as Vector2).clamp(ARENA.position + Vector2(20,20), ARENA.end - Vector2(20,20))
		e.cd -= dt
		if e.cd <= 0:
			shots.append({"p": e.p + direction * 23, "v": direction * (125 + wave * 12), "friendly": false})
			e.cd = 2.3 - wave * 0.12
		if player.distance_to(e.p) < 33:
			hurt()
	for b in shots:
		b.p += b.v * dt
		if b.friendly:
			for e in enemies:
				if e.hp > 0 and (b.p as Vector2).distance_to(e.p) < 23:
					e.hp -= damage
					b.dead = true
					sparks.append({"p": e.p, "life": 0.3})
					if e.hp <= 0:
						kills += 1
					break
		elif (b.p as Vector2).distance_to(player) < 21:
			b.dead = true
			hurt()
	shots = shots.filter(func(b): return not b.get("dead", false) and ARENA.has_point(b.p))
	enemies = enemies.filter(func(e): return e.hp > 0)
	if enemies.is_empty() and state == "play":
		shots.clear()
		state = "win" if wave == 5 else "upgrade"
		drag = false
		stick = Vector2.ZERO

func hurt() -> void:
	if invincible > 0 or state != "play":
		return
	hp -= 1
	invincible = 1.0
	if hp <= 0:
		state = "dead"
		drag = false

func upgrade(choice: int) -> void:
	if state != "upgrade":
		return
	match choice:
		0: damage += 1
		1: fire_interval *= 0.8
		2: hp = mini(6, hp + 3); speed += 20
	wave += 1
	state = "play"
	spawn_wave()

func pointer_down(p: Vector2) -> void:
	if p.y < 140 and p.x > 450:
		paused = not paused
		return
	if state == "upgrade":
		for i in range(3):
			if Rect2(62, 405 + i * 86, 416, 72).has_point(p):
				upgrade(i)
		return
	if state in ["dead", "win"]:
		if Rect2(110,510,320,64).has_point(p): reset_run()
		return
	if not paused:
		drag = true
		origin = p
		stick = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R: reset_run()
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P: paused = not paused
		if state == "upgrade" and event.keycode in [KEY_1, KEY_2, KEY_3]: upgrade(event.keycode - KEY_1)
	if event is InputEventScreenTouch:
		if event.pressed: pointer_down(event.position)
		else: drag = false; stick = Vector2.ZERO
	if event is InputEventScreenDrag and drag: stick = event.position - origin
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: pointer_down(event.position)
		else: drag = false; stick = Vector2.ZERO
	if event is InputEventMouseMotion and drag: stick = event.position - origin

func label_at(p: Vector2, text: String, size: int, color: Color = Color("e6edf7")) -> void:
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel(rect: Rect2, color: Color) -> void:
	draw_style_box(make_style(color), rect)

func make_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(12)
	return s

func _draw() -> void:
	draw_rect(Rect2(0,0,540,900), Color("0b1220"))
	label_at(Vector2(30,38), "STILLBOW", 25, TEAL)
	label_at(Vector2(30,61), "GEOMETRY TRIALS  /  PROTOTYPE 01", 12, Color("8193af"))
	panel(Rect2(30,82,480,66), Color("172337"))
	label_at(Vector2(47,106), "VITALITY", 11, Color("8193af"))
	for i in range(6):
		draw_circle(Vector2(55+i*23,125), 7, TEAL if i < hp else Color("30425a"))
	label_at(Vector2(225,109), "WAVE", 11, Color("8193af"))
	label_at(Vector2(225,133), "%02d / 05" % wave, 21)
	label_at(Vector2(349,109), "DEFEATED", 11, Color("8193af"))
	label_at(Vector2(349,133), "%02d" % kills, 21, GOLD)
	label_at(Vector2(474,122), "II", 22, TEAL)
	panel(ARENA.grow(4), Color("30435a"))
	# Crop the floor to the room aspect instead of stretching its circular motif.
	var background_size := ARENA_IMAGE.get_size()
	var crop_height := background_size.x * ARENA.size.y / ARENA.size.x
	draw_texture_rect_region(ARENA_IMAGE, ARENA, Rect2(0, (background_size.y-crop_height)/2, background_size.x, crop_height))
	# Restore top/bottom wall strips; side walls remain in the cropped floor.
	draw_texture_rect_region(ARENA_IMAGE, Rect2(ARENA.position, Vector2(480,30)), Rect2(0,0,background_size.x,80))
	draw_texture_rect_region(ARENA_IMAGE, Rect2(30,720,480,30), Rect2(0,background_size.y-80,background_size.x,80))
	# Lower the floor contrast so enemies and bullets retain their visual priority.
	draw_rect(ARENA, Color(0.02, 0.04, 0.08, 0.25))
	for e in enemies:
		var p: Vector2 = e.p
		draw_circle(p+Vector2(0,7),21,Color(0,0,0,0.2))
		if e.kind == 0:
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-19),p+Vector2(19,0),p+Vector2(0,19),p+Vector2(-19,0)]),RED)
		else:
			draw_rect(Rect2(p-Vector2(16,16),Vector2(32,32)),GOLD)
		draw_circle(p,6,Color("283047"))
		draw_rect(Rect2(p+Vector2(-19,-29),Vector2(38,4)),Color("30425a"))
		draw_rect(Rect2(p+Vector2(-19,-29),Vector2(38.0*e.hp/e.max,4)),RED)
		if e.cd < 0.45: draw_arc(p,25,0,TAU,32,Color(1,0.5,0.5,0.5),2)
	for b in shots:
		if b.friendly:
			draw_line(b.p - b.v.normalized()*15,b.p,TEAL,3,true)
		else:
			draw_circle(b.p,9,Color(1,0.35,0.4,0.16))
			draw_circle(b.p,5,RED)
	for s in sparks: draw_arc(s.p,(0.3-s.life)*90+8,0,TAU,20,Color(0.4,1,0.8,s.life/0.3),2)
	if invincible == 0 or int(elapsed*15)%2 == 0:
		draw_circle(player+Vector2(0,8),20,Color(0,0,0,0.3))
		draw_arc(player,21,0,TAU,40,Color(0.4,0.94,0.82,0.45),1.5,true)
		var art_size := Vector2(76.0 * archer_texture.region.size.x / archer_texture.region.size.y, 76)
		draw_set_transform(player, facing)
		draw_texture_rect(archer_texture, Rect2(-art_size / 2, art_size), false)
		draw_set_transform(Vector2.ZERO)
	panel(Rect2(30,770,480,100), Color("172337"))
	label_at(Vector2(49,801), "MOVE TO DODGE" if moving else "STILL. AIM. RELEASE.", 19, TEAL)
	label_at(Vector2(49,826), "WASD / arrows   or   drag anywhere", 15)
	label_at(Vector2(49,850), "Stop to auto-fire   |   R restart   |   P pause", 13, Color("8193af"))
	if drag:
		draw_circle(origin,55,Color(0.4,1,0.8,0.1))
		draw_arc(origin,55,0,TAU,40,Color(0.4,1,0.8,0.4),2)
		draw_circle(origin+stick.limit_length(55),18,Color(0.4,1,0.8,0.5))
	if state != "play" or paused:
		draw_rect(Rect2(0,158,540,600),Color(0.02,0.04,0.08,0.88))
		if state == "upgrade":
			label_at(Vector2(62,320), "ROOM CLEARED", 30, TEAL)
			label_at(Vector2(62,355), "Choose your edge for the next wave.", 17)
			var titles := ["1   POWER ARROW", "2   QUICK DRAW", "3   SECOND WIND"]
			var notes := ["+1 damage per arrow", "20% shorter firing cooldown", "Restore 3 health / +20 movement speed"]
			for i in range(3):
				panel(Rect2(62,405+i*86,416,72),Color("22364a"))
				label_at(Vector2(80,434+i*86),titles[i],19,GOLD)
				label_at(Vector2(80,460+i*86),notes[i],14)
		else:
			var title := "PAUSED" if paused and state == "play" else ("TRIAL COMPLETE" if state == "win" else "ONE MORE SHOT")
			label_at(Vector2(83,380),title,30,TEAL)
			label_at(Vector2(83,421),"Press P to resume" if paused and state == "play" else "%d defeated  /  wave %d" % [kills,wave],19)
			if state != "play":
				panel(Rect2(110,510,320,64),TEAL)
				label_at(Vector2(173,550),"PLAY AGAIN  [R]",20,Color("102b32"))
