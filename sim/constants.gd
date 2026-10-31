# Clowder: Alley Siege - Sim Constants
class_name SimConstants

enum DamageType {
	CLAW,
	BITE,
	BLAST,
	MAGIC,
	ACID,
	VOID,
	TRUE
}

enum StatusType {
	CHILL,
	FREEZE,
	BURN,
	STUN,
	MARK,
	HEX
}

enum TargetPriority {
	FIRST,
	LAST,
	STRONG,
	CLOSE,
	RATS_FIRST,
	MICE_FIRST
}

enum CatCategory {
	ALLEY,
	HUNT,
	MYTH,
	DEN
}

enum GameMode {
	SUNNY,
	ALLEY,
	NIGHT,
	LAST_WHISKER,
	BARE_PAW
}

const TICK_RATE: float = 30.0
const TICK_DELTA: float = 1.0 / 30.0

static func damage_type_from_string(val: String) -> int:
	match val.to_upper():
		"CLAW": return DamageType.CLAW
		"BITE": return DamageType.BITE
		"BLAST": return DamageType.BLAST
		"MAGIC": return DamageType.MAGIC
		"ACID": return DamageType.ACID
		"VOID": return DamageType.VOID
		"TRUE": return DamageType.TRUE
		_: return DamageType.TRUE

static func damage_type_to_string(val: int) -> String:
	match val:
		DamageType.CLAW: return "Claw"
		DamageType.BITE: return "Bite"
		DamageType.BLAST: return "Blast"
		DamageType.MAGIC: return "Magic"
		DamageType.ACID: return "Acid"
		DamageType.VOID: return "Void"
		DamageType.TRUE: return "True"
		_: return "Claw"

static func target_priority_to_string(val: int) -> String:
	match val:
		TargetPriority.FIRST: return "First"
		TargetPriority.LAST: return "Last"
		TargetPriority.STRONG: return "Strong"
		TargetPriority.CLOSE: return "Close"
		TargetPriority.RATS_FIRST: return "Rats First"
		TargetPriority.MICE_FIRST: return "Mice First"
		_: return "First"


static func is_immune_to_damage(immunities: Array, damage_type: int) -> bool:
	match damage_type:
		DamageType.CLAW:
			return immunities.has("Claw")
		DamageType.BLAST:
			return immunities.has("Blast")
		DamageType.MAGIC:
			return immunities.has("Magic")
		DamageType.BITE, DamageType.ACID, DamageType.VOID, DamageType.TRUE:
			return false
	return false

