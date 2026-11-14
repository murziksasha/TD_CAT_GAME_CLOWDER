extends SceneTree

var main: Node

func _init() -> void:
	main = load("res://presentation/main.tscn").instantiate()
	root.add_child.call_deferred(main)

func _process(_delta: float) -> bool:
	if not main.is_node_ready():
		return false
	var profile: Dictionary = main.save_mgr.data.duplicate(true)
	main._on_mode_selected(5)
	assert(main.testing_lab != null and main.lab_panel.visible)
	assert(main.sim.replay.mode == 5)
	assert(main.testing_lab.spawn_enemy("mouse", "rust"))
	main.testing_lab.set_paused(true)
	assert(main.testing_lab.step())
	main.sim.match_lost = true
	main._show_results_dialog(false)
	assert(main.save_mgr.data == profile, "Lab results must not modify the profile")
	assert("no progression" in main.results_unlock_lbl.text)
	main._on_mode_selected(0)
	assert(main.testing_lab == null and not main.lab_panel.visible)
	assert(not main.sim.economy.unlimited_kibble)
	print("[PASS] Testing Lab UI integration and profile isolation")
	quit(0)
	return false

