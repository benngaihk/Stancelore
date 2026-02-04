extends Resource
class_name Move
## Move - Defines a combat move/technique with optional affixes

enum MoveType {
	BASIC,      # Basic attacks, no cooldown
	SKILL,      # Skills with cooldown
	ULTIMATE    # Powerful moves with conditions
}

enum HitZone {
	HIGH,       # Head level
	MID,        # Body level
	LOW         # Leg level
}

# ===== Affix System =====
enum ElementAffix {
	NONE,
	FIRE,       # Burn damage over time
	ICE,        # Slow enemy
	LIGHTNING,  # Chance to stun
	WIND,       # Increased knockback
	EARTH       # Increased hitstun
}

enum EffectAffix {
	NONE,
	STUN,       # Chance to stun on hit
	BLEED,      # Damage over time
	DRAIN,      # Heal on hit
	ARMOR_BREAK,# Reduce defense
	GUARD_CRUSH # Extra damage to blocking enemies
}

enum QualityAffix {
	NONE,
	SWIFT,      # Faster startup/recovery
	HEAVY,      # More damage, slower
	PRECISE,    # Higher crit chance
	WILD,       # Random damage range
	RELENTLESS  # Reduced stamina cost
}

# Basic info
@export var move_name: String = "Jab"
@export var base_name: String = ""  # Original name before affixes
@export var move_type: MoveType = MoveType.BASIC
@export var description: String = ""

# Affixes
@export var element_affix: ElementAffix = ElementAffix.NONE
@export var effect_affix: EffectAffix = EffectAffix.NONE
@export var quality_affix: QualityAffix = QualityAffix.NONE

# Combat properties
@export var damage_multiplier: float = 1.0
@export var stamina_cost: float = 10.0
@export var hit_zone: HitZone = HitZone.MID
@export var range_modifier: float = 1.0  # Multiplies base attack range

# Timing (multipliers on base durations)
@export var startup_multiplier: float = 1.0   # Wind-up time
@export var active_multiplier: float = 1.0    # Hit window
@export var recovery_multiplier: float = 1.0  # End lag

# Effects
@export var knockback_force: float = 1.0
@export var hitstun_multiplier: float = 1.0
@export var can_combo: bool = true
@export var combo_starter: bool = false  # Good for starting combos
@export var combo_ender: bool = false    # High damage but ends combo

# Affix-specific properties
@export var burn_damage: float = 0.0      # Fire: DPS
@export var slow_amount: float = 0.0      # Ice: speed reduction %
@export var stun_chance: float = 0.0      # Lightning/Stun: 0-1
@export var bleed_damage: float = 0.0     # Bleed: DPS
@export var drain_percent: float = 0.0    # Drain: % of damage healed
@export var armor_break_amount: float = 0.0  # Armor Break: defense reduction
@export var crit_chance_bonus: float = 0.0   # Precise: extra crit chance

# Skill-specific
@export var cooldown: float = 0.0  # Seconds
@export var required_combo_count: int = 0  # Min combo to use

# Visual
@export var color_tint: Color = Color.WHITE


func get_total_duration_multiplier() -> float:
	return startup_multiplier + active_multiplier + recovery_multiplier


func can_use(fighter: FighterController) -> bool:
	# Check stamina
	if fighter.stamina < stamina_cost:
		return false

	# Check combo requirement
	if required_combo_count > 0 and fighter.combo_count < required_combo_count:
		return false

	return true


func has_affix() -> bool:
	return element_affix != ElementAffix.NONE or effect_affix != EffectAffix.NONE or quality_affix != QualityAffix.NONE


