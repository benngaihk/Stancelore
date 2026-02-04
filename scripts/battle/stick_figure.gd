extends Node2D
class_name StickFigure
## StickFigure - Simple skeleton visualization for fighter animations
## Now with hair, clothing, and accessories support

const CharacterAppearanceClass = preload("res://scripts/battle/character_appearance.gd")

# Body part colors (can be overridden by appearance)
@export var body_color: Color = Color.WHITE
@export var head_color: Color = Color.WHITE
@export var glove_color: Color = Color.RED
@export var line_width: float = 2.0

# Character appearance (optional - if null, uses simple stick figure)
var appearance: Resource = null  # CharacterAppearance

# Flash effect
var flash_timer: float = 0.0
var is_flashing: bool = false

# Body proportions (relative to scale)
const HEAD_RADIUS = 5.0
const TORSO_LENGTH = 12.0
const UPPER_ARM_LENGTH = 7.0
const LOWER_ARM_LENGTH = 7.0
const UPPER_LEG_LENGTH = 8.0
const LOWER_LEG_LENGTH = 8.0

# Joint positions (will be calculated)
var head_pos: Vector2 = Vector2.ZERO
var neck_pos: Vector2 = Vector2.ZERO
var hip_pos: Vector2 = Vector2.ZERO
var left_shoulder: Vector2 = Vector2.ZERO
var right_shoulder: Vector2 = Vector2.ZERO
var left_elbow: Vector2 = Vector2.ZERO
var right_elbow: Vector2 = Vector2.ZERO
var left_hand: Vector2 = Vector2.ZERO
var right_hand: Vector2 = Vector2.ZERO
var left_hip: Vector2 = Vector2.ZERO
var right_hip: Vector2 = Vector2.ZERO
var left_knee: Vector2 = Vector2.ZERO
var right_knee: Vector2 = Vector2.ZERO
var left_foot: Vector2 = Vector2.ZERO
var right_foot: Vector2 = Vector2.ZERO

# Current pose angles (in radians)
var torso_angle: float = 0.0
var left_upper_arm_angle: float = 0.3
var left_lower_arm_angle: float = 0.2
var right_upper_arm_angle: float = -0.3
var right_lower_arm_angle: float = -0.2
var left_upper_leg_angle: float = 0.1
var left_lower_leg_angle: float = 0.0
var right_upper_leg_angle: float = -0.1
var right_lower_leg_angle: float = 0.0

# Target pose for interpolation
var target_pose: Dictionary = {}
var pose_lerp_speed: float = 15.0

# Presets
enum Pose { IDLE, WALK_1, WALK_2, JAB, STRAIGHT, HOOK, UPPERCUT, DEFEND, EVADE, HIT, RECOVERY,
			FRONT_KICK, LOW_KICK, ROUNDHOUSE, KNEE_STRIKE, ELBOW, BACKFIST }


func _ready() -> void:
	set_pose(Pose.IDLE)


func set_appearance(new_appearance: Resource) -> void:
	appearance = new_appearance
	if appearance:
		glove_color = appearance.glove_color
		body_color = appearance.skin_color
		head_color = appearance.skin_color
	queue_redraw()


func _process(delta: float) -> void:
	# Update flash effect
	_update_flash(delta)

	# Interpolate to target pose
	if not target_pose.is_empty():
		_lerp_to_pose(delta)

	# Calculate joint positions
	_calculate_skeleton()

	# Trigger redraw
	queue_redraw()


