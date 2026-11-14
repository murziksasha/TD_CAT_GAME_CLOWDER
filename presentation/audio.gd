class_name PresentationAudio
extends RefCounted

# Authoritative audio manager with synthesized procedural sound effects and polyphony limiting.
# Audio is non-blocking and safe: headless or missing audio drivers fail silently.

const MIX_RATE := 22050
const POOL_SIZE := 16

var players: Array[AudioStreamPlayer] = []
var player_index := 0
var streams: Dictionary = {}
var last_played: Dictionary = {}
var min_intervals: Dictionary = {
	"pip_click": 0.04, "nibs_swipe": 0.05, "pudding_pulse": 0.12, "biscuit_thump": 0.08,
	"sable_crack": 0.08, "nim_zap": 0.06, "goldie_net": 0.10, "miso_chime": 0.12,
	"bub_clink": 0.08, "bub_hiss": 0.10,
	"mittens_whistle": 0.10, "duchess_fan": 0.08, "baron_anchor": 0.12, "pebble_bell": 0.14,
	"rust_pop": 0.035, "grain_pop": 0.035, "iron_clang": 0.06, "porcelain_pop": 0.05,
	"slate_pop": 0.04, "moss_pop": 0.04, "sugar_pop": 0.04, "soot_pop": 0.05,
	"frost_shiver": 0.05, "ink_swallow": 0.08, "marble_crash": 0.08, "prism_shimmer": 0.06,
	"burrow_break": 0.20, "bristle_rattle": 0.20, "monarch_fanfare": 0.25,
	"dusk_vanish": 0.18, "matriarch_roar": 0.35, "pop": 0.03, "leak": 0.15
}
var is_ready := false

func _init() -> void:
	_synthesize_all_sounds()

func setup(parent_node: Node) -> void:
	if parent_node == null:
		return
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "ClowderSfx_%d" % i
		parent_node.add_child(p)
		players.append(p)
	is_ready = true

func note(event: Dictionary) -> void:
	var kind := str(event.get("type", ""))
	match kind:
		"fire":
			var cat := str(event.get("cat", "")).to_lower()
			match cat:
				"pip": play("pip_click", -3.0)
				"nibs": play("nibs_swipe", -2.0)
				"pudding": play("pudding_pulse", -1.0)
				"biscuit": play("biscuit_thump", 0.0)
				"sable": play("sable_crack", 1.0)
				"nim": play("nim_zap", -1.0)
				"goldie": play("goldie_net", -1.0)
				"miso": play("miso_chime", -1.0)
				"bub": play("bub_clink", -1.0)
				"mittens": play("mittens_whistle", 0.0)
				"duchess": play("duchess_fan", -2.0)
				"baron": play("baron_anchor", 1.0)
				"pebble": play("pebble_bell", 0.0)
		"frost_pulse":
			play("pudding_pulse", -1.0)
		"slash":
			play("nibs_swipe", -2.0)
		"explosion":
			play("biscuit_thump", 1.0)
		"acid_splash", "acid_pool":
			play("bub_hiss", -1.0)
		"rat_enter":
			var rat := str(event.get("rat", "")).to_lower()
			if rat == "matriarch":
				play("matriarch_roar", 3.0)
			elif rat == "monarch":
				play("monarch_fanfare", 2.0)
		"blocked":
			var blk := str(event.get("blocked_by", "")).to_lower()
			match blk:
				"iron": play("iron_clang", 1.0)
				"ink": play("ink_swallow", 0.0)
				"soot": play("soot_pop", 0.0)
				"frost": play("frost_shiver", -1.0)
				"matriarch": play("burrow_break", 1.0)
		"pop":
			var coat := str(event.get("coat", "")).to_lower()
			var unit_type := str(event.get("unit_type", "")).to_lower()
			var is_rat := bool(event.get("is_rat", false)) or unit_type in ["burrow", "bristle", "monarch", "dusk", "matriarch"]
			if is_rat or unit_type in ["burrow", "bristle", "monarch", "dusk", "matriarch"]:
				match unit_type:
					"matriarch": play("matriarch_roar", 4.0)
					"monarch": play("monarch_fanfare", 2.0)
					"bristle": play("bristle_rattle", 2.0)
					"dusk": play("dusk_vanish", 1.0)
					_: play("burrow_break", 2.0)
			else:
				match coat:
					"iron": play("iron_clang", 0.0)
					"porcelain": play("porcelain_pop", 1.0)
					"grain": play("grain_pop", -2.0)
					"rust": play("rust_pop", -3.0)
					"slate": play("slate_pop", -2.0)
					"moss": play("moss_pop", -3.0)
					"sugar": play("sugar_pop", -1.0)
					"soot": play("soot_pop", -2.0)
					"frost": play("frost_shiver", -1.0)
					"ink": play("ink_swallow", 0.0)
					"marble": play("marble_crash", 1.0)
					"prism": play("prism_shimmer", 1.0)
					_: play("pop", -2.0)
		"leak":
			play("leak", 2.0)