func get_display_name() -> String:
	var prefix = ""
	var suffix = ""

	# Quality prefix
	match quality_affix:
		QualityAffix.SWIFT: prefix = "Swift "
		QualityAffix.HEAVY: prefix = "Heavy "
		QualityAffix.PRECISE: prefix = "Precise "
		QualityAffix.WILD: prefix = "Wild "
		QualityAffix.RELENTLESS: prefix = "Relentless "

	# Element/Effect suffix
	match element_affix:
		ElementAffix.FIRE: suffix = " of Flame"
		ElementAffix.ICE: suffix = " of Frost"
		ElementAffix.LIGHTNING: suffix = " of Thunder"
		ElementAffix.WIND: suffix = " of Wind"
		ElementAffix.EARTH: suffix = " of Stone"

	if effect_affix != EffectAffix.NONE and element_affix == ElementAffix.NONE:
		match effect_affix:
			EffectAffix.STUN: suffix = " [Stun]"
			EffectAffix.BLEED: suffix = " [Bleed]"
			EffectAffix.DRAIN: suffix = " [Drain]"
			EffectAffix.ARMOR_BREAK: suffix = " [Crush]"
			EffectAffix.GUARD_CRUSH: suffix = " [Break]"

	return prefix + base_name + suffix


func apply_element_affix(affix: ElementAffix) -> void:
	element_affix = affix
	match affix:
		ElementAffix.FIRE:
			burn_damage = damage_multiplier * 5.0  # 5 DPS per damage mult
			color_tint = Color(1.0, 0.4, 0.2)
			stamina_cost *= 1.1
		ElementAffix.ICE:
			slow_amount = 0.3  # 30% slow
			color_tint = Color(0.4, 0.8, 1.0)
			stamina_cost *= 1.1
		ElementAffix.LIGHTNING:
			stun_chance = 0.15  # 15% stun chance
			color_tint = Color(1.0, 1.0, 0.4)
			stamina_cost *= 1.15
		ElementAffix.WIND:
			knockback_force *= 1.5
			color_tint = Color(0.7, 1.0, 0.7)
		ElementAffix.EARTH:
			hitstun_multiplier *= 1.3
			color_tint = Color(0.7, 0.5, 0.3)
			startup_multiplier *= 1.1

	_update_name()


func apply_effect_affix(affix: EffectAffix) -> void:
	effect_affix = affix
	match affix:
		EffectAffix.STUN:
			stun_chance = 0.2  # 20% stun chance
			stamina_cost *= 1.15
		EffectAffix.BLEED:
			bleed_damage = damage_multiplier * 3.0  # 3 DPS
			stamina_cost *= 1.1
		EffectAffix.DRAIN:
			drain_percent = 0.2  # Heal 20% of damage
			stamina_cost *= 1.2
		EffectAffix.ARMOR_BREAK:
			armor_break_amount = 0.2  # Reduce defense by 20%
			stamina_cost *= 1.1
		EffectAffix.GUARD_CRUSH:
			# Double damage to blocking enemies (handled in combat)
			stamina_cost *= 1.1

	_update_name()


func apply_quality_affix(affix: QualityAffix) -> void:
	quality_affix = affix
	match affix:
		QualityAffix.SWIFT:
			startup_multiplier *= 0.75
			recovery_multiplier *= 0.8
			damage_multiplier *= 0.9
		QualityAffix.HEAVY:
			damage_multiplier *= 1.3
			startup_multiplier *= 1.25
			recovery_multiplier *= 1.2
			knockback_force *= 1.2
		QualityAffix.PRECISE:
			crit_chance_bonus = 0.25  # +25% crit chance
			damage_multiplier *= 0.95
		QualityAffix.WILD:
			# Damage variation handled in combat (0.7x to 1.5x)
			damage_multiplier *= 1.1  # Average slightly higher
		QualityAffix.RELENTLESS:
			stamina_cost *= 0.7
			cooldown *= 0.8

	_update_name()


func _update_name() -> void:
	if base_name.is_empty():
		base_name = move_name
	move_name = get_display_name()