func _calculate_skeleton() -> void:
	# Start from neck
	neck_pos = Vector2(0, -TORSO_LENGTH - HEAD_RADIUS)
	head_pos = neck_pos + Vector2(0, -HEAD_RADIUS)

	# Torso (slightly tilted based on torso_angle)
	var torso_dir = Vector2(sin(torso_angle), cos(torso_angle))
	hip_pos = neck_pos + torso_dir * TORSO_LENGTH

	# Shoulders (at neck level)
	left_shoulder = neck_pos + Vector2(-3, 0)
	right_shoulder = neck_pos + Vector2(3, 0)

	# Left arm
	var left_upper_dir = Vector2(sin(left_upper_arm_angle), cos(left_upper_arm_angle))
	left_elbow = left_shoulder + left_upper_dir * UPPER_ARM_LENGTH
	var left_lower_dir = Vector2(sin(left_upper_arm_angle + left_lower_arm_angle),
								  cos(left_upper_arm_angle + left_lower_arm_angle))
	left_hand = left_elbow + left_lower_dir * LOWER_ARM_LENGTH

	# Right arm
	var right_upper_dir = Vector2(sin(right_upper_arm_angle), cos(right_upper_arm_angle))
	right_elbow = right_shoulder + right_upper_dir * UPPER_ARM_LENGTH
	var right_lower_dir = Vector2(sin(right_upper_arm_angle + right_lower_arm_angle),
								   cos(right_upper_arm_angle + right_lower_arm_angle))
	right_hand = right_elbow + right_lower_dir * LOWER_ARM_LENGTH

	# Hips
	left_hip = hip_pos + Vector2(-2, 0)
	right_hip = hip_pos + Vector2(2, 0)

	# Left leg
	var left_upper_leg_dir = Vector2(sin(left_upper_leg_angle), cos(left_upper_leg_angle))
	left_knee = left_hip + left_upper_leg_dir * UPPER_LEG_LENGTH
	var left_lower_leg_dir = Vector2(sin(left_upper_leg_angle + left_lower_leg_angle),
									  cos(left_upper_leg_angle + left_lower_leg_angle))
	left_foot = left_knee + left_lower_leg_dir * LOWER_LEG_LENGTH

	# Right leg
	var right_upper_leg_dir = Vector2(sin(right_upper_leg_angle), cos(right_upper_leg_angle))
	right_knee = right_hip + right_upper_leg_dir * UPPER_LEG_LENGTH
	var right_lower_leg_dir = Vector2(sin(right_upper_leg_angle + right_lower_leg_angle),
									   cos(right_upper_leg_angle + right_lower_leg_angle))
	right_foot = right_knee + right_lower_leg_dir * LOWER_LEG_LENGTH


func _draw() -> void:
	# If we have an appearance, use the full rendering
	if appearance:
		_draw_with_appearance()
	else:
		_draw_simple()


func _draw_simple() -> void:
	var draw_color = body_color
	var head_draw_color = head_color

	# Flash white when hit
	if is_flashing:
		draw_color = Color.WHITE
		head_draw_color = Color.WHITE

	# Draw shadow (offset slightly)
	var shadow_offset = Vector2(2, 2)
	var shadow_color = Color(0, 0, 0, 0.3)
	draw_line(neck_pos + shadow_offset, hip_pos + shadow_offset, shadow_color, line_width)
	draw_line(left_shoulder + shadow_offset, left_elbow + shadow_offset, shadow_color, line_width)
	draw_line(left_elbow + shadow_offset, left_hand + shadow_offset, shadow_color, line_width)
	draw_line(right_shoulder + shadow_offset, right_elbow + shadow_offset, shadow_color, line_width)
	draw_line(right_elbow + shadow_offset, right_hand + shadow_offset, shadow_color, line_width)

	# Draw legs (behind body)
	draw_line(left_hip, left_knee, draw_color, line_width)
	draw_line(left_knee, left_foot, draw_color, line_width)
	draw_line(right_hip, right_knee, draw_color, line_width)
	draw_line(right_knee, right_foot, draw_color, line_width)

	# Draw feet
	draw_circle(left_foot, 2.0, draw_color)
	draw_circle(right_foot, 2.0, draw_color)

	# Draw torso
	draw_line(neck_pos, hip_pos, draw_color, line_width + 1)

	# Draw head
	draw_circle(head_pos, HEAD_RADIUS, head_draw_color)
	draw_arc(head_pos, HEAD_RADIUS, 0, TAU, 16, draw_color, line_width)

	# Draw arms
	draw_line(left_shoulder, left_elbow, draw_color, line_width)
	draw_line(left_elbow, left_hand, draw_color, line_width)
	draw_line(right_shoulder, right_elbow, draw_color, line_width)
	draw_line(right_elbow, right_hand, draw_color, line_width)

	# Draw boxing gloves (hands)
	var glove_draw_color = glove_color if not is_flashing else Color.WHITE
	draw_circle(left_hand, 3.5, glove_draw_color)
	draw_circle(right_hand, 3.5, glove_draw_color)

	# Draw joints
	_draw_joint(left_elbow, draw_color)
	_draw_joint(right_elbow, draw_color)
	_draw_joint(left_knee, draw_color)
	_draw_joint(right_knee, draw_color)
	_draw_joint(left_shoulder, draw_color)
	_draw_joint(right_shoulder, draw_color)


