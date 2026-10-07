extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	assert(game.enemies.size() == 4)
	game.simulate(0.3, Vector2.RIGHT)
	assert(game.moving and game.shots.is_empty(), "Moving must suppress player shooting")
	game.simulate(0.01, Vector2.ZERO)
	assert(game.shots.size() == 1 and game.shots[0].friendly, "Stopping must fire")
	game.shots.clear()
	var enemy = game.enemies[0]
	enemy.hp = 1
	game.shots.append({"p": enemy.p, "v": Vector2.ZERO, "friendly": true})
	game.simulate(0.001, Vector2.RIGHT)
	assert(game.kills == 1 and game.enemies.size() == 3)
	game.hurt()
	game.hurt()
	assert(game.hp == 5, "Damage immunity prevents repeated instant hits")
	game.enemies.clear()
	game.simulate(0.01, Vector2.ZERO)
	assert(game.state == "upgrade")
	game.upgrade(0)
	assert(game.wave == 2 and game.damage == 2 and game.enemies.size() == 5)
	game.wave = 5
	game.enemies.clear()
	game.simulate(0.01, Vector2.ZERO)
	assert(game.state == "win")
	game.reset_run()
	game.hp = 1
	game.hurt()
	assert(game.state == "dead")
	game.reset_run()
	assert(game.hp == 6 and game.state == "play" and game.wave == 1)
	game.pointer_down(Vector2(100,600))
	game.stick = Vector2(55,0)
	assert(game.movement() == Vector2.RIGHT)
	game.simulate(10, Vector2.RIGHT)
	assert(game.player.x <= 492)
	print("PASS: movement, stop/fire, arrow hit, immunity, upgrade, victory, death, restart, drag, bounds")
	game.free()
	quit()