static func create_with_random_affix(base_move: Move, affix_tier: int = 1) -> Move:
	# Clone the base move
	var new_move = base_move.duplicate()
	new_move.base_name = base_move.move_name

	# Roll for affixes based on tier
	# Tier 1: 1 affix, Tier 2: 1-2 affixes, Tier 3: 2-3 affixes
	var num_affixes = clampi(randi_range(1, affix_tier), 1, 3)

	var applied = []
	for _i in range(num_affixes):
		var roll = randi() % 3
		match roll:
			0:  # Element
				if not applied.has("element"):
					var element = (randi() % 5) + 1  # Skip NONE
					new_move.apply_element_affix(element as ElementAffix)
					applied.append("element")
			1:  # Effect
				if not applied.has("effect"):
					var effect = (randi() % 5) + 1  # Skip NONE
					new_move.apply_effect_affix(effect as EffectAffix)
					applied.append("effect")
			2:  # Quality
				if not applied.has("quality"):
					var quality = (randi() % 5) + 1  # Skip NONE
					new_move.apply_quality_affix(quality as QualityAffix)
					applied.append("quality")

	return new_move


static func get_affix_description(move: Move) -> String:
	var lines = []

	if move.element_affix != ElementAffix.NONE:
		match move.element_affix:
			ElementAffix.FIRE:
				lines.append("Fire: Burns for %.0f/s" % move.burn_damage)
			ElementAffix.ICE:
				lines.append("Ice: Slows by %.0f%%" % (move.slow_amount * 100))
			ElementAffix.LIGHTNING:
				lines.append("Lightning: %.0f%% stun chance" % (move.stun_chance * 100))
			ElementAffix.WIND:
				lines.append("Wind: +50% knockback")
			ElementAffix.EARTH:
				lines.append("Earth: +30% hitstun")

	if move.effect_affix != EffectAffix.NONE:
		match move.effect_affix:
			EffectAffix.STUN:
				lines.append("Stun: %.0f%% stun chance" % (move.stun_chance * 100))
			EffectAffix.BLEED:
				lines.append("Bleed: %.0f/s over time" % move.bleed_damage)
			EffectAffix.DRAIN:
				lines.append("Drain: Heal %.0f%% of damage" % (move.drain_percent * 100))
			EffectAffix.ARMOR_BREAK:
				lines.append("Crush: -%.0f%% enemy defense" % (move.armor_break_amount * 100))
			EffectAffix.GUARD_CRUSH:
				lines.append("Break: 2x damage to blocking")

	if move.quality_affix != QualityAffix.NONE:
		match move.quality_affix:
			QualityAffix.SWIFT:
				lines.append("Swift: Faster but weaker")
			QualityAffix.HEAVY:
				lines.append("Heavy: Stronger but slower")
			QualityAffix.PRECISE:
				lines.append("Precise: +%.0f%% crit chance" % (move.crit_chance_bonus * 100))
			QualityAffix.WILD:
				lines.append("Wild: Variable damage")
			QualityAffix.RELENTLESS:
				lines.append("Relentless: -30% stamina cost")

	return "\n".join(lines)


# ===== Preset Moves =====

static func create_jab():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Jab"
	move.move_type = MoveType.BASIC
	move.description = "Quick straight punch"
	move.damage_multiplier = 0.8
	move.stamina_cost = 8.0
	move.hit_zone = HitZone.HIGH
	move.startup_multiplier = 0.7
	move.recovery_multiplier = 0.7
	move.knockback_force = 0.5
	move.combo_starter = true
	move.color_tint = Color(1.0, 0.9, 0.9)
	return move


static func create_straight() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Straight"
	move.move_type = MoveType.BASIC
	move.description = "Powerful straight punch"
	move.damage_multiplier = 1.2
	move.stamina_cost = 12.0
	move.hit_zone = HitZone.MID
	move.startup_multiplier = 1.0
	move.recovery_multiplier = 1.1
	move.knockback_force = 1.2
	move.color_tint = Color(1.0, 0.8, 0.8)
	return move