func _draw_with_appearance() -> void:
	var skin_color = appearance.skin_color if not is_flashing else Color.WHITE
	var hair_col = appearance.hair_color if not is_flashing else Color.WHITE
	var top_col = appearance.top_color if not is_flashing else Color.WHITE
	var bottom_col = appearance.bottom_color if not is_flashing else Color.WHITE
	var glove_col = appearance.glove_color if not is_flashing else Color.WHITE
	var acc_col = appearance.accessory_color if not is_flashing else Color.WHITE

	# Get build multiplier
	var build_mult = _get_build_multiplier()

	# Draw shadow
	var shadow_offset = Vector2(2, 2)
	var shadow_color = Color(0, 0, 0, 0.3)
	draw_line(neck_pos + shadow_offset, hip_pos + shadow_offset, shadow_color, line_width * build_mult)

	# ===== Draw legs with pants =====
	_draw_legs(skin_color, bottom_col, build_mult)

	# ===== Draw torso with clothing =====
	_draw_torso(skin_color, top_col, build_mult)

	# ===== Draw head and face =====
	_draw_head(skin_color, build_mult)

	# ===== Draw hair =====
	_draw_hair(hair_col)

	# ===== Draw accessory =====
	_draw_accessory(acc_col)

	# ===== Draw arms =====
	_draw_arms(skin_color, top_col, glove_col, build_mult)


func _get_build_multiplier() -> float:
	match appearance.build:
		CharacterAppearanceClass.Build.SLIM:
			return 0.8
		CharacterAppearanceClass.Build.NORMAL:
			return 1.0
		CharacterAppearanceClass.Build.MUSCULAR:
			return 1.3
		CharacterAppearanceClass.Build.HEAVY:
			return 1.5
	return 1.0


func _draw_legs(skin_color: Color, pants_color: Color, build_mult: float) -> void:
	var leg_width = line_width * build_mult * 1.2

	# Draw pants/shorts based on style
	match appearance.bottom_style:
		CharacterAppearanceClass.BottomStyle.SHORTS, CharacterAppearanceClass.BottomStyle.TRUNKS:
			# Shorts - pants to knee, skin below
			draw_line(left_hip, left_knee, pants_color, leg_width + 2)
			draw_line(right_hip, right_knee, pants_color, leg_width + 2)
			draw_line(left_knee, left_foot, skin_color, leg_width)
			draw_line(right_knee, right_foot, skin_color, leg_width)
		CharacterAppearanceClass.BottomStyle.PANTS, CharacterAppearanceClass.BottomStyle.GI_PANTS, CharacterAppearanceClass.BottomStyle.BAGGY:
			# Full pants
			var pant_width = leg_width + 2
			if appearance.bottom_style == CharacterAppearanceClass.BottomStyle.BAGGY:
				pant_width = leg_width + 4
			draw_line(left_hip, left_knee, pants_color, pant_width)
			draw_line(left_knee, left_foot, pants_color, pant_width)
			draw_line(right_hip, right_knee, pants_color, pant_width)
			draw_line(right_knee, right_foot, pants_color, pant_width)

	# Draw feet/shoes
	draw_circle(left_foot, 2.5 * build_mult, pants_color.darkened(0.3))
	draw_circle(right_foot, 2.5 * build_mult, pants_color.darkened(0.3))

	# Draw knee joints
	_draw_joint(left_knee, skin_color if appearance.bottom_style in [CharacterAppearanceClass.BottomStyle.SHORTS, CharacterAppearanceClass.BottomStyle.TRUNKS] else pants_color)
	_draw_joint(right_knee, skin_color if appearance.bottom_style in [CharacterAppearanceClass.BottomStyle.SHORTS, CharacterAppearanceClass.BottomStyle.TRUNKS] else pants_color)


