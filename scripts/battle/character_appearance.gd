extends Resource
class_name CharacterAppearance
## CharacterAppearance - Defines visual customization for fighters
## Includes hair styles, clothing, and color schemes

# ===== Hair Styles =====
enum HairStyle {
	BALD,           # No hair
	SHORT,          # Short cropped
	SPIKY,          # Anime spiky
	MOHAWK,         # Punk mohawk
	PONYTAIL,       # Tied back
	LONG,           # Long flowing
	AFRO,           # Big afro
	BRAIDS,         # Braided
	SLICKED,        # Slicked back
	MESSY           # Messy/wild
}

# ===== Clothing Styles =====
enum TopStyle {
	NONE,           # Shirtless
	TANK_TOP,       # Simple tank top
	T_SHIRT,        # T-shirt
	HOODIE,         # Hoodie
	GI_TOP,         # Martial arts gi
	JACKET,         # Open jacket
	VEST            # Sleeveless vest
}

enum BottomStyle {
	SHORTS,         # Fighting shorts
	PANTS,          # Long pants
	GI_PANTS,       # Martial arts pants
	TRUNKS,         # Boxing trunks
	BAGGY           # Baggy pants
}

# ===== Accessory =====
enum Accessory {
	NONE,
	HEADBAND,       # Fighting headband
	BANDANA,        # Wrapped bandana
	CAP,            # Baseball cap
	MASK,           # Face mask
	GLASSES,        # Sunglasses
	SCAR            # Face scar
}

# Character properties
@export var hair_style: HairStyle = HairStyle.SHORT
@export var top_style: TopStyle = TopStyle.TANK_TOP
@export var bottom_style: BottomStyle = BottomStyle.SHORTS
@export var accessory: Accessory = Accessory.NONE

# Colors
@export var skin_color: Color = Color(0.96, 0.80, 0.69)  # Default skin tone
@export var hair_color: Color = Color(0.15, 0.12, 0.10)  # Dark hair
@export var top_color: Color = Color(0.2, 0.4, 0.8)      # Blue top
@export var bottom_color: Color = Color(0.15, 0.15, 0.15) # Dark shorts
@export var accessory_color: Color = Color(0.9, 0.1, 0.1) # Red accessory
@export var glove_color: Color = Color(0.8, 0.1, 0.1)     # Red gloves

# Body build (affects proportions)
enum Build {
	SLIM,
	NORMAL,
	MUSCULAR,
	HEAVY
}
@export var build: Build = Build.NORMAL


func _init() -> void:
	pass


# Create random appearance
static func create_random() -> CharacterAppearance:
	var appearance = CharacterAppearance.new()

	# Random hair
	appearance.hair_style = randi() % HairStyle.size() as HairStyle
	appearance.hair_color = _random_hair_color()

	# Random clothing
	appearance.top_style = randi() % TopStyle.size() as TopStyle
	appearance.bottom_style = randi() % BottomStyle.size() as BottomStyle
	appearance.top_color = _random_clothing_color()
	appearance.bottom_color = _random_clothing_color()

	# Random accessory (30% chance)
	if randf() < 0.3:
		appearance.accessory = (randi() % (Accessory.size() - 1) + 1) as Accessory
		appearance.accessory_color = _random_clothing_color()

	# Random skin tone
	appearance.skin_color = _random_skin_color()

	# Random build
	appearance.build = randi() % Build.size() as Build

	# Random glove color
	appearance.glove_color = _random_glove_color()

	return appearance


static func _random_hair_color() -> Color:
	var colors = [
		Color(0.1, 0.08, 0.05),   # Black
		Color(0.35, 0.22, 0.12),  # Brown
		Color(0.85, 0.65, 0.35),  # Blonde
		Color(0.6, 0.25, 0.1),    # Red/Auburn
		Color(0.4, 0.4, 0.45),    # Gray
		Color(1.0, 1.0, 1.0),     # White
		Color(0.1, 0.3, 0.8),     # Blue (anime)
		Color(0.8, 0.2, 0.5),     # Pink (anime)
		Color(0.2, 0.7, 0.3),     # Green (anime)
	]
	return colors[randi() % colors.size()]


static func _random_skin_color() -> Color:
	var colors = [
		Color(1.0, 0.87, 0.77),   # Light
		Color(0.96, 0.80, 0.69),  # Fair
		Color(0.87, 0.72, 0.53),  # Medium
		Color(0.76, 0.57, 0.42),  # Tan
		Color(0.55, 0.38, 0.26),  # Brown
		Color(0.36, 0.24, 0.17),  # Dark
	]
	return colors[randi() % colors.size()]


static func _random_clothing_color() -> Color:
	var colors = [
		Color(0.1, 0.1, 0.1),     # Black
		Color(0.9, 0.9, 0.9),     # White
		Color(0.8, 0.1, 0.1),     # Red
		Color(0.1, 0.3, 0.8),     # Blue
		Color(0.1, 0.6, 0.2),     # Green
		Color(0.9, 0.7, 0.1),     # Yellow
		Color(0.6, 0.1, 0.6),     # Purple
		Color(0.9, 0.5, 0.1),     # Orange
		Color(0.4, 0.4, 0.4),     # Gray
	]
	return colors[randi() % colors.size()]


static func _random_glove_color() -> Color:
	var colors = [
		Color(0.8, 0.1, 0.1),     # Red
		Color(0.1, 0.1, 0.8),     # Blue
		Color(0.1, 0.1, 0.1),     # Black
		Color(0.9, 0.9, 0.9),     # White
		Color(0.9, 0.7, 0.1),     # Gold
		Color(0.1, 0.7, 0.2),     # Green
	]
	return colors[randi() % colors.size()]


# Preset appearances for player character archetypes
static func create_boxer() -> CharacterAppearance:
	var appearance = CharacterAppearance.new()
	appearance.hair_style = HairStyle.SHORT
	appearance.top_style = TopStyle.NONE
	appearance.bottom_style = BottomStyle.TRUNKS
	appearance.build = Build.MUSCULAR
	appearance.accessory = Accessory.NONE
	return appearance


static func create_martial_artist() -> CharacterAppearance:
	var appearance = CharacterAppearance.new()
	appearance.hair_style = HairStyle.PONYTAIL
	appearance.top_style = TopStyle.GI_TOP
	appearance.bottom_style = BottomStyle.GI_PANTS
	appearance.top_color = Color.WHITE
	appearance.bottom_color = Color.WHITE
	appearance.accessory = Accessory.HEADBAND
	appearance.accessory_color = Color.RED
	return appearance


static func create_street_fighter() -> CharacterAppearance:
	var appearance = CharacterAppearance.new()
	appearance.hair_style = HairStyle.SPIKY
	appearance.top_style = TopStyle.TANK_TOP
	appearance.bottom_style = BottomStyle.PANTS
	appearance.build = Build.NORMAL
	appearance.accessory = Accessory.BANDANA
	return appearance


static func create_brawler() -> CharacterAppearance:
	var appearance = CharacterAppearance.new()
	appearance.hair_style = HairStyle.MOHAWK
	appearance.top_style = TopStyle.VEST
	appearance.bottom_style = BottomStyle.BAGGY
	appearance.build = Build.HEAVY
	appearance.accessory = Accessory.SCAR
	return appearance
