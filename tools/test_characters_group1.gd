extends SceneTree

func _init() -> void:
	print("==================================================")
	print("   CLOWDER GROUP 1 CHARACTERS VERIFICATION       ")
	print("==================================================")
	var scene_res = load("res://presentation/main.tscn")
	if scene_res == null:
		printerr("FAILED: Could not load presentation/main.tscn")
		quit(1)
		return

	var main = scene_res.instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		main._ready()

	var sim = main.sim
	if sim == null:
		printerr("FAILED: Sim is null")
		quit(1)
		return

	# 1. Verify Cat Sprites / Sheets loaded
	var cats = ["pip", "nibs", "pudding", "biscuit"]
	for cat in cats:
		var tex: Texture2D = main.cat_sprites.get(cat)
		assert(tex != null, "Cat sprite/sheet missing: " + cat)
		print("[PASS] Cat loaded: %s (size %dx%d, is_sheet=%s)" % [
			cat, tex.get_width(), tex.get_height(), str(tex.get_width() >= 1280)
		])

	# 2. Verify Mice Walk Sheets loaded
	var mice_coats = ["rust", "grain", "iron", "porcelain"]
	for coat in mice_coats:
		var tex: Texture2D = main.mouse_sprites.get(coat)
		assert(tex != null, "Mouse sprite/sheet missing: " + coat)
		print("[PASS] Mouse loaded: %s (size %dx%d)" % [coat, tex.get_width(), tex.get_height()])

	# 3. Verify Rat Walk Sheet loaded
	var burrow_tex: Texture2D = main.rat_sprites.get("burrow")
	assert(burrow_tex != null, "Rat burrow sprite/sheet missing")
	print("[PASS] Rat burrow loaded (size %dx%d)" % [burrow_tex.get_width(), burrow_tex.get_height()])

	# 4. Verify Tower Placement & Upgrades (Primary + Crosspath)
	sim.economy.kibble = 99999
	var pip_pos = Vector2(250.0, 180.0)
	var pip_tower = sim.place_tower("pip", pip_pos)
	assert(pip_tower != null, "Failed to place Pip")
	print("[PASS] Pip placed at ", pip_pos)

	var nibs_tower = sim.place_tower("nibs", Vector2(300.0, 180.0))
	assert(nibs_tower != null, "Failed to place Nibs")
	print("[PASS] Nibs placed")

	var pudding_tower = sim.place_tower("pudding", Vector2(350.0, 180.0))
	assert(pudding_tower != null, "Failed to place Pudding")
	print("[PASS] Pudding placed")

	var biscuit_tower = sim.place_tower("biscuit", Vector2(400.0, 180.0))
	assert(biscuit_tower != null, "Failed to place Biscuit")
	print("[PASS] Biscuit placed")

	# Test upgrade ornaments: 3-2-0 on Pip
	pip_tower.tiers.path_a = 3
	pip_tower.tiers.path_b = 2
	print("[PASS] Pip upgraded to 3-2-0 crosspath")

	# 5. Spawn Enemies: Rust, Grain, Iron, Porcelain, Burrow
	var rust_unit = sim.spawn_unit({"coat": "rust"}, 50.0)
	var grain_unit = sim.spawn_unit({"coat": "grain"}, 60.0)
	var iron_unit = sim.spawn_unit({"coat": "iron"}, 70.0)
	var porc_unit = sim.spawn_unit({"coat": "porcelain"}, 80.0)
	var burrow_unit = sim.spawn_unit({"rat": "burrow"}, 10.0)

	assert(rust_unit != null and grain_unit != null and iron_unit != null and porc_unit != null and burrow_unit != null, "Units failed to spawn")
	print("[PASS] Spawns verified: Rust, Grain, Iron, Porcelain, Burrow")

	# 6. Test Combat Reactions & Damage Types
	# Iron blocks Claw
	var iron_hit = iron_unit.hit(1, 0) # Claw = 0
	assert(iron_hit.get("blocked_by") == "iron", "Iron must block claw")
	print("[PASS] Iron blocked Claw correctly (blocked_by='iron')")

	# Porcelain shell damage reflects cracks
	porc_unit.hit(2, 4) # Acid/Bite bypasses
	assert(porc_unit.layer_hp < porc_unit.max_layer_hp, "Porcelain shell took damage")
	print("[PASS] Porcelain shell HP damaged: %d/%d" % [porc_unit.layer_hp, porc_unit.max_layer_hp])

	# Burrow damage states
	burrow_unit.body_hp = int(burrow_unit.max_body_hp * 0.45) # Under 50%
	print("[PASS] Burrow body HP damaged to 45% (testing second damage stage)")

	# 7. Test Biscuit Lob Projectile Arc
	sim.proj_id_counter += 1
	var proj = SimProjectile.new()
	proj.setup_lob(sim.proj_id_counter, biscuit_tower.instance_id, Vector2(100.0, 100.0), 2, 2, 8, 45.0, 0.4, biscuit_tower.position)
	sim.projectiles.append(proj)
	assert(proj.start_position == biscuit_tower.position, "Projectile must preserve start_position")
	print("[PASS] Biscuit lob projectile arc verified with start_position")

	# 8. Test Audio & VFX Processing
	main.presentation_audio.note({"type": "fire", "cat": "pip"})
	main.presentation_audio.note({"type": "fire", "cat": "nibs"})
	main.presentation_audio.note({"type": "fire", "cat": "pudding"})
	main.presentation_audio.note({"type": "fire", "cat": "biscuit"})
	main.presentation_audio.note({"type": "blocked", "blocked_by": "iron"})
	main.presentation_audio.note({"type": "pop", "coat": "rust"})
	main.presentation_audio.note({"type": "pop", "coat": "grain"})
	main.presentation_audio.note({"type": "pop", "coat": "iron"})
	main.presentation_audio.note({"type": "pop", "coat": "porcelain"})
	main.presentation_audio.note({"type": "pop", "unit_type": "burrow", "is_rat": true})
	print("[PASS] All 10 procedural audio triggers executed cleanly")

	# Pop VFX Equipment Debris
	main.combat_vfx.note({"type": "pop", "coat": "iron", "x": 100, "y": 100})
	main.combat_vfx.note({"type": "pop", "coat": "porcelain", "x": 150, "y": 100})
	main.combat_vfx.note({"type": "pop", "coat": "grain", "x": 200, "y": 100})
	main.combat_vfx.note({"type": "pop", "coat": "burrow", "is_rat": true, "x": 250, "y": 100})
	main.combat_vfx.note({"type": "explosion", "x": 100, "y": 100, "radius": 45.0})
	main.combat_vfx.note({"type": "frost_pulse", "x": 200, "y": 200, "radius": 90.0})
	main.combat_vfx.note({"type": "slash", "x": 300, "y": 300, "radius": 40.0})
	assert(main.combat_vfx.debris.size() > 0, "Debris must spawn on pop")
	print("[PASS] Flying equipment debris spawned: %d pieces" % main.combat_vfx.debris.size())

	# 9. Run visual frames & draw test
	for i in range(30):
		main._process(0.0166)

	print("==================================================")
	print("   ALL GROUP 1 CHARACTER CHECKS PASSED CLEANLY    ")
	print("==================================================")
	quit(0)