func _draw_torso(skin_color: Color, top_color: Color, build_mult: float) -> void:
	var torso_width = (line_width + 2) * build_mult

	match appearance.top_style:
		CharacterAppearanceClass.TopStyle.NONE:
			# Shirtless - draw skin colored torso
			draw_line(neck_pos, hip_pos, skin_color, torso_width)
			# Add simple muscle definition for muscular builds
			if appearance.build == CharacterAppearanceClass.Build.MUSCULAR:
				var chest_pos = neck_pos.lerp(hip_pos, 0.3)
				draw_circle(chest_pos + Vector2(-2, 0), 2, skin_color.darkened(0.1))
				draw_circle(chest_pos + Vector2(2, 0), 2, skin_color.darkened(0.1))

		CharacterAppearanceClass.TopStyle.TANK_TOP:
			# Tank top - narrow straps
			draw_line(neck_pos, hip_pos, top_color, torso_width)
			# Exposed shoulders
			draw_circle(left_shoulder, 2 * build_mult, skin_color)
			draw_circle(right_shoulder, 2 * build_mult, skin_color)

		CharacterAppearanceClass.TopStyle.T_SHIRT, CharacterAppearanceClass.TopStyle.GI_TOP:
			# T-shirt or gi - full coverage
			draw_line(neck_pos, hip_pos, top_color, torso_width + 1)
			# Collar
			draw_arc(neck_pos, 3, PI * 0.7, PI * 0.3, 8, top_color.darkened(0.2), 1)

		CharacterAppearanceClass.TopStyle.HOODIE:
			# Hoodie - bulkier
			draw_line(neck_pos, hip_pos, top_color, torso_width + 3)
			# Hood behind head
			draw_arc(neck_pos + Vector2(0, -3), 6, PI * 0.6, PI * 0.4, 8, top_color.darkened(0.1), 3)

		CharacterAppearanceClass.TopStyle.JACKET:
			# Open jacket - shows skin/undershirt
			draw_line(neck_pos, hip_pos, skin_color.darkened(0.1), torso_width)
			# Jacket sides
			draw_line(neck_pos + Vector2(-3, 0), hip_pos + Vector2(-4, 0), top_color, 2)
			draw_line(neck_pos + Vector2(3, 0), hip_pos + Vector2(4, 0), top_color, 2)

		CharacterAppearanceClass.TopStyle.VEST:
			# Vest - no sleeves
			draw_line(neck_pos, hip_pos, top_color, torso_width)


func _draw_head(skin_color: Color, build_mult: float) -> void:
	var head_radius = HEAD_RADIUS * build_mult

	# Draw head
	draw_circle(head_pos, head_radius, skin_color)
	draw_arc(head_pos, head_radius, 0, TAU, 16, skin_color.darkened(0.2), line_width)

	# Simple face - eyes and mouth
	var eye_offset = head_radius * 0.4
	var eye_y = head_pos.y - head_radius * 0.1
	# Eyes (small dots)
	draw_circle(Vector2(head_pos.x - eye_offset, eye_y), 1, Color.BLACK)
	draw_circle(Vector2(head_pos.x + eye_offset, eye_y), 1, Color.BLACK)
	# Mouth (small line)
	var mouth_y = head_pos.y + head_radius * 0.4
	draw_line(Vector2(head_pos.x - 2, mouth_y), Vector2(head_pos.x + 2, mouth_y), skin_color.darkened(0.3), 1)


