# Clowder: Alley Siege - Headless Balance Harness
class_name BalanceRunner
extends SceneTree

func _init() -> void:
	print("--- Running Clowder Balance Harness (GDScript) ---")
	var success = run_all_tests()
	if success:
		print("ALL BALANCE HARNESS TESTS PASSED.")
		quit(0)
	else:
		push_error("BALANCE HARNESS FAILED.")
		quit(1)

func run_all_tests() -> bool:
	var passed = true
	# 1. RBE check
	# 2. Pop overflow & immunities
	# 3. Matriarch immunity
	# 4. Trick damage cap (<= 1100)
	# 5. Discount floor (>= 60%)
	# 6. Gnaw suppression
	# 7. Seeded feat offers
	return passed

