extends Resource
class_name FighterStats
## FighterStats - Six-dimensional attribute system for fighters

# Base attributes (1-10 scale, 5 is average)
@export var strength: int = 5      # STR: Attack damage
@export var agility: int = 5       # AGI: Attack speed, evade chance
@export var vitality: int = 5      # VIT: Max HP, defense
@export var technique: int = 5     # TEC: Crit rate, combo success
@export var willpower: int = 5     # WIL: Recovery speed, low HP bonus
@export var intuition: int = 5     # INT: Counter chance, prediction

# Attribute caps
const MIN_STAT: int = 1
const MAX_STAT: int = 10
const BASE_STAT: int = 5

# Derived stat multipliers
const HP_PER_VIT: float = 20.0
const BASE_HP: float = 50.0
const DAMAGE_PER_STR: float = 2.0
const BASE_DAMAGE: float = 5.0
const DEFENSE_PER_VIT: float = 0.02
const SPEED_PER_AGI: float = 0.1
const CRIT_PER_TEC: float = 0.03
const EVADE_PER_AGI: float = 0.02
const COUNTER_PER_INT: float = 0.03
const RECOVERY_PER_WIL: float = 0.1


func _init() -> void:
	pass


# ===== Derived Stats =====

func get_max_hp() -> float:
	return BASE_HP + (vitality * HP_PER_VIT)


func get_base_damage() -> float:
	return BASE_DAMAGE + (strength * DAMAGE_PER_STR)


func get_defense_multiplier() -> float:
	# Returns damage reduction (0.0 to ~0.2)
	return vitality * DEFENSE_PER_VIT


func get_attack_speed_multiplier() -> float:
	# Returns speed modifier (0.5 to 1.5)
	return 0.5 + (agility * SPEED_PER_AGI)


func get_crit_chance() -> float:
	# Returns crit chance (0.03 to 0.30)
	return technique * CRIT_PER_TEC


func get_evade_chance() -> float:
	# Returns base evade chance (0.02 to 0.20)
	return agility * EVADE_PER_AGI


func get_counter_chance() -> float:
	# Returns counter chance (0.03 to 0.30)
	return intuition * COUNTER_PER_INT


func get_recovery_speed() -> float:
	# Returns recovery speed multiplier (0.5 to 1.5)
	return 0.5 + (willpower * RECOVERY_PER_WIL)


func get_low_hp_bonus(hp_ratio: float) -> float:
	# Willpower gives bonus when HP is low
	if hp_ratio > 0.3:
		return 1.0
	# Up to 50% bonus at low HP based on willpower
	var bonus = (1.0 - hp_ratio / 0.3) * (willpower / 10.0) * 0.5
	return 1.0 + bonus


# ===== AI Decision Modifiers =====

func get_ai_attack_modifier() -> float:
	# STR and TEC increase attack tendency
	return 0.8 + (strength + technique) * 0.02


func get_ai_defend_modifier() -> float:
	# VIT and WIL increase defense tendency
	return 0.8 + (vitality + willpower) * 0.02


func get_ai_evade_modifier() -> float:
	# AGI increases evade tendency
	return 0.8 + agility * 0.04


func get_ai_counter_modifier() -> float:
	# INT increases counter tendency
	return 0.8 + intuition * 0.04


# ===== Utility =====

func get_total_points() -> int:
	return strength + agility + vitality + technique + willpower + intuition


func clone():
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = strength
	s.agility = agility
	s.vitality = vitality
	s.technique = technique
	s.willpower = willpower
	s.intuition = intuition
	return s


func to_dict() -> Dictionary:
	return {
		"STR": strength,
		"AGI": agility,
		"VIT": vitality,
		"TEC": technique,
		"WIL": willpower,
		"INT": intuition
	}


static func create_balanced():
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 5
	s.agility = 5
	s.vitality = 5
	s.technique = 5
	s.willpower = 5
	s.intuition = 5
	return s


static func create_brawler():
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 8
	s.agility = 3
	s.vitality = 7
	s.technique = 4
	s.willpower = 6
	s.intuition = 2
	return s


static func create_speedster():
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 4
	s.agility = 8
	s.vitality = 3
	s.technique = 7
	s.willpower = 4
	s.intuition = 4
	return s


static func create_tank():
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 4
	s.agility = 3
	s.vitality = 9
	s.technique = 3
	s.willpower = 8
	s.intuition = 3
	return s


static func create_technician():
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 5
	s.agility = 5
	s.vitality = 4
	s.technique = 8
	s.willpower = 4
	s.intuition = 8
	return s


static func create_counter_puncher():
	# High INT for counters, good defense
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 6
	s.agility = 5
	s.vitality = 5
	s.technique = 4
	s.willpower = 5
	s.intuition = 9
	return s


static func create_glass_cannon():
	# Very high offense, very low defense
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 9
	s.agility = 7
	s.vitality = 2
	s.technique = 6
	s.willpower = 3
	s.intuition = 3
	return s


static func create_survivor():
	# High willpower, good at comebacks
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	s.strength = 5
	s.agility = 4
	s.vitality = 6
	s.technique = 4
	s.willpower = 9
	s.intuition = 6
	return s


static func create_wild_card():
	# Random high stats
	var s = load("res://scripts/battle/fighter_stats.gd").new()
	var stats_pool = [3, 4, 5, 6, 7, 8]
	stats_pool.shuffle()
	s.strength = stats_pool[0]
	s.agility = stats_pool[1]
	s.vitality = stats_pool[2]
	s.technique = stats_pool[3]
	s.willpower = stats_pool[4]
	s.intuition = stats_pool[5]
	return s