func _draw_hair(hair_color: Color) -> void:
	var hr = HEAD_RADIUS

	match appearance.hair_style:
		CharacterAppearanceClass.HairStyle.BALD:
			# No hair - maybe slight shine
			draw_arc(head_pos + Vector2(-2, -hr * 0.5), 2, 0, PI, 6, Color.WHITE.lerp(appearance.skin_color, 0.7), 1)

		CharacterAppearanceClass.HairStyle.SHORT:
			# Short cropped hair - cap shape
			draw_arc(head_pos, hr + 1, PI * 0.8, PI * 0.2, 12, hair_color, 3)

		CharacterAppearanceClass.HairStyle.SPIKY:
			# Anime spiky hair
			var base_y = head_pos.y - hr * 0.5
			for i in range(5):
				var spike_x = head_pos.x + (i - 2) * 3
				var spike_height = 6 + (2 - abs(i - 2)) * 2
				var points = PackedVector2Array([
					Vector2(spike_x - 2, base_y),
					Vector2(spike_x, base_y - spike_height),
					Vector2(spike_x + 2, base_y)
				])
				draw_colored_polygon(points, hair_color)

		CharacterAppearanceClass.HairStyle.MOHAWK:
			# Punk mohawk
			var points = PackedVector2Array()
			for i in range(7):
				var t = i / 6.0
				var x = head_pos.x + (t - 0.5) * 8
				var y = head_pos.y - hr - 4 - sin(t * PI) * 6
				points.append(Vector2(x, y))
			# Close the shape
			points.append(Vector2(head_pos.x + 4, head_pos.y - hr + 2))
			points.append(Vector2(head_pos.x - 4, head_pos.y - hr + 2))
			draw_colored_polygon(points, hair_color)

		CharacterAppearanceClass.HairStyle.PONYTAIL:
			# Hair with ponytail
			draw_arc(head_pos, hr + 1, PI * 0.7, PI * 0.3, 12, hair_color, 3)
			# Ponytail behind
			var tail_start = head_pos + Vector2(0, -hr * 0.3)
			var tail_end = tail_start + Vector2(8, 6)
			draw_line(tail_start, tail_end, hair_color, 3)
			draw_circle(tail_end, 2, hair_color)

		CharacterAppearanceClass.HairStyle.LONG:
			# Long flowing hair
			draw_arc(head_pos, hr + 1, PI * 0.8, PI * 0.2, 12, hair_color, 3)
			# Hair strands down sides
			draw_line(head_pos + Vector2(-hr, 0), head_pos + Vector2(-hr - 2, 12), hair_color, 3)
			draw_line(head_pos + Vector2(hr, 0), head_pos + Vector2(hr + 2, 12), hair_color, 3)
			draw_line(head_pos + Vector2(-hr + 2, 2), head_pos + Vector2(-hr, 10), hair_color, 2)
			draw_line(head_pos + Vector2(hr - 2, 2), head_pos + Vector2(hr, 10), hair_color, 2)

		CharacterAppearanceClass.HairStyle.AFRO:
			# Big afro
			draw_circle(head_pos + Vector2(0, -3), hr + 5, hair_color)
			draw_arc(head_pos + Vector2(0, -3), hr + 5, 0, TAU, 20, hair_color.darkened(0.1), 2)

		CharacterAppearanceClass.HairStyle.BRAIDS:
			# Braided hair
			draw_arc(head_pos, hr + 1, PI * 0.7, PI * 0.3, 12, hair_color, 3)
			# Multiple braids
			for i in range(3):
				var braid_x = head_pos.x + (i - 1) * 5
				var braid_start = head_pos + Vector2((i - 1) * 4, hr * 0.3)
				for j in range(4):
					var by = braid_start.y + j * 3
					draw_circle(Vector2(braid_x, by), 1.5, hair_color)

		CharacterAppearanceClass.HairStyle.SLICKED:
			# Slicked back hair
			var points = PackedVector2Array([
				head_pos + Vector2(-hr - 1, -2),
				head_pos + Vector2(-hr * 0.5, -hr - 2),
				head_pos + Vector2(0, -hr - 3),
				head_pos + Vector2(hr * 0.5, -hr - 2),
				head_pos + Vector2(hr + 1, -2),
				head_pos + Vector2(hr + 3, 4),
				head_pos + Vector2(-hr - 3, 4),
			])
			draw_colored_polygon(points, hair_color)

		CharacterAppearanceClass.HairStyle.MESSY:
			# Messy/wild hair
			draw_arc(head_pos, hr + 2, PI * 0.9, PI * 0.1, 12, hair_color, 4)
			# Random tufts
			for i in range(6):
				var angle = PI * 0.2 + i * PI * 0.13
				var tuft_start = head_pos + Vector2(cos(angle), -sin(angle)) * hr
				var tuft_end = tuft_start + Vector2(cos(angle + randf_range(-0.3, 0.3)), -sin(angle)) * (4 + randi() % 4)
				draw_line(tuft_start, tuft_end, hair_color, 2)


