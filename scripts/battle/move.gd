extends Resource
class_name Move
## Move - Defines a combat move/technique

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

# Basic info
@export var move_name: String = "Jab"
@export var move_type: MoveType = MoveType.BASIC
@export var description: String = ""

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
