extends SceneTree

var main: Node

func _init() -> void:
	main = load("res://presentation/main.tscn").instantiate()
	root.add_child.call_deferred(main)

func _process(_delta: float) -> bool:
	if not main.is_node_ready():
		return false
	main._on_mode_selected(6)
	assert(main.alley_crawl != null and main.alley_crawl_session != null)
	assert(main.sim.replay.mode == 6)
	assert(main.sim.max_rounds == int(main.alley_crawl_config.district_rounds[main.alley_crawl.current_stage]))
	assert(main.map_select_btn.disabled)
	var fish_before := int(main.save_mgr.data.economy.fishcoin)
	var medals_before: Dictionary = main.save_mgr.data.medals.duplicate(true)
	main.sim.economy.kibble = 999
	main.sim.match_won = true
	main._show_results_dialog(true)
	assert(main.alley_crawl.pending_relic_offer.size() == 3)
	assert(main.crawl_panel.visible and not main.results_modal.visible)
	assert(int(main.save_mgr.data.economy.fishcoin) == fish_before, "District clear cannot grant completion Fishcoin")
	assert(main.save_mgr.data.medals == medals_before, "Crawl cannot grant standard medals")
	var relic_id: String = main.alley_crawl.pending_relic_offer[0]
	main._choose_crawl_relic(relic_id)
	assert(main.alley_crawl.relics.has(relic_id))
	assert(main.alley_crawl.get_next_nodes().size() > 0)
	var next_id := str(main.alley_crawl.get_next_nodes()[0].id)
	main._choose_crawl_node(next_id)
	assert(main.alley_crawl.current_stage == 1)
	assert(main.alley_crawl_session != null and main.sim.replay.mode == 6)
	print("[PASS] Alley Crawl mode entry, district clear, draft, route, and reward isolation")
	quit(0)
	return false