static func create_hook() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Hook"
	move.move_type = MoveType.BASIC
	move.description = "Powerful hook punch"
	move.damage_multiplier = 1.4
	move.stamina_cost = 15.0
	move.hit_zone = HitZone.HIGH
	move.startup_multiplier = 1.2
	move.recovery_multiplier = 1.3
	move.knockback_force = 1.5
	move.hitstun_multiplier = 1.2
	move.combo_ender = true
	move.color_tint = Color(1.0, 0.6, 0.6)
	return move


static func create_uppercut() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Uppercut"
	move.move_type = MoveType.BASIC
	move.description = "Rising uppercut"
	move.damage_multiplier = 1.3
	move.stamina_cost = 14.0
	move.hit_zone = HitZone.HIGH
	move.startup_multiplier = 1.1
	move.recovery_multiplier = 1.2
	move.knockback_force = 1.8
	move.hitstun_multiplier = 1.3
	move.color_tint = Color(1.0, 0.7, 0.5)
	return move


static func create_body_blow() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Body Blow"
	move.move_type = MoveType.BASIC
	move.description = "Attack to the body"
	move.damage_multiplier = 1.1
	move.stamina_cost = 11.0
	move.hit_zone = HitZone.MID
	move.startup_multiplier = 0.9
	move.recovery_multiplier = 0.9
	move.knockback_force = 0.8
	move.color_tint = Color(0.9, 0.9, 1.0)
	return move


static func create_low_kick() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Low Kick"
	move.move_type = MoveType.BASIC
	move.description = "Quick leg kick"
	move.damage_multiplier = 0.9
	move.stamina_cost = 10.0
	move.hit_zone = HitZone.LOW
	move.range_modifier = 1.2
	move.startup_multiplier = 0.8
	move.recovery_multiplier = 0.8
	move.knockback_force = 0.6
	move.color_tint = Color(0.9, 1.0, 0.9)
	return move


# ===== Skill Moves =====

static func create_flurry() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Flurry"
	move.move_type = MoveType.SKILL
	move.description = "Rapid series of punches"
	move.damage_multiplier = 2.0  # Multiple hits
	move.stamina_cost = 25.0
	move.hit_zone = HitZone.MID
	move.startup_multiplier = 0.8
	move.active_multiplier = 2.0
	move.recovery_multiplier = 1.5
	move.knockback_force = 0.3
	move.cooldown = 8.0
	move.can_combo = false
	move.color_tint = Color(1.0, 0.5, 0.5)
	return move


static func create_counter_punch() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Counter"
	move.move_type = MoveType.SKILL
	move.description = "Counter attack after blocking"
	move.damage_multiplier = 1.8
	move.stamina_cost = 20.0
	move.hit_zone = HitZone.HIGH
	move.startup_multiplier = 0.5  # Very fast
	move.recovery_multiplier = 1.0
	move.knockback_force = 2.0
	move.hitstun_multiplier = 1.5
	move.cooldown = 10.0
	move.color_tint = Color(0.5, 0.5, 1.0)
	return move


static func create_haymaker() :
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Haymaker"
	move.move_type = MoveType.ULTIMATE
	move.description = "Devastating power punch"
	move.damage_multiplier = 3.0
	move.stamina_cost = 40.0
	move.hit_zone = HitZone.HIGH
	move.startup_multiplier = 2.0  # Very slow
	move.recovery_multiplier = 2.0
	move.knockback_force = 3.0
	move.hitstun_multiplier = 2.0
	move.cooldown = 20.0
	move.required_combo_count = 3
	move.can_combo = false
	move.combo_ender = true
	move.color_tint = Color(1.0, 0.3, 0.0)
	return move


# ===== Kick Moves =====

