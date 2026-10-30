# Clowder: Alley Siege - Match Economy Manager
class_name SimEconomy
extends RefCounted

const SimConstants = preload("res://sim/constants.gd")

var kibble: int = 650
var mode: int = SimConstants.GameMode.ALLEY
var mode_price_multiplier: float = 1.00
var allow_selling: bool = true
var sell_refund_ratio: float = 0.70
var discount_floor_ratio: float = 0.60 # Can be improved to 0.55 via Den insight

func setup(p_mode: int, start_kibble_bonus: int = 0, clean_sell: bool = false) -> void:
	mode = p_mode
	match mode:
		SimConstants.GameMode.SUNNY:
			kibble = 850 + start_kibble_bonus
			mode_price_multiplier = 0.85
			allow_selling = true
		SimConstants.GameMode.ALLEY:
			kibble = 650 + start_kibble_bonus
			mode_price_multiplier = 1.00
			allow_selling = true
		SimConstants.GameMode.NIGHT:
			kibble = 550 + start_kibble_bonus
			mode_price_multiplier = 1.08
			allow_selling = true
		SimConstants.GameMode.LAST_WHISKER:
			kibble = 650 + start_kibble_bonus
			mode_price_multiplier = 1.20
			allow_selling = true
		SimConstants.GameMode.BARE_PAW:
			kibble = 650 # No bonus in Bare Paw
			mode_price_multiplier = 1.00
			allow_selling = false
			
	if clean_sell and allow_selling:
		sell_refund_ratio = 0.75
	else:
		sell_refund_ratio = 0.70

func get_pop_income_rate(round_num: int) -> float:
	if round_num <= 50:
		return 1.00
	elif round_num <= 80:
		return 0.85
	elif round_num <= 100:
		return 0.50
	else:
		var factor = 0.50 * pow(0.96, round_num - 100)
		return maxf(0.05, factor)

func add_pop_damage(hp_removed: int, round_num: int, shell_bounty: int = 0) -> int:
	var rate = get_pop_income_rate(round_num)
	var earned = int(floor(hp_removed * rate)) + shell_bounty
	kibble += earned
	return earned

func add_end_of_round_bonus(round_num: int) -> int:
	var bonus = 1 * round_num
	kibble += bonus
	return bonus

func calculate_price(base_cost: int, discounts: Array[float] = []) -> int:
	var mode_adjusted_base = float(base_cost) * mode_price_multiplier
	var highest_disc = 0.0
	for d in discounts:
		highest_disc = maxf(highest_disc, d)
	
	var discounted = mode_adjusted_base * (1.0 - highest_disc)
	var floor_price = mode_adjusted_base * discount_floor_ratio
	return int(round(maxf(discounted, floor_price)))

func can_afford(cost: int) -> bool:
	return kibble >= cost

func spend(amount: int) -> bool:
	if kibble >= amount:
		kibble -= amount
		return true
	return false

func refund_sell(total_spent_on_unit: int) -> int:
	if not allow_selling:
		return 0
	var refund = int(floor(total_spent_on_unit * sell_refund_ratio))
	kibble += refund
	return refund

func get_continue_cost(round_num: int) -> int:
	return 250 + 25 * round_num