func _draw_accessory(acc_color: Color) -> void:
	var hr = HEAD_RADIUS

	match appearance.accessory:
		CharacterAppearanceClass.Accessory.NONE:
			pass

		CharacterAppearanceClass.Accessory.HEADBAND:
			# Fighting headband
			draw_arc(head_pos, hr + 0.5, PI * 0.85, PI * 0.15, 12, acc_color, 3)
			# Trailing ends
			draw_line(head_pos + Vector2(hr + 1, -2), head_pos + Vector2(hr + 8, 2), acc_color, 2)
			draw_line(head_pos + Vector2(hr + 1, -1), head_pos + Vector2(hr + 6, 4), acc_color, 2)

		CharacterAppearanceClass.Accessory.BANDANA:
			# Wrapped bandana covering top of head
			var points = PackedVector2Array([
				head_pos + Vector2(-hr - 1, 0),
				head_pos + Vector2(-hr, -hr * 0.7),
				head_pos + Vector2(0, -hr - 1),
				head_pos + Vector2(hr, -hr * 0.7),
				head_pos + Vector2(hr + 1, 0),
			])
			draw_polyline(points, acc_color, 3)
			# Knot at back
			draw_circle(head_pos + Vector2(hr + 2, 0), 2, acc_color)

		CharacterAppearanceClass.Accessory.CAP:
			# Baseball cap
			var cap_points = PackedVector2Array([
				head_pos + Vector2(-hr - 1, -hr * 0.3),
				head_pos + Vector2(-hr, -hr - 1),
				head_pos + Vector2(0, -hr - 2),
				head_pos + Vector2(hr, -hr - 1),
				head_pos + Vector2(hr + 1, -hr * 0.3),
			])
			draw_polyline(cap_points, acc_color, 4)
			# Bill
			draw_line(head_pos + Vector2(-hr, -hr * 0.3), head_pos + Vector2(-hr - 6, -hr * 0.1), acc_color, 3)

		CharacterAppearanceClass.Accessory.MASK:
			# Face mask (lower face)
			draw_arc(head_pos + Vector2(0, hr * 0.3), hr * 0.8, PI * 0.2, PI * 0.8, 8, acc_color, 3)

		CharacterAppearanceClass.Accessory.GLASSES:
			# Sunglasses
			var eye_y = head_pos.y - hr * 0.1
			draw_rect(Rect2(head_pos.x - hr * 0.7, eye_y - 2, 4, 4), acc_color)
			draw_rect(Rect2(head_pos.x + hr * 0.3, eye_y - 2, 4, 4), acc_color)
			draw_line(Vector2(head_pos.x - hr * 0.3, eye_y), Vector2(head_pos.x + hr * 0.3, eye_y), acc_color, 1)

		CharacterAppearanceClass.Accessory.SCAR:
			# Face scar
			draw_line(head_pos + Vector2(-3, -2), head_pos + Vector2(2, 4), Color(0.6, 0.3, 0.3), 1.5)


func _draw_arms(skin_color: Color, top_color: Color, glove_col: Color, build_mult: float) -> void:
	var arm_width = line_width * build_mult

	# Determine arm coverage based on top style
	var upper_arm_color = skin_color
	if appearance.top_style in [CharacterAppearanceClass.TopStyle.T_SHIRT, CharacterAppearanceClass.TopStyle.HOODIE, CharacterAppearanceClass.TopStyle.GI_TOP, CharacterAppearanceClass.TopStyle.JACKET]:
		upper_arm_color = top_color

	# Left arm
	draw_line(left_shoulder, left_elbow, upper_arm_color, arm_width + 1)
	draw_line(left_elbow, left_hand, skin_color, arm_width)

	# Right arm
	draw_line(right_shoulder, right_elbow, upper_arm_color, arm_width + 1)
	draw_line(right_elbow, right_hand, skin_color, arm_width)

	# Gloves
	draw_circle(left_hand, 3.5 * build_mult, glove_col)
	draw_circle(right_hand, 3.5 * build_mult, glove_col)

	# Elbow joints
	_draw_joint(left_elbow, skin_color)
	_draw_joint(right_elbow, skin_color)

	# Shoulder joints
	_draw_joint(left_shoulder, upper_arm_color)
	_draw_joint(right_shoulder, upper_arm_color)


func _draw_joint(pos: Vector2, color: Color = Color.WHITE) -> void:
	draw_circle(pos, 1.5, color)


func flash() -> void:
	is_flashing = true
	flash_timer = 0.1


func _update_flash(delta: float) -> void:
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			is_flashing = false


func _lerp_to_pose(delta: float) -> void:
	var t = pose_lerp_speed * delta

	if target_pose.has("torso"):
		torso_angle = lerp(torso_angle, target_pose.torso, t)
	if target_pose.has("left_upper_arm"):
		left_upper_arm_angle = lerp(left_upper_arm_angle, target_pose.left_upper_arm, t)
	if target_pose.has("left_lower_arm"):
		left_lower_arm_angle = lerp(left_lower_arm_angle, target_pose.left_lower_arm, t)
	if target_pose.has("right_upper_arm"):
		right_upper_arm_angle = lerp(right_upper_arm_angle, target_pose.right_upper_arm, t)
	if target_pose.has("right_lower_arm"):
		right_lower_arm_angle = lerp(right_lower_arm_angle, target_pose.right_lower_arm, t)
	if target_pose.has("left_upper_leg"):
		left_upper_leg_angle = lerp(left_upper_leg_angle, target_pose.left_upper_leg, t)
	if target_pose.has("left_lower_leg"):
		left_lower_leg_angle = lerp(left_lower_leg_angle, target_pose.left_lower_leg, t)
	if target_pose.has("right_upper_leg"):
		right_upper_leg_angle = lerp(right_upper_leg_angle, target_pose.right_upper_leg, t)
	if target_pose.has("right_lower_leg"):
		right_lower_leg_angle = lerp(right_lower_leg_angle, target_pose.right_lower_leg, t)