func play(sound_name: String, volume_db: float = 0.0) -> void:
	if not is_ready or players.is_empty():
		return
	var stream: AudioStreamWAV = streams.get(sound_name)
	if stream == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var min_gap: float = min_intervals.get(sound_name, 0.04)
	if now - float(last_played.get(sound_name, -999.0)) < min_gap:
		return
	last_played[sound_name] = now

	var player: AudioStreamPlayer = players[player_index]
	if not player.is_inside_tree():
		return
	player_index = (player_index + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.96, 1.04)
	player.play()

func _synthesize_all_sounds() -> void:
	# Group 1 Cats
	streams["pip_click"] = _build_sound(0.025, func(t: float, _d: float) -> float:
		var env: float = exp(-t * 220.0)
		return (sin(TAU * 3400.0 * t) * 0.7 + sin(TAU * 1900.0 * t) * 0.3) * env
	)
	streams["nibs_swipe"] = _build_sound(0.075, func(t: float, d: float) -> float:
		var env: float = sin(PI * (t / d))
		var freq: float = lerpf(1800.0, 500.0, t / d)
		return (randf_range(-1.0, 1.0) * 0.65 + sin(TAU * freq * t) * 0.35) * env
	)
	streams["pudding_pulse"] = _build_sound(0.18, func(t: float, d: float) -> float:
		var env: float = exp(-t * 18.0) * (1.0 - t / d)
		return (sin(TAU * 880.0 * t) * 0.45 + sin(TAU * 1320.0 * t) * 0.35 + randf_range(-1.0, 1.0) * 0.20 * exp(-t * 30.0)) * env
	)
	streams["biscuit_thump"] = _build_sound(0.15, func(t: float, d: float) -> float:
		var punch: float = sin(TAU * 85.0 * t) * exp(-t * 32.0)
		var rumble: float = randf_range(-1.0, 1.0) * (1.0 - t / d) * exp(-t * 16.0) * 0.4
		return punch * 0.7 + rumble * 0.3
	)

	# Group 2 Cats
	streams["sable_crack"] = _build_sound(0.12, func(t: float, d: float) -> float:
		var impulse: float = sin(TAU * 1400.0 * t) * exp(-t * 45.0)
		var snap: float = randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.5
		var tail: float = sin(TAU * 180.0 * t) * (1.0 - t / d) * exp(-t * 18.0) * 0.3
		return impulse * 0.6 + snap + tail
	)
	streams["nim_zap"] = _build_sound(0.09, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d)
		var buzz: float = sin(TAU * 720.0 * t) * 0.5 + sin(TAU * 1440.0 * t) * 0.3
		var crackle: float = (1.0 if randf() > 0.6 else -1.0) * 0.4
		return (buzz + crackle) * env
	)
	streams["goldie_net"] = _build_sound(0.10, func(t: float, d: float) -> float:
		var env: float = sin(PI * (t / d))
		var woosh: float = randf_range(-1.0, 1.0) * env * 0.6
		var clink: float = sin(TAU * 2200.0 * t) * exp(-t * 30.0) * 0.4
		return woosh + clink
	)
	streams["miso_chime"] = _build_sound(0.16, func(t: float, d: float) -> float:
		var env: float = exp(-t * 12.0) * (1.0 - t / d)
		var chime: float = sin(TAU * 1046.5 * t) * 0.5 + sin(TAU * 1568.0 * t) * 0.35 + sin(TAU * 2093.0 * t) * 0.15
		return chime * env
	)
	streams["bub_clink"] = _build_sound(0.10, func(t: float, d: float) -> float:
		var env: float = exp(-t * 28.0) * (1.0 - t / d)
		return (sin(TAU * 1900.0 * t) * 0.55 + sin(TAU * 2850.0 * t) * 0.30 + randf_range(-1.0, 1.0) * 0.15) * env
	)
	streams["bub_hiss"] = _build_sound(0.20, func(t: float, d: float) -> float:
		var env: float = sin(PI * (t / d)) * exp(-t * 5.0)
		var fizz: float = randf_range(-1.0, 1.0) * 0.65
		var bubble: float = sin(TAU * (180.0 + 120.0 * t / d) * t) * 0.35
		return (fizz + bubble) * env
	)

	# Group 4 Heroes
	streams["mittens_whistle"] = _build_sound(0.08, func(t: float, d: float) -> float:
		var env: float = sin(PI * (t / d))
		return sin(TAU * 2800.0 * t) * env * 0.8
	)
	streams["duchess_fan"] = _build_sound(0.06, func(t: float, d: float) -> float:
		var env: float = sin(PI * (t / d))
		return randf_range(-1.0, 1.0) * env * 0.5 + sin(TAU * 1600.0 * t) * exp(-t * 50.0) * 0.5
	)
	streams["baron_anchor"] = _build_sound(0.18, func(t: float, d: float) -> float:
		var sub: float = sin(TAU * 55.0 * t) * (1.0 - t / d)
		var rattle: float = randf_range(-1.0, 1.0) * exp(-t * 20.0) * 0.4
		return sub * 0.7 + rattle * 0.3
	)
	streams["pebble_bell"] = _build_sound(0.24, func(t: float, d: float) -> float:
		var env: float = exp(-t * 8.0) * (1.0 - t / d)
		var bell: float = sin(TAU * 659.25 * t) * 0.6 + sin(TAU * 1318.5 * t) * 0.3 + sin(TAU * 1977.7 * t) * 0.1
		return bell * env
	)

	# Group 1 Mice
	streams["rust_pop"] = _build_sound(0.045, func(t: float, d: float) -> float:
		return sin(TAU * lerpf(220.0, 80.0, t / d) * t) * (1.0 - t / d)
	)
	streams["grain_pop"] = _build_sound(0.045, func(t: float, d: float) -> float:
		return sin(TAU * lerpf(340.0, 140.0, t / d) * t) * (1.0 - t / d)
	)
	streams["iron_clang"] = _build_sound(0.18, func(t: float, _d: float) -> float:
		var env: float = exp(-t * 22.0)
		return (sin(TAU * 1180.0 * t) * 0.5 + sin(TAU * 2420.0 * t) * 0.35 + sin(TAU * 3860.0 * t) * 0.15) * env
	)
	streams["porcelain_pop"] = _build_sound(0.07, func(t: float, d: float) -> float:
		var env: float = exp(-t * 40.0) * (1.0 - t / d)
		return (sin(TAU * lerpf(2600.0, 1200.0, t / d) * t) * 0.7 + randf_range(-1.0, 1.0) * 0.3 * exp(-t * 70.0)) * env
	)

	# Group 2 Mice
	streams["slate_pop"] = _build_sound(0.045, func(t: float, d: float) -> float:
		return sin(TAU * lerpf(200.0, 75.0, t / d) * t) * (1.0 - t / d)
	)
	streams["moss_pop"] = _build_sound(0.045, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d)
		return (sin(TAU * lerpf(280.0, 110.0, t / d) * t) * 0.6 + randf_range(-1.0, 1.0) * 0.4) * env
	)
	streams["sugar_pop"] = _build_sound(0.045, func(t: float, d: float) -> float:
		return (sin(TAU * lerpf(440.0, 220.0, t / d) * t) * 0.7 + sin(TAU * 880.0 * t) * 0.3) * (1.0 - t / d)
	)
	streams["soot_pop"] = _build_sound(0.05, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d)
		return (sin(TAU * 120.0 * t) * 0.4 + randf_range(-1.0, 1.0) * 0.6) * env
	)

	# Group 3 Mice
	streams["frost_shiver"] = _build_sound(0.05, func(t: float, d: float) -> float:
		return (sin(TAU * lerpf(1600.0, 600.0, t / d) * t) * 0.6 + randf_range(-1.0, 1.0) * 0.4) * (1.0 - t / d)
	)
	streams["ink_swallow"] = _build_sound(0.12, func(t: float, d: float) -> float:
		var env: float = sin(PI * (t / d))
		var gulp: float = sin(TAU * lerpf(180.0, 320.0, t / d) * t)
		return gulp * env
	)
	streams["marble_crash"] = _build_sound(0.18, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d) * exp(-t * 14.0)
		var thud: float = sin(TAU * 90.0 * t) * 0.7
		var grit: float = randf_range(-1.0, 1.0) * 0.3
		return (thud + grit) * env
	)
	streams["prism_shimmer"] = _build_sound(0.14, func(t: float, d: float) -> float:
		var env: float = exp(-t * 16.0) * (1.0 - t / d)
		var chime: float = sin(TAU * 1760.0 * t) * 0.4 + sin(TAU * 2637.0 * t) * 0.35 + sin(TAU * 3520.0 * t) * 0.25
		return chime * env
	)

	# Rats
	streams["burrow_break"] = _build_sound(0.22, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d) * exp(-t * 12.0)
		return (sin(TAU * lerpf(65.0, 40.0, t / d) * t) * 0.65 + randf_range(-1.0, 1.0) * exp(-t * 28.0) * 0.35) * env
	)
	streams["bristle_rattle"] = _build_sound(0.20, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d) * exp(-t * 10.0)
		var clatter: float = sin(TAU * 340.0 * t) * (1.0 if int(t * 80.0) % 2 == 0 else -1.0) * 0.6
		return clatter * env
	)
	streams["monarch_fanfare"] = _build_sound(0.25, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d)
		var brass: float = sin(TAU * 440.0 * t) * 0.5 + sin(TAU * 660.0 * t) * 0.3 + sin(TAU * 880.0 * t) * 0.2
		return brass * env
	)
	streams["dusk_vanish"] = _build_sound(0.15, func(t: float, d: float) -> float:
		var env: float = sin(PI * (t / d))
		return randf_range(-1.0, 1.0) * env * 0.7
	)
	streams["matriarch_roar"] = _build_sound(0.35, func(t: float, d: float) -> float:
		var env: float = (1.0 - t / d) * exp(-t * 6.0)
		var sub: float = sin(TAU * lerpf(50.0, 28.0, t / d) * t) * 0.7
		var rumble: float = randf_range(-1.0, 1.0) * 0.3
		return (sub + rumble) * env
	)

	# Fallbacks
	streams["pop"] = streams["rust_pop"]
	streams["leak"] = _build_sound(0.20, func(t: float, d: float) -> float:
		return sin(TAU * 60.0 * t) * (1.0 - t / d) * exp(-t * 10.0)
	)

func _build_sound(duration: float, formula: Callable) -> AudioStreamWAV:
	var total_samples := int(duration * MIX_RATE)
	var raw := PackedByteArray()
	raw.resize(total_samples * 2)
	for i in range(total_samples):
		var t := float(i) / float(MIX_RATE)
		var s: float = formula.call(t, duration)
		var val := int(clampf(s, -1.0, 1.0) * 32767.0)
		raw.encode_s16(i * 2, val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = raw
	return wav