static func create_front_kick():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Front Kick"
	move.move_type = MoveType.BASIC
	move.description = "Straight kick to push back"
	move.damage_multiplier = 1.0
	move.stamina_cost = 12.0
	move.hit_zone = HitZone.MID
	move.range_modifier = 1.4
	move.startup_multiplier = 1.0
	move.recovery_multiplier = 1.1
	move.knockback_force = 2.0  # High knockback
	move.color_tint = Color(0.8, 1.0, 0.8)
	return move


static func create_roundhouse():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Roundhouse"
	move.move_type = MoveType.SKILL
	move.description = "Powerful spinning kick"
	move.damage_multiplier = 1.6
	move.stamina_cost = 18.0
	move.hit_zone = HitZone.HIGH
	move.range_modifier = 1.3
	move.startup_multiplier = 1.3
	move.recovery_multiplier = 1.4
	move.knockback_force = 2.5
	move.hitstun_multiplier = 1.4
	move.cooldown = 6.0
	move.combo_ender = true
	move.color_tint = Color(1.0, 0.8, 0.4)
	return move


static func create_knee_strike():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Knee Strike"
	move.move_type = MoveType.BASIC
	move.description = "Close-range knee attack"
	move.damage_multiplier = 1.2
	move.stamina_cost = 11.0
	move.hit_zone = HitZone.MID
	move.range_modifier = 0.7  # Short range
	move.startup_multiplier = 0.8
	move.recovery_multiplier = 0.9
	move.knockback_force = 1.0
	move.hitstun_multiplier = 1.2
	move.color_tint = Color(0.9, 0.8, 1.0)
	return move


static func create_spinning_backfist():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Backfist"
	move.move_type = MoveType.SKILL
	move.description = "Spinning backfist strike"
	move.damage_multiplier = 1.5
	move.stamina_cost = 16.0
	move.hit_zone = HitZone.HIGH
	move.startup_multiplier = 1.1
	move.recovery_multiplier = 1.2
	move.knockback_force = 1.8
	move.hitstun_multiplier = 1.3
	move.cooldown = 5.0
	move.color_tint = Color(0.8, 0.6, 1.0)
	return move


static func create_elbow_strike():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Elbow"
	move.move_type = MoveType.BASIC
	move.description = "Close-range elbow strike"
	move.damage_multiplier = 1.3
	move.stamina_cost = 13.0
	move.hit_zone = HitZone.HIGH
	move.range_modifier = 0.6  # Very short range
	move.startup_multiplier = 0.7
	move.recovery_multiplier = 0.8
	move.knockback_force = 0.8
	move.hitstun_multiplier = 1.4
	move.combo_starter = true
	move.color_tint = Color(1.0, 0.7, 0.7)
	return move


# ===== Special Moves =====

static func create_dempsey_roll():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Dempsey Roll"
	move.move_type = MoveType.ULTIMATE
	move.description = "Weaving combo of hooks"
	move.damage_multiplier = 2.5
	move.stamina_cost = 35.0
	move.hit_zone = HitZone.MID
	move.startup_multiplier = 1.5
	move.active_multiplier = 2.5
	move.recovery_multiplier = 1.8
	move.knockback_force = 2.0
	move.hitstun_multiplier = 1.5
	move.cooldown = 15.0
	move.required_combo_count = 2
	move.can_combo = false
	move.color_tint = Color(1.0, 0.4, 0.2)
	return move


static func create_gazelle_punch():
	var move = load("res://scripts/battle/move.gd").new()
	move.move_name = "Gazelle Punch"
	move.move_type = MoveType.SKILL
	move.description = "Leaping uppercut"
	move.damage_multiplier = 1.7
	move.stamina_cost = 22.0
	move.hit_zone = HitZone.HIGH
	move.startup_multiplier = 1.2
	move.recovery_multiplier = 1.3
	move.knockback_force = 2.2
	move.hitstun_multiplier = 1.6
	move.cooldown = 8.0
	move.combo_ender = true
	move.color_tint = Color(0.6, 0.8, 1.0)
	return move