func set_pose(pose: Pose, immediate: bool = false) -> void:
	target_pose = _get_pose_data(pose)

	if immediate:
		torso_angle = target_pose.get("torso", 0.0)
		left_upper_arm_angle = target_pose.get("left_upper_arm", 0.0)
		left_lower_arm_angle = target_pose.get("left_lower_arm", 0.0)
		right_upper_arm_angle = target_pose.get("right_upper_arm", 0.0)
		right_lower_arm_angle = target_pose.get("right_lower_arm", 0.0)
		left_upper_leg_angle = target_pose.get("left_upper_leg", 0.0)
		left_lower_leg_angle = target_pose.get("left_lower_leg", 0.0)
		right_upper_leg_angle = target_pose.get("right_upper_leg", 0.0)
		right_lower_leg_angle = target_pose.get("right_lower_leg", 0.0)


func _get_pose_data(pose: Pose) -> Dictionary:
	match pose:
		Pose.IDLE:
			return {
				"torso": 0.0,
				"left_upper_arm": 0.3,
				"left_lower_arm": 0.2,
				"right_upper_arm": -0.3,
				"right_lower_arm": -0.2,
				"left_upper_leg": 0.05,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.05,
				"right_lower_leg": 0.0
			}
		Pose.WALK_1:
			return {
				"torso": 0.1,
				"left_upper_arm": 0.6,
				"left_lower_arm": 0.3,
				"right_upper_arm": -0.6,
				"right_lower_arm": -0.3,
				"left_upper_leg": -0.4,
				"left_lower_leg": 0.3,
				"right_upper_leg": 0.4,
				"right_lower_leg": 0.0
			}
		Pose.WALK_2:
			return {
				"torso": 0.1,
				"left_upper_arm": -0.6,
				"left_lower_arm": -0.3,
				"right_upper_arm": 0.6,
				"right_lower_arm": 0.3,
				"left_upper_leg": 0.4,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.4,
				"right_lower_leg": 0.3
			}
		Pose.JAB:
			return {
				"torso": 0.2,
				"left_upper_arm": 0.2,
				"left_lower_arm": 0.3,
				"right_upper_arm": -1.5,  # Punch forward
				"right_lower_arm": 0.0,
				"left_upper_leg": 0.2,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.1,
				"right_lower_leg": 0.0
			}
		Pose.STRAIGHT:
			return {
				"torso": 0.3,
				"left_upper_arm": 0.4,
				"left_lower_arm": 0.5,
				"right_upper_arm": -1.6,  # Strong punch
				"right_lower_arm": 0.0,
				"left_upper_leg": 0.3,
				"left_lower_leg": 0.1,
				"right_upper_leg": -0.2,
				"right_lower_leg": 0.0
			}
		Pose.HOOK:
			return {
				"torso": 0.4,
				"left_upper_arm": 0.5,
				"left_lower_arm": 0.4,
				"right_upper_arm": -1.2,  # Hook angle
				"right_lower_arm": -1.0,  # Bent arm
				"left_upper_leg": 0.3,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.1,
				"right_lower_leg": 0.0
			}
		Pose.UPPERCUT:
			return {
				"torso": -0.2,  # Lean back slightly
				"left_upper_arm": 0.4,
				"left_lower_arm": 0.3,
				"right_upper_arm": -0.5,  # Arm coming up
				"right_lower_arm": -1.5,  # Bent for uppercut
				"left_upper_leg": 0.3,
				"left_lower_leg": 0.2,
				"right_upper_leg": -0.3,
				"right_lower_leg": 0.0
			}
		Pose.DEFEND:
			return {
				"torso": -0.1,
				"left_upper_arm": -0.8,  # Arms up
				"left_lower_arm": -1.2,
				"right_upper_arm": 0.8,
				"right_lower_arm": 1.2,
				"left_upper_leg": 0.1,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.1,
				"right_lower_leg": 0.0
			}
		Pose.EVADE:
			return {
				"torso": -0.4,  # Lean back
				"left_upper_arm": 0.5,
				"left_lower_arm": 0.3,
				"right_upper_arm": -0.5,
				"right_lower_arm": -0.3,
				"left_upper_leg": -0.3,
				"left_lower_leg": 0.5,
				"right_upper_leg": 0.2,
				"right_lower_leg": 0.0
			}
		Pose.HIT:
			return {
				"torso": -0.3,  # Stagger back
				"left_upper_arm": 0.8,
				"left_lower_arm": 0.5,
				"right_upper_arm": -0.8,
				"right_lower_arm": -0.5,
				"left_upper_leg": 0.0,
				"left_lower_leg": 0.2,
				"right_upper_leg": -0.3,
				"right_lower_leg": 0.3
			}
		Pose.RECOVERY:
			return {
				"torso": 0.0,
				"left_upper_arm": 0.4,
				"left_lower_arm": 0.3,
				"right_upper_arm": -0.4,
				"right_lower_arm": -0.3,
				"left_upper_leg": 0.1,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.1,
				"right_lower_leg": 0.0
			}
		Pose.FRONT_KICK:
			return {
				"torso": -0.1,
				"left_upper_arm": 0.4,
				"left_lower_arm": 0.3,
				"right_upper_arm": -0.4,
				"right_lower_arm": -0.3,
				"left_upper_leg": 0.2,
				"left_lower_leg": 0.1,
				"right_upper_leg": -1.4,  # Kick forward
				"right_lower_leg": 0.2
			}
		Pose.LOW_KICK:
			return {
				"torso": 0.2,
				"left_upper_arm": 0.5,
				"left_lower_arm": 0.3,
				"right_upper_arm": -0.5,
				"right_lower_arm": -0.3,
				"left_upper_leg": 0.1,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.8,  # Low kick angle
				"right_lower_leg": -0.3
			}
		Pose.ROUNDHOUSE:
			return {
				"torso": 0.4,
				"left_upper_arm": 0.6,
				"left_lower_arm": 0.4,
				"right_upper_arm": -0.6,
				"right_lower_arm": -0.4,
				"left_upper_leg": 0.3,
				"left_lower_leg": 0.2,
				"right_upper_leg": -1.2,  # High roundhouse
				"right_lower_leg": -0.8
			}
		Pose.KNEE_STRIKE:
			return {
				"torso": 0.1,
				"left_upper_arm": 0.3,
				"left_lower_arm": 0.2,
				"right_upper_arm": -0.3,
				"right_lower_arm": -0.2,
				"left_upper_leg": 0.1,
				"left_lower_leg": 0.0,
				"right_upper_leg": -1.0,  # Knee up
				"right_lower_leg": -1.5   # Folded leg
			}
		Pose.ELBOW:
			return {
				"torso": 0.3,
				"left_upper_arm": 0.4,
				"left_lower_arm": 0.3,
				"right_upper_arm": -0.8,  # Elbow angle
				"right_lower_arm": -1.8,  # Tight fold
				"left_upper_leg": 0.2,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.1,
				"right_lower_leg": 0.0
			}
		Pose.BACKFIST:
			return {
				"torso": -0.3,  # Twist back
				"left_upper_arm": 0.8,
				"left_lower_arm": 0.5,
				"right_upper_arm": 1.2,   # Backswing
				"right_lower_arm": 0.8,
				"left_upper_leg": 0.2,
				"left_lower_leg": 0.0,
				"right_upper_leg": -0.2,
				"right_lower_leg": 0.0
			}
		_:
			return {}


# Get pose for a specific move name
func get_pose_for_move(move_name: String) -> Pose:
	match move_name:
		"Jab":
			return Pose.JAB
		"Straight":
			return Pose.STRAIGHT
		"Hook":
			return Pose.HOOK
		"Uppercut":
			return Pose.UPPERCUT
		"Body Blow":
			return Pose.STRAIGHT
		"Low Kick":
			return Pose.LOW_KICK
		"Front Kick":
			return Pose.FRONT_KICK
		"Roundhouse":
			return Pose.ROUNDHOUSE
		"Knee Strike":
			return Pose.KNEE_STRIKE
		"Elbow":
			return Pose.ELBOW
		"Backfist":
			return Pose.BACKFIST
		"Flurry":
			return Pose.JAB
		"Counter":
			return Pose.STRAIGHT
		"Haymaker":
			return Pose.HOOK
		"Dempsey Roll":
			return Pose.HOOK
		"Gazelle Punch":
			return Pose.UPPERCUT
		_:
			return Pose.JAB  # Default attack pose
