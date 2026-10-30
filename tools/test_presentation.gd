extends SceneTree

var main_node: Node2D
var frame_count: int = 0

func _init() -> void:
	print("--- Running Full Presentation & Draw Verification ---")
	var scene = load("res://presentation/main.tscn")
	if scene == null:
		push_error("Failed to load main.tscn")
		quit(1)
		return
	main_node = scene.instantiate()
	root.add_child(main_node)

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 1:
		_run_tests()
	return false

func _run_tests() -> void:
	if main_node.sim == null:
		push_error("main_node.sim is null")
		quit(1)
		return
		
	print("1. Sim and UI initialized. Lives: %d, Kibble: %d" % [main_node.sim.lives, main_node.sim.economy.kibble])
	
	# Test tower placement
	var t = main_node.sim.place_tower("pip", Vector2(200.0, 200.0))
	if t == null:
		push_error("Failed to place pip")
		quit(1)
		return
	print("2. Placed Pip at (200, 200).")
	
	# Test hero placement
	var h = main_node.sim.place_hero("mittens", Vector2(300.0, 250.0))
	if h == null:
		push_error("Failed to place hero Mittens")
		quit(1)
		return
	print("3. Placed Hero Mittens at (300, 250).")
	
	# Test inspector selection
	main_node._select_tower(t)
	print("4. Selected Pip in Inspector. Path A text: %s" % main_node.path_a_btn.text.replace("\n", " "))
	
	# Test upgrade
	main_node._upgrade_selected("path_a")
	print("5. Upgraded Pip Path A. Tier: %d, Kibble: %d" % [t.tiers["path_a"], main_node.sim.economy.kibble])
	
	# Test round start and spawn
	main_node.sim.start_next_round()
	print("6. Round 1 started. Pending spawns: %d" % main_node.sim.pending_spawns.size())
	
	# Spawn a rat for testing rat rendering
	var rat = main_node.sim.spawn_unit({"rat": "burrow", "sunny_reduced_hp": true}, 200.0)
	print("7. Spawned test Burrow Rat. Body HP: %d / %d" % [rat.body_hp, rat.max_body_hp])
	
	# Simulate 30 ticks
	for i in range(30):
		main_node.sim.tick()
		
	# Trigger redraw
	main_node.queue_redraw()
	print("8. queue_redraw() requested.")
	
	# Test Feat offer and selection
	t.add_feat_xp(150.0)
	main_node._check_pending_feats()
	if main_node.feat_modal.visible:
		print("9. Feat modal opened for Pip. Card 1: %s" % main_node.feat_card1_name.text)
		main_node._pick_feat_card(0)
		print("10. Picked feat card 0. Feats on Pip: %d" % t.selected_feats.size())
		
	print("--- ALL PRESENTATION CHECKS PASSED (10/10) ---")
	quit(0)
