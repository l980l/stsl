class_name CombatScale
extends RefCounted

# Explicit legacy mode is for historical regression/comparison harnesses only.
static func enabled() -> bool:
	return OS.get_environment("STSL_LEGACY_COMBAT") != "1"

static func amount(value: int) -> int:
	if not enabled() or value == 0:
		return value
	var magnitude := maxi(1, int(floor(absf(float(value)) / 10.0 + 0.5)))
	return magnitude if value > 0 else -magnitude

# For small bonuses earned repeatedly, round the total rather than inflating
# every individual earning to the minimum one-point combat quantum.
static func accumulated(value: int) -> int:
	if not enabled():
		return value
	var magnitude := int(floor(absf(float(value)) / 10.0 + 0.5))
	return magnitude if value >= 0 else -magnitude
