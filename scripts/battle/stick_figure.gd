extends Node2D
class_name StickFigure
## StickFigure - MUGEN-style character rendering with polygon bodies
## Features: Filled polygons, thick outlines, motion effects, expressions

const CharacterAppearanceClass = preload("res://scripts/battle/character_appearance.gd")
const VerletPhysicsClass = preload("res://scripts/battle/verlet_physics.gd")

# Body part colors (can be overridden by appearance)
@export var body_color: Color = Color.WHITE
@export var head_color: Color = Color.WHITE
@export var glove_color: Color = Color.RED
@export var line_width: float = 2.0

# MUGEN-style rendering settings
@export var outline_color: Color = Color(0.1, 0.1, 0.15)  # Dark outline
@export var outline_width: float = 2.0  # Thick outlines for MUGEN look
@export var enable_shading: bool = true  # Simple 2-tone shading
@export var enable_motion_effects: bool = true  # Speed lines and afterimages

# Character appearance (optional - if null, uses simple stick figure)
var appearance: Resource = null  # CharacterAppearance

# Flash effect
var flash_timer: float = 0.0
var is_flashing: bool = false

# Motion effects
var afterimage_positions: Array = []  # Store last N positions for afterimages
var afterimage_poses: Array = []  # Store poses for afterimages
var max_afterimages: int = 4
var afterimage_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var speed_line_intensity: float = 0.0

# Expression system
enum Expression { NEUTRAL, FOCUSED, ANGRY, HURT, VICTORIOUS, EXHAUSTED }
var current_expression: Expression = Expression.NEUTRAL
var expression_timer: float = 0.0

# ===== Physics Systems =====
var hair_chains: Array = []  # Array of HairChain for dynamic hair
var cloth_mesh = null  # ClothMesh for loose clothing
var ragdoll: VerletPhysicsClass.RagdollBody = null
var is_ragdoll_active: bool = false
var last_velocity: Vector2 = Vector2.ZERO
var physics_initialized: bool = false

# Body proportions (relative to scale) - MUGEN-style slightly exaggerated
const HEAD_RADIUS = 6.0
const TORSO_LENGTH = 14.0
const UPPER_ARM_LENGTH = 8.0
const LOWER_ARM_LENGTH = 8.0
const UPPER_LEG_LENGTH = 9.0
const LOWER_LEG_LENGTH = 9.0

# Polygon body widths (for filled shapes)
const TORSO_WIDTH_TOP = 8.0  # Shoulder width
const TORSO_WIDTH_BOT = 5.0  # Hip width
const ARM_WIDTH_UPPER = 3.5
const ARM_WIDTH_LOWER = 3.0
const ARM_WIDTH_HAND = 2.0
const LEG_WIDTH_UPPER = 4.0
const LEG_WIDTH_LOWER = 3.5
const LEG_WIDTH_FOOT = 2.5

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

# Pose data constants (DRY: extracted from _get_pose_data)
const POSE_DATA = {
	Pose.IDLE: {"torso": 0.0, "left_upper_arm": 0.3, "left_lower_arm": 0.2, "right_upper_arm": -0.3, "right_lower_arm": -0.2, "left_upper_leg": 0.05, "left_lower_leg": 0.0, "right_upper_leg": -0.05, "right_lower_leg": 0.0},
	Pose.WALK_1: {"torso": 0.1, "left_upper_arm": 0.6, "left_lower_arm": 0.3, "right_upper_arm": -0.6, "right_lower_arm": -0.3, "left_upper_leg": -0.4, "left_lower_leg": 0.3, "right_upper_leg": 0.4, "right_lower_leg": 0.0},
	Pose.WALK_2: {"torso": 0.1, "left_upper_arm": -0.6, "left_lower_arm": -0.3, "right_upper_arm": 0.6, "right_lower_arm": 0.3, "left_upper_leg": 0.4, "left_lower_leg": 0.0, "right_upper_leg": -0.4, "right_lower_leg": 0.3},
	Pose.JAB: {"torso": 0.2, "left_upper_arm": 0.2, "left_lower_arm": 0.3, "right_upper_arm": -1.5, "right_lower_arm": 0.0, "left_upper_leg": 0.2, "left_lower_leg": 0.0, "right_upper_leg": -0.1, "right_lower_leg": 0.0},
	Pose.STRAIGHT: {"torso": 0.3, "left_upper_arm": 0.4, "left_lower_arm": 0.5, "right_upper_arm": -1.6, "right_lower_arm": 0.0, "left_upper_leg": 0.3, "left_lower_leg": 0.1, "right_upper_leg": -0.2, "right_lower_leg": 0.0},
	Pose.HOOK: {"torso": 0.4, "left_upper_arm": 0.5, "left_lower_arm": 0.4, "right_upper_arm": -1.2, "right_lower_arm": -1.0, "left_upper_leg": 0.3, "left_lower_leg": 0.0, "right_upper_leg": -0.1, "right_lower_leg": 0.0},
	Pose.UPPERCUT: {"torso": -0.2, "left_upper_arm": 0.4, "left_lower_arm": 0.3, "right_upper_arm": -0.5, "right_lower_arm": -1.5, "left_upper_leg": 0.3, "left_lower_leg": 0.2, "right_upper_leg": -0.3, "right_lower_leg": 0.0},
	Pose.DEFEND: {"torso": -0.1, "left_upper_arm": -0.8, "left_lower_arm": -1.2, "right_upper_arm": 0.8, "right_lower_arm": 1.2, "left_upper_leg": 0.1, "left_lower_leg": 0.0, "right_upper_leg": -0.1, "right_lower_leg": 0.0},
	Pose.EVADE: {"torso": -0.4, "left_upper_arm": 0.5, "left_lower_arm": 0.3, "right_upper_arm": -0.5, "right_lower_arm": -0.3, "left_upper_leg": -0.3, "left_lower_leg": 0.5, "right_upper_leg": 0.2, "right_lower_leg": 0.0},
	Pose.HIT: {"torso": -0.3, "left_upper_arm": 0.8, "left_lower_arm": 0.5, "right_upper_arm": -0.8, "right_lower_arm": -0.5, "left_upper_leg": 0.0, "left_lower_leg": 0.2, "right_upper_leg": -0.3, "right_lower_leg": 0.3},
	Pose.RECOVERY: {"torso": 0.0, "left_upper_arm": 0.4, "left_lower_arm": 0.3, "right_upper_arm": -0.4, "right_lower_arm": -0.3, "left_upper_leg": 0.1, "left_lower_leg": 0.0, "right_upper_leg": -0.1, "right_lower_leg": 0.0},
	Pose.FRONT_KICK: {"torso": -0.1, "left_upper_arm": 0.4, "left_lower_arm": 0.3, "right_upper_arm": -0.4, "right_lower_arm": -0.3, "left_upper_leg": 0.2, "left_lower_leg": 0.1, "right_upper_leg": -1.4, "right_lower_leg": 0.2},
	Pose.LOW_KICK: {"torso": 0.2, "left_upper_arm": 0.5, "left_lower_arm": 0.3, "right_upper_arm": -0.5, "right_lower_arm": -0.3, "left_upper_leg": 0.1, "left_lower_leg": 0.0, "right_upper_leg": -0.8, "right_lower_leg": -0.3},
	Pose.ROUNDHOUSE: {"torso": 0.4, "left_upper_arm": 0.6, "left_lower_arm": 0.4, "right_upper_arm": -0.6, "right_lower_arm": -0.4, "left_upper_leg": 0.3, "left_lower_leg": 0.2, "right_upper_leg": -1.2, "right_lower_leg": -0.8},
	Pose.KNEE_STRIKE: {"torso": 0.1, "left_upper_arm": 0.3, "left_lower_arm": 0.2, "right_upper_arm": -0.3, "right_lower_arm": -0.2, "left_upper_leg": 0.1, "left_lower_leg": 0.0, "right_upper_leg": -1.0, "right_lower_leg": -1.5},
	Pose.ELBOW: {"torso": 0.3, "left_upper_arm": 0.4, "left_lower_arm": 0.3, "right_upper_arm": -0.8, "right_lower_arm": -1.8, "left_upper_leg": 0.2, "left_lower_leg": 0.0, "right_upper_leg": -0.1, "right_lower_leg": 0.0},
	Pose.BACKFIST: {"torso": -0.3, "left_upper_arm": 0.8, "left_lower_arm": 0.5, "right_upper_arm": 1.2, "right_lower_arm": 0.8, "left_upper_leg": 0.2, "left_lower_leg": 0.0, "right_upper_leg": -0.2, "right_lower_leg": 0.0}
}

# Move name to pose mapping (DRY: extracted from get_pose_for_move)
const MOVE_POSE_MAP = {
	"Jab": Pose.JAB, "Straight": Pose.STRAIGHT, "Hook": Pose.HOOK, "Uppercut": Pose.UPPERCUT,
	"Body Blow": Pose.STRAIGHT, "Low Kick": Pose.LOW_KICK, "Front Kick": Pose.FRONT_KICK,
	"Roundhouse": Pose.ROUNDHOUSE, "Knee Strike": Pose.KNEE_STRIKE, "Elbow": Pose.ELBOW,
	"Backfist": Pose.BACKFIST, "Flurry": Pose.JAB, "Counter": Pose.STRAIGHT,
	"Haymaker": Pose.HOOK, "Dempsey Roll": Pose.HOOK, "Gazelle Punch": Pose.UPPERCUT
}


func _ready() -> void:
	set_pose(Pose.IDLE)


func set_appearance(new_appearance: Resource) -> void:
	appearance = new_appearance
	if appearance:
		glove_color = appearance.glove_color
		body_color = appearance.skin_color
		head_color = appearance.skin_color
		# Initialize physics after appearance is set
		call_deferred("_initialize_physics")
	queue_redraw()


func _initialize_physics() -> void:
	if physics_initialized:
		return
	physics_initialized = true

	# Calculate skeleton first
	_calculate_skeleton()

	# Initialize hair physics based on hair style
	_setup_hair_physics()

	# Initialize cloth physics for loose clothing
	_setup_cloth_physics()

	# Initialize ragdoll (inactive by default)
	_setup_ragdoll()


func _setup_hair_physics() -> void:
	hair_chains.clear()

	if not appearance:
		return

	var hr = HEAD_RADIUS

	match appearance.hair_style:
		CharacterAppearanceClass.HairStyle.PONYTAIL:
			# Single ponytail chain
			var start = head_pos + Vector2(0, -hr * 0.3)
			var chain = VerletPhysicsClass.HairChain.new(start, 5, 3.0)
			chain.gravity = Vector2(0, 120)
			hair_chains.append(chain)

		CharacterAppearanceClass.HairStyle.LONG:
			# Multiple strands on sides
			for side in [-1, 1]:
				var start = head_pos + Vector2(hr * side, 0)
				var chain = VerletPhysicsClass.HairChain.new(start, 4, 3.0)
				chain.gravity = Vector2(0, 100)
				hair_chains.append(chain)
			# Back hair
			var back_start = head_pos + Vector2(0, hr * 0.5)
			var back_chain = VerletPhysicsClass.HairChain.new(back_start, 5, 2.5)
			back_chain.gravity = Vector2(0, 110)
			hair_chains.append(back_chain)

		CharacterAppearanceClass.HairStyle.BRAIDS:
			# Three braid chains
			for i in range(3):
				var offset_x = (i - 1) * 4
				var start = head_pos + Vector2(offset_x, hr * 0.3)
				var chain = VerletPhysicsClass.HairChain.new(start, 5, 2.5)
				chain.gravity = Vector2(0, 90)
				hair_chains.append(chain)

		CharacterAppearanceClass.HairStyle.MESSY:
			# Multiple wild strands
			for i in range(4):
				var angle = PI * 0.3 + i * PI * 0.15
				var start = head_pos + Vector2(cos(angle) * hr, -sin(angle) * hr)
				var chain = VerletPhysicsClass.HairChain.new(start, 3, 2.0)
				chain.gravity = Vector2(0, 80)
				chain.wind_strength = 30.0
				hair_chains.append(chain)


func _setup_cloth_physics() -> void:
	cloth_mesh = null

	if not appearance:
		return

	# Add cloth for certain clothing types
	match appearance.top_style:
		CharacterAppearanceClass.TopStyle.HOODIE:
			# Hood cloth behind head
			var top_left = neck_pos + Vector2(-6, -8)
			cloth_mesh = VerletPhysicsClass.ClothMesh.new(top_left, 4, 3, 4.0)
			cloth_mesh.gravity = Vector2(0, 60)

		CharacterAppearanceClass.TopStyle.JACKET:
			# Jacket flaps
			var top_left = hip_pos + Vector2(-5, 0)
			cloth_mesh = VerletPhysicsClass.ClothMesh.new(top_left, 3, 3, 3.0)
			cloth_mesh.gravity = Vector2(0, 80)


func _setup_ragdoll() -> void:
	ragdoll = VerletPhysicsClass.RagdollBody.new()


func set_velocity(vel: Vector2) -> void:
	last_velocity = vel
	# Update speed line intensity based on velocity
	speed_line_intensity = clampf(vel.length() / 200.0, 0.0, 1.0)


func set_attacking(attacking: bool, direction: Vector2 = Vector2.RIGHT) -> void:
	is_attacking = attacking
	attack_direction = direction.normalized() if direction.length() > 0 else Vector2.RIGHT


func set_expression(expr: Expression, duration: float = 0.5) -> void:
	current_expression = expr
	expression_timer = duration


# DRY: Helper to get skeleton data as dictionary (used by ragdoll and afterimages)
func _get_skeleton_dict(offset: Vector2 = Vector2.ZERO) -> Dictionary:
	return {
		"head": head_pos + offset, "neck": neck_pos + offset, "hip": hip_pos + offset,
		"left_shoulder": left_shoulder + offset, "right_shoulder": right_shoulder + offset,
		"left_elbow": left_elbow + offset, "right_elbow": right_elbow + offset,
		"left_hand": left_hand + offset, "right_hand": right_hand + offset,
		"left_hip": left_hip + offset, "right_hip": right_hip + offset,
		"left_knee": left_knee + offset, "right_knee": right_knee + offset,
		"left_foot": left_foot + offset, "right_foot": right_foot + offset
	}


func activate_ragdoll(impact_direction: Vector2 = Vector2.ZERO, impact_force: float = 300.0) -> void:
	if is_ragdoll_active:
		return

	# Get current skeleton positions (global space)
	var skeleton_data = _get_skeleton_dict(global_position)

	# Initialize ragdoll at ground level (assume feet are on ground)
	var ground_y = global_position.y + left_foot.y + 5
	ragdoll.initialize_from_skeleton(skeleton_data, ground_y)

	# Apply impact force
	var force = impact_direction.normalized() * impact_force
	force.y -= 100  # Add some upward force
	ragdoll.activate(force)

	is_ragdoll_active = true


func deactivate_ragdoll() -> void:
	is_ragdoll_active = false


func _process(delta: float) -> void:
	# Update flash effect
	_update_flash(delta)

	# Update expression timer
	if expression_timer > 0:
		expression_timer -= delta
		if expression_timer <= 0:
			current_expression = Expression.NEUTRAL

	# If ragdoll is active, use physics-based positions
	if is_ragdoll_active:
		_update_ragdoll(delta)
	else:
		# Interpolate to target pose
		if not target_pose.is_empty():
			_lerp_to_pose(delta)

		# Calculate joint positions
		_calculate_skeleton()

	# Update hair physics
	_update_hair_physics(delta)

	# Update cloth physics
	_update_cloth_physics(delta)

	# Update afterimages for motion effects
	_update_afterimages(delta)

	# Trigger redraw
	queue_redraw()


func _update_afterimages(delta: float) -> void:
	if not enable_motion_effects:
		return

	afterimage_timer += delta

	# Only record afterimages when moving fast or attacking
	var should_record = is_attacking or speed_line_intensity > 0.3

	if should_record and afterimage_timer > 0.03:  # Record every 30ms
		afterimage_timer = 0.0
		# DRY: Use helper function for skeleton data
		afterimage_poses.push_front(_get_skeleton_dict())
		afterimage_positions.push_front(global_position)

		# Limit afterimage count
		while afterimage_poses.size() > max_afterimages:
			afterimage_poses.pop_back()
			afterimage_positions.pop_back()
	elif not should_record and afterimage_poses.size() > 0:
		# Fade out afterimages when not moving fast
		afterimage_poses.pop_back()
		afterimage_positions.pop_back()


func _update_hair_physics(delta: float) -> void:
	if hair_chains.is_empty():
		return

	var hr = HEAD_RADIUS

	for i in range(hair_chains.size()):
		var chain = hair_chains[i]

		# Determine anchor position based on hair style
		var anchor = head_pos

		if appearance:
			match appearance.hair_style:
				CharacterAppearanceClass.HairStyle.PONYTAIL:
					anchor = head_pos + Vector2(0, -hr * 0.3)
				CharacterAppearanceClass.HairStyle.LONG:
					if i < 2:
						var side = -1 if i == 0 else 1
						anchor = head_pos + Vector2(hr * side, 0)
					else:
						anchor = head_pos + Vector2(0, hr * 0.5)
				CharacterAppearanceClass.HairStyle.BRAIDS:
					var offset_x = (i - 1) * 4
					anchor = head_pos + Vector2(offset_x, hr * 0.3)
				CharacterAppearanceClass.HairStyle.MESSY:
					var angle = PI * 0.3 + i * PI * 0.15
					anchor = head_pos + Vector2(cos(angle) * hr, -sin(angle) * hr)

		chain.update(delta, anchor, last_velocity)


func _update_cloth_physics(delta: float) -> void:
	if cloth_mesh == null:
		return

	# Get anchor positions based on clothing type
	var anchors: Array[Vector2] = []

	if appearance:
		match appearance.top_style:
			CharacterAppearanceClass.TopStyle.HOODIE:
				# Hood attached to neck/head area
				anchors.append(neck_pos + Vector2(-6, -8))
				anchors.append(neck_pos + Vector2(-2, -10))
				anchors.append(neck_pos + Vector2(2, -10))
				anchors.append(neck_pos + Vector2(6, -8))
			CharacterAppearanceClass.TopStyle.JACKET:
				# Jacket bottom
				anchors.append(hip_pos + Vector2(-5, 0))
				anchors.append(hip_pos + Vector2(0, 0))
				anchors.append(hip_pos + Vector2(5, 0))

	cloth_mesh.update(delta, anchors, last_velocity)


func _update_ragdoll(delta: float) -> void:
	if ragdoll == null:
		return

	ragdoll.update(delta)

	# Get positions from ragdoll (convert to local space)
	var data = ragdoll.get_skeleton_data()
	head_pos = data.head - global_position
	neck_pos = data.neck - global_position
	hip_pos = data.hip - global_position
	left_shoulder = data.left_shoulder - global_position
	right_shoulder = data.right_shoulder - global_position
	left_elbow = data.left_elbow - global_position
	right_elbow = data.right_elbow - global_position
	left_hand = data.left_hand - global_position
	right_hand = data.right_hand - global_position
	left_hip = data.left_hip - global_position
	right_hip = data.right_hip - global_position
	left_knee = data.left_knee - global_position
	right_knee = data.right_knee - global_position
	left_foot = data.left_foot - global_position
	right_foot = data.right_foot - global_position


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
	# Draw afterimages first (behind main character)
	if enable_motion_effects:
		_draw_afterimages()

	# Draw speed lines when moving fast or attacking
	if enable_motion_effects and (is_attacking or speed_line_intensity > 0.3):
		_draw_speed_lines()

	# Main character rendering
	if appearance:
		_draw_with_appearance()
	else:
		_draw_simple()


func _draw_afterimages() -> void:
	if afterimage_poses.is_empty():
		return

	for i in range(afterimage_poses.size()):
		var alpha = 0.3 * (1.0 - float(i) / float(max_afterimages))
		var offset = afterimage_positions[i] - global_position if i < afterimage_positions.size() else Vector2.ZERO
		var pose = afterimage_poses[i]

		# Draw simplified afterimage silhouette
		var ghost_color = Color(0.5, 0.7, 1.0, alpha)  # Blue-ish ghost

		# Draw body silhouette
		_draw_limb_polygon(pose.neck + offset, pose.hip + offset, TORSO_WIDTH_TOP, TORSO_WIDTH_BOT, ghost_color, Color.TRANSPARENT)
		_draw_limb_polygon(pose.left_shoulder + offset, pose.left_elbow + offset, ARM_WIDTH_UPPER, ARM_WIDTH_LOWER, ghost_color, Color.TRANSPARENT)
		_draw_limb_polygon(pose.right_shoulder + offset, pose.right_elbow + offset, ARM_WIDTH_UPPER, ARM_WIDTH_LOWER, ghost_color, Color.TRANSPARENT)
		_draw_limb_polygon(pose.left_hip + offset, pose.left_knee + offset, LEG_WIDTH_UPPER, LEG_WIDTH_LOWER, ghost_color, Color.TRANSPARENT)
		_draw_limb_polygon(pose.right_hip + offset, pose.right_knee + offset, LEG_WIDTH_UPPER, LEG_WIDTH_LOWER, ghost_color, Color.TRANSPARENT)

		# Head
		draw_circle(pose.head + offset, HEAD_RADIUS * 0.9, ghost_color)


func _draw_speed_lines() -> void:
	var line_count = int(8 * speed_line_intensity) if not is_attacking else 6
	var line_dir = -last_velocity.normalized() if last_velocity.length() > 0 else -attack_direction

	for i in range(line_count):
		var base_offset = Vector2(randf_range(-15, 15), randf_range(-20, 5))
		var start = hip_pos + base_offset
		var line_length = randf_range(15, 35) * speed_line_intensity
		var end = start + line_dir * line_length

		var alpha = randf_range(0.3, 0.7) * speed_line_intensity
		var line_color = Color(1, 1, 1, alpha)
		draw_line(start, end, line_color, randf_range(1.0, 2.5))


func _draw_simple() -> void:
	var draw_color = body_color
	var head_draw_color = head_color
	var shade_color = draw_color.darkened(0.25) if enable_shading else draw_color

	# Flash white when hit
	if is_flashing:
		draw_color = Color.WHITE
		head_draw_color = Color.WHITE
		shade_color = Color(0.9, 0.9, 0.9)

	# Draw shadow (offset slightly)
	var shadow_offset = Vector2(3, 3)
	var shadow_color = Color(0, 0, 0, 0.4)
	_draw_limb_polygon(neck_pos + shadow_offset, hip_pos + shadow_offset, TORSO_WIDTH_TOP, TORSO_WIDTH_BOT, shadow_color, Color.TRANSPARENT)

	# Draw legs (behind body) with polygons
	_draw_limb_polygon(left_hip, left_knee, LEG_WIDTH_UPPER, LEG_WIDTH_LOWER, shade_color, outline_color)
	_draw_limb_polygon(left_knee, left_foot, LEG_WIDTH_LOWER, LEG_WIDTH_FOOT, draw_color, outline_color)
	_draw_limb_polygon(right_hip, right_knee, LEG_WIDTH_UPPER, LEG_WIDTH_LOWER, draw_color, outline_color)
	_draw_limb_polygon(right_knee, right_foot, LEG_WIDTH_LOWER, LEG_WIDTH_FOOT, shade_color, outline_color)

	# Draw feet with outlines
	_draw_circle_with_outline(left_foot, 3.0, draw_color, outline_color)
	_draw_circle_with_outline(right_foot, 3.0, draw_color, outline_color)

	# Draw torso with polygon
	_draw_limb_polygon(neck_pos, hip_pos, TORSO_WIDTH_TOP, TORSO_WIDTH_BOT, draw_color, outline_color)
	# Add shading to one side
	if enable_shading:
		var torso_mid = neck_pos.lerp(hip_pos, 0.5)
		var shade_points = PackedVector2Array([
			neck_pos + Vector2(2, 0),
			neck_pos + Vector2(TORSO_WIDTH_TOP * 0.5, 0),
			hip_pos + Vector2(TORSO_WIDTH_BOT * 0.5, 0),
			hip_pos + Vector2(1, 0)
		])
		draw_colored_polygon(shade_points, shade_color)

	# Draw head with outline
	_draw_circle_with_outline(head_pos, HEAD_RADIUS, head_draw_color, outline_color)

	# Draw simple face
	_draw_face_simple(head_draw_color)

	# Draw arms with polygons
	_draw_limb_polygon(left_shoulder, left_elbow, ARM_WIDTH_UPPER, ARM_WIDTH_LOWER, shade_color, outline_color)
	_draw_limb_polygon(left_elbow, left_hand, ARM_WIDTH_LOWER, ARM_WIDTH_HAND, draw_color, outline_color)
	_draw_limb_polygon(right_shoulder, right_elbow, ARM_WIDTH_UPPER, ARM_WIDTH_LOWER, draw_color, outline_color)
	_draw_limb_polygon(right_elbow, right_hand, ARM_WIDTH_LOWER, ARM_WIDTH_HAND, shade_color, outline_color)

	# Draw boxing gloves with outline
	var glove_draw_color = glove_color if not is_flashing else Color.WHITE
	_draw_glove(left_hand, 4.5, glove_draw_color, left_elbow)
	_draw_glove(right_hand, 4.5, glove_draw_color, right_elbow)

	# Draw joint highlights
	_draw_joint_highlight(left_elbow)
	_draw_joint_highlight(right_elbow)
	_draw_joint_highlight(left_knee)
	_draw_joint_highlight(right_knee)


# Helper: Draw a limb as a filled polygon with tapered width
func _draw_limb_polygon(start: Vector2, end: Vector2, width_start: float, width_end: float, fill_color: Color, stroke_color: Color) -> void:
	var dir = (end - start).normalized()
	var perp = Vector2(-dir.y, dir.x)

	var points = PackedVector2Array([
		start + perp * width_start * 0.5,
		start - perp * width_start * 0.5,
		end - perp * width_end * 0.5,
		end + perp * width_end * 0.5
	])

	# Fill
	draw_colored_polygon(points, fill_color)

	# Outline
	if stroke_color.a > 0:
		points.append(points[0])  # Close the loop
		draw_polyline(points, stroke_color, outline_width)


# Helper: Draw circle with thick outline
func _draw_circle_with_outline(pos: Vector2, radius: float, fill_color: Color, stroke_color: Color) -> void:
	draw_circle(pos, radius, fill_color)
	if stroke_color.a > 0:
		draw_arc(pos, radius, 0, TAU, 24, stroke_color, outline_width)


# Helper: Draw a boxing glove shape
func _draw_glove(pos: Vector2, size: float, color: Color, elbow_pos: Vector2) -> void:
	var dir = (pos - elbow_pos).normalized()
	var perp = Vector2(-dir.y, dir.x)

	# Glove is slightly oval, stretched in direction of punch
	var main_radius = size
	var secondary_radius = size * 0.75

	# Draw glove shape (slightly oval)
	var points = PackedVector2Array()
	for i in range(12):
		var angle = i * TAU / 12.0
		var r = main_radius if abs(cos(angle)) > 0.5 else secondary_radius
		points.append(pos + Vector2(cos(angle) * r, sin(angle) * r * 0.85))

	var shade_color = color.darkened(0.2)
	draw_colored_polygon(points, color)

	# Add highlight
	draw_circle(pos + Vector2(-size * 0.25, -size * 0.25), size * 0.25, color.lightened(0.3))

	# Outline
	points.append(points[0])
	draw_polyline(points, outline_color, outline_width)


# Helper: Draw joint highlight (subtle shine)
func _draw_joint_highlight(pos: Vector2) -> void:
	draw_circle(pos, 1.0, Color(1, 1, 1, 0.3))


# Draw simple face for default character
func _draw_face_simple(skin_color: Color) -> void:
	var eye_offset = HEAD_RADIUS * 0.35
	var eye_y = head_pos.y - HEAD_RADIUS * 0.15

	match current_expression:
		Expression.NEUTRAL, Expression.FOCUSED:
			# Standard eyes
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y), 1.5, Color.WHITE)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y), 1.5, Color.WHITE)
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y), 0.8, Color.BLACK)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y), 0.8, Color.BLACK)
			# Mouth
			var mouth_y = head_pos.y + HEAD_RADIUS * 0.35
			draw_line(Vector2(head_pos.x - 2, mouth_y), Vector2(head_pos.x + 2, mouth_y), skin_color.darkened(0.4), 1.5)

		Expression.ANGRY:
			# Angry eyebrows and eyes
			draw_line(Vector2(head_pos.x - eye_offset - 2, eye_y - 3), Vector2(head_pos.x - eye_offset + 2, eye_y - 1), outline_color, 1.5)
			draw_line(Vector2(head_pos.x + eye_offset + 2, eye_y - 3), Vector2(head_pos.x + eye_offset - 2, eye_y - 1), outline_color, 1.5)
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y), 1.2, Color.WHITE)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y), 1.2, Color.WHITE)
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y), 0.6, Color.BLACK)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y), 0.6, Color.BLACK)
			# Gritting teeth
			var mouth_y = head_pos.y + HEAD_RADIUS * 0.35
			draw_line(Vector2(head_pos.x - 2.5, mouth_y), Vector2(head_pos.x + 2.5, mouth_y), skin_color.darkened(0.5), 2)

		Expression.HURT:
			# Squinting eyes
			draw_line(Vector2(head_pos.x - eye_offset - 2, eye_y), Vector2(head_pos.x - eye_offset + 2, eye_y), outline_color, 2)
			draw_line(Vector2(head_pos.x + eye_offset - 2, eye_y), Vector2(head_pos.x + eye_offset + 2, eye_y), outline_color, 2)
			# Open mouth
			var mouth_y = head_pos.y + HEAD_RADIUS * 0.4
			draw_circle(Vector2(head_pos.x, mouth_y), 2, skin_color.darkened(0.5))

		Expression.VICTORIOUS:
			# Happy closed eyes (^_^)
			draw_arc(Vector2(head_pos.x - eye_offset, eye_y + 1), 2, PI, TAU, 6, outline_color, 1.5)
			draw_arc(Vector2(head_pos.x + eye_offset, eye_y + 1), 2, PI, TAU, 6, outline_color, 1.5)
			# Smile
			var mouth_y = head_pos.y + HEAD_RADIUS * 0.3
			draw_arc(Vector2(head_pos.x, mouth_y), 3, 0.2, PI - 0.2, 8, skin_color.darkened(0.4), 1.5)

		Expression.EXHAUSTED:
			# Tired droopy eyes
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y + 1), 1.2, Color.WHITE)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y + 1), 1.2, Color.WHITE)
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y + 1), 0.5, Color.BLACK)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y + 1), 0.5, Color.BLACK)
			# Half-closed eyelids
			draw_line(Vector2(head_pos.x - eye_offset - 2, eye_y), Vector2(head_pos.x - eye_offset + 2, eye_y + 1), skin_color, 1.5)
			draw_line(Vector2(head_pos.x + eye_offset - 2, eye_y), Vector2(head_pos.x + eye_offset + 2, eye_y + 1), skin_color, 1.5)
			# Wavy mouth
			var mouth_y = head_pos.y + HEAD_RADIUS * 0.4
			draw_line(Vector2(head_pos.x - 2, mouth_y), Vector2(head_pos.x, mouth_y - 1), skin_color.darkened(0.4), 1)
			draw_line(Vector2(head_pos.x, mouth_y - 1), Vector2(head_pos.x + 2, mouth_y), skin_color.darkened(0.4), 1)


func _draw_with_appearance() -> void:
	var skin_color = appearance.skin_color if not is_flashing else Color.WHITE
	var skin_shade = skin_color.darkened(0.2) if enable_shading else skin_color
	var hair_col = appearance.hair_color if not is_flashing else Color.WHITE
	var top_col = appearance.top_color if not is_flashing else Color.WHITE
	var top_shade = top_col.darkened(0.15) if enable_shading else top_col
	var bottom_col = appearance.bottom_color if not is_flashing else Color.WHITE
	var bottom_shade = bottom_col.darkened(0.15) if enable_shading else bottom_col
	var glove_col = appearance.glove_color if not is_flashing else Color.WHITE
	var acc_col = appearance.accessory_color if not is_flashing else Color.WHITE

	# Get build multiplier
	var build_mult = _get_build_multiplier()

	# Draw shadow (proper body shape shadow)
	var shadow_offset = Vector2(3, 3)
	var shadow_color = Color(0, 0, 0, 0.35)
	_draw_limb_polygon(neck_pos + shadow_offset, hip_pos + shadow_offset, TORSO_WIDTH_TOP * build_mult, TORSO_WIDTH_BOT * build_mult, shadow_color, Color.TRANSPARENT)
	_draw_limb_polygon(left_hip + shadow_offset, left_knee + shadow_offset, LEG_WIDTH_UPPER * build_mult, LEG_WIDTH_LOWER * build_mult, shadow_color, Color.TRANSPARENT)
	_draw_limb_polygon(right_hip + shadow_offset, right_knee + shadow_offset, LEG_WIDTH_UPPER * build_mult, LEG_WIDTH_LOWER * build_mult, shadow_color, Color.TRANSPARENT)

	# ===== Draw legs with pants (POLYGON VERSION) =====
	_draw_legs_polygon(skin_color, skin_shade, bottom_col, bottom_shade, build_mult)

	# ===== Draw torso with clothing (POLYGON VERSION) =====
	_draw_torso_polygon(skin_color, skin_shade, top_col, top_shade, build_mult)

	# ===== Draw head and face =====
	_draw_head_mugen(skin_color, build_mult)

	# ===== Draw hair =====
	_draw_hair(hair_col)

	# ===== Draw accessory =====
	_draw_accessory(acc_col)

	# ===== Draw cloth physics =====
	_draw_cloth(top_col)

	# ===== Draw arms (POLYGON VERSION) =====
	_draw_arms_polygon(skin_color, skin_shade, top_col, top_shade, glove_col, build_mult)


func _draw_cloth(cloth_color: Color) -> void:
	if cloth_mesh == null:
		return

	# Draw cloth as connected triangles
	for y in range(cloth_mesh.height - 1):
		for x in range(cloth_mesh.width - 1):
			var p1 = cloth_mesh.get_point(x, y)
			var p2 = cloth_mesh.get_point(x + 1, y)
			var p3 = cloth_mesh.get_point(x, y + 1)
			var p4 = cloth_mesh.get_point(x + 1, y + 1)

			if p1 and p2 and p3 and p4:
				# Draw two triangles to form a quad
				var color1 = cloth_color
				var color2 = cloth_color.darkened(0.1)

				# Triangle 1
				var tri1 = PackedVector2Array([p1.position, p2.position, p3.position])
				draw_colored_polygon(tri1, color1)

				# Triangle 2
				var tri2 = PackedVector2Array([p2.position, p4.position, p3.position])
				draw_colored_polygon(tri2, color2)

	# Draw cloth edges for definition
	for y in range(cloth_mesh.height):
		for x in range(cloth_mesh.width - 1):
			var p1 = cloth_mesh.get_point(x, y)
			var p2 = cloth_mesh.get_point(x + 1, y)
			if p1 and p2:
				draw_line(p1.position, p2.position, cloth_color.darkened(0.2), 0.5)


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


# MUGEN-style polygon legs rendering
func _draw_legs_polygon(skin_color: Color, skin_shade: Color, pants_color: Color, pants_shade: Color, build_mult: float) -> void:
	var upper_width = LEG_WIDTH_UPPER * build_mult
	var lower_width = LEG_WIDTH_LOWER * build_mult
	var foot_width = LEG_WIDTH_FOOT * build_mult

	# Determine what's covered by pants
	var shorts = appearance.bottom_style in [CharacterAppearanceClass.BottomStyle.SHORTS, CharacterAppearanceClass.BottomStyle.TRUNKS]
	var baggy = appearance.bottom_style == CharacterAppearanceClass.BottomStyle.BAGGY

	if baggy:
		upper_width *= 1.3
		lower_width *= 1.2

	# Draw left leg
	if shorts:
		# Upper: pants, Lower: skin
		_draw_limb_polygon(left_hip, left_knee, upper_width, lower_width, pants_shade, outline_color)
		_draw_limb_polygon(left_knee, left_foot, lower_width, foot_width, skin_color, outline_color)
	else:
		# Full pants
		_draw_limb_polygon(left_hip, left_knee, upper_width, lower_width, pants_shade, outline_color)
		_draw_limb_polygon(left_knee, left_foot, lower_width, foot_width, pants_color, outline_color)

	# Draw right leg
	if shorts:
		_draw_limb_polygon(right_hip, right_knee, upper_width, lower_width, pants_color, outline_color)
		_draw_limb_polygon(right_knee, right_foot, lower_width, foot_width, skin_shade, outline_color)
	else:
		_draw_limb_polygon(right_hip, right_knee, upper_width, lower_width, pants_color, outline_color)
		_draw_limb_polygon(right_knee, right_foot, lower_width, foot_width, pants_shade, outline_color)

	# Draw feet/shoes with outlines
	var shoe_color = pants_color.darkened(0.3)
	_draw_foot(left_foot, 3.5 * build_mult, shoe_color, left_knee)
	_draw_foot(right_foot, 3.5 * build_mult, shoe_color, right_knee)

	# Knee highlights
	_draw_joint_highlight(left_knee)
	_draw_joint_highlight(right_knee)


# Helper: Draw a foot/shoe shape
func _draw_foot(pos: Vector2, size: float, color: Color, knee_pos: Vector2) -> void:
	var dir = (pos - knee_pos).normalized()
	# Foot extends forward a bit
	var foot_extension = Vector2(dir.y * 0.5, 0) * size

	var points = PackedVector2Array([
		pos + Vector2(-size * 0.6, -size * 0.4),
		pos + Vector2(-size * 0.6, size * 0.3),
		pos + foot_extension + Vector2(size * 0.4, size * 0.3),
		pos + foot_extension + Vector2(size * 0.5, -size * 0.2),
		pos + Vector2(size * 0.3, -size * 0.4)
	])

	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, outline_color, outline_width)

	# Shoe highlight
	draw_circle(pos + Vector2(0, -size * 0.2), size * 0.2, color.lightened(0.2))


# MUGEN-style polygon torso rendering
func _draw_torso_polygon(skin_color: Color, skin_shade: Color, top_color: Color, top_shade: Color, build_mult: float) -> void:
	var top_width = TORSO_WIDTH_TOP * build_mult
	var bot_width = TORSO_WIDTH_BOT * build_mult

	match appearance.top_style:
		CharacterAppearanceClass.TopStyle.NONE:
			# Shirtless - skin colored torso with muscle definition
			_draw_limb_polygon(neck_pos, hip_pos, top_width, bot_width, skin_color, outline_color)

			# Add muscle definition for muscular builds
			if appearance.build == CharacterAppearanceClass.Build.MUSCULAR:
				var chest_pos = neck_pos.lerp(hip_pos, 0.25)
				# Pec muscles
				draw_circle(chest_pos + Vector2(-2.5, 0), 3, skin_shade)
				draw_circle(chest_pos + Vector2(2.5, 0), 3, skin_shade)
				# Abs (subtle lines)
				for i in range(3):
					var ab_y = neck_pos.lerp(hip_pos, 0.45 + i * 0.15).y
					draw_line(Vector2(neck_pos.x - 1.5, ab_y), Vector2(neck_pos.x + 1.5, ab_y), skin_shade, 0.8)

			# Add shading on one side
			if enable_shading:
				var shade_points = PackedVector2Array([
					neck_pos + Vector2(top_width * 0.2, 0),
					neck_pos + Vector2(top_width * 0.5, 0),
					hip_pos + Vector2(bot_width * 0.5, 0),
					hip_pos + Vector2(bot_width * 0.1, 0)
				])
				draw_colored_polygon(shade_points, skin_shade)

		CharacterAppearanceClass.TopStyle.TANK_TOP:
			# Tank top with exposed shoulders
			_draw_limb_polygon(neck_pos, hip_pos, top_width * 0.85, bot_width, top_color, outline_color)
			# Shoulder circles (skin showing)
			_draw_circle_with_outline(left_shoulder, 2.5 * build_mult, skin_color, outline_color)
			_draw_circle_with_outline(right_shoulder, 2.5 * build_mult, skin_color, outline_color)
			# Tank top straps
			draw_line(neck_pos + Vector2(-2, 2), left_shoulder + Vector2(1, -1), top_shade, 2)
			draw_line(neck_pos + Vector2(2, 2), right_shoulder + Vector2(-1, -1), top_shade, 2)

		CharacterAppearanceClass.TopStyle.T_SHIRT, CharacterAppearanceClass.TopStyle.GI_TOP:
			# T-shirt or gi - full coverage
			_draw_limb_polygon(neck_pos, hip_pos, top_width + 1, bot_width + 1, top_color, outline_color)
			# Collar detail
			draw_arc(neck_pos + Vector2(0, 2), 4, PI * 0.2, PI * 0.8, 8, top_shade, 2)
			# Center line for gi
			if appearance.top_style == CharacterAppearanceClass.TopStyle.GI_TOP:
				draw_line(neck_pos + Vector2(0, 3), hip_pos, top_shade, 1.5)
			# Side shading
			if enable_shading:
				var shade_points = PackedVector2Array([
					neck_pos + Vector2(top_width * 0.3, 0),
					neck_pos + Vector2(top_width * 0.5 + 1, 0),
					hip_pos + Vector2(bot_width * 0.5 + 1, 0),
					hip_pos + Vector2(bot_width * 0.2, 0)
				])
				draw_colored_polygon(shade_points, top_shade)

		CharacterAppearanceClass.TopStyle.HOODIE:
			# Hoodie - bulkier with hood
			_draw_limb_polygon(neck_pos, hip_pos, top_width + 3, bot_width + 2, top_color, outline_color)
			# Hood behind head (drawn later in hair section or here as base)
			var hood_points = PackedVector2Array([
				neck_pos + Vector2(-6, -2),
				neck_pos + Vector2(-8, -8),
				neck_pos + Vector2(0, -12),
				neck_pos + Vector2(8, -8),
				neck_pos + Vector2(6, -2)
			])
			draw_colored_polygon(hood_points, top_shade)
			draw_polyline(hood_points, outline_color, outline_width)
			# Kangaroo pocket
			var pocket_y = hip_pos.y - 3
			draw_arc(Vector2(neck_pos.x, pocket_y), 4, 0, PI, 6, top_shade, 2)

		CharacterAppearanceClass.TopStyle.JACKET:
			# Open jacket - shows undershirt
			# Undershirt first
			_draw_limb_polygon(neck_pos + Vector2(0, 2), hip_pos, top_width * 0.8, bot_width * 0.8, skin_shade, Color.TRANSPARENT)
			# Jacket sides (open front)
			var jacket_left = PackedVector2Array([
				neck_pos + Vector2(-top_width * 0.3, 0),
				neck_pos + Vector2(-top_width * 0.55, 0),
				hip_pos + Vector2(-bot_width * 0.6, 0),
				hip_pos + Vector2(-bot_width * 0.2, 0)
			])
			var jacket_right = PackedVector2Array([
				neck_pos + Vector2(top_width * 0.3, 0),
				neck_pos + Vector2(top_width * 0.55, 0),
				hip_pos + Vector2(bot_width * 0.6, 0),
				hip_pos + Vector2(bot_width * 0.2, 0)
			])
			draw_colored_polygon(jacket_left, top_color)
			draw_colored_polygon(jacket_right, top_shade)
			jacket_left.append(jacket_left[0])
			jacket_right.append(jacket_right[0])
			draw_polyline(jacket_left, outline_color, outline_width)
			draw_polyline(jacket_right, outline_color, outline_width)
			# Collar
			draw_line(neck_pos + Vector2(-3, 1), neck_pos + Vector2(-5, 4), top_color, 3)
			draw_line(neck_pos + Vector2(3, 1), neck_pos + Vector2(5, 4), top_shade, 3)

		CharacterAppearanceClass.TopStyle.VEST:
			# Vest - no sleeves, open front
			_draw_limb_polygon(neck_pos, hip_pos, top_width, bot_width, top_color, outline_color)
			# V-neck opening
			var vneck = PackedVector2Array([
				neck_pos + Vector2(-2, 2),
				neck_pos + Vector2(0, 8),
				neck_pos + Vector2(2, 2)
			])
			draw_colored_polygon(vneck, skin_color)
			draw_polyline(vneck, outline_color, 1.0)
			# Side shading
			if enable_shading:
				var shade_points = PackedVector2Array([
					neck_pos + Vector2(top_width * 0.2, 0),
					neck_pos + Vector2(top_width * 0.5, 0),
					hip_pos + Vector2(bot_width * 0.5, 0),
					hip_pos + Vector2(bot_width * 0.1, 0)
				])
				draw_colored_polygon(shade_points, top_shade)


# MUGEN-style head with detailed expressions
func _draw_head_mugen(skin_color: Color, build_mult: float) -> void:
	var hr = HEAD_RADIUS * build_mult
	var skin_shade = skin_color.darkened(0.15)

	# Draw head with outline
	_draw_circle_with_outline(head_pos, hr, skin_color, outline_color)

	# Add shading (crescent on one side)
	if enable_shading:
		draw_arc(head_pos + Vector2(hr * 0.2, 0), hr * 0.95, -PI * 0.4, PI * 0.4, 12, skin_shade, hr * 0.3)

	# Ear (side of head)
	var ear_pos = head_pos + Vector2(hr * 0.85, 0)
	draw_circle(ear_pos, hr * 0.25, skin_shade)
	draw_arc(ear_pos, hr * 0.25, 0, TAU, 8, outline_color, outline_width * 0.7)

	# Draw detailed face based on expression
	_draw_face_detailed(skin_color, skin_shade, hr)


func _draw_face_detailed(skin_color: Color, skin_shade: Color, hr: float) -> void:
	var eye_offset = hr * 0.35
	var eye_y = head_pos.y - hr * 0.1

	match current_expression:
		Expression.NEUTRAL:
			# Standard determined eyes
			_draw_eye(Vector2(head_pos.x - eye_offset, eye_y), 2.2, false, false)
			_draw_eye(Vector2(head_pos.x + eye_offset, eye_y), 2.2, false, false)
			# Neutral mouth
			draw_line(Vector2(head_pos.x - 2, head_pos.y + hr * 0.4), Vector2(head_pos.x + 2, head_pos.y + hr * 0.4), skin_shade, 1.5)

		Expression.FOCUSED:
			# Narrowed focused eyes
			_draw_eye(Vector2(head_pos.x - eye_offset, eye_y), 2.0, true, false)
			_draw_eye(Vector2(head_pos.x + eye_offset, eye_y), 2.0, true, false)
			# Slight frown
			draw_arc(Vector2(head_pos.x, head_pos.y + hr * 0.45), 2.5, PI * 1.1, PI * 1.9, 6, skin_shade, 1.5)

		Expression.ANGRY:
			# Angry slanted eyebrows
			draw_line(Vector2(head_pos.x - eye_offset - 3, eye_y - 4), Vector2(head_pos.x - eye_offset + 2, eye_y - 2), outline_color, 2)
			draw_line(Vector2(head_pos.x + eye_offset + 3, eye_y - 4), Vector2(head_pos.x + eye_offset - 2, eye_y - 2), outline_color, 2)
			# Intense eyes
			_draw_eye(Vector2(head_pos.x - eye_offset, eye_y), 2.0, true, true)
			_draw_eye(Vector2(head_pos.x + eye_offset, eye_y), 2.0, true, true)
			# Gritting teeth
			var mouth_y = head_pos.y + hr * 0.4
			draw_rect(Rect2(head_pos.x - 3, mouth_y - 1, 6, 3), skin_shade)
			draw_line(Vector2(head_pos.x - 3, mouth_y), Vector2(head_pos.x + 3, mouth_y), Color.WHITE, 1)
			draw_rect(Rect2(head_pos.x - 3, mouth_y - 1, 6, 3), outline_color, false, 1)

		Expression.HURT:
			# Squinting in pain
			draw_line(Vector2(head_pos.x - eye_offset - 2, eye_y - 1), Vector2(head_pos.x - eye_offset + 2, eye_y + 1), outline_color, 2)
			draw_line(Vector2(head_pos.x + eye_offset - 2, eye_y - 1), Vector2(head_pos.x + eye_offset + 2, eye_y + 1), outline_color, 2)
			# Pain lines near eyes
			draw_line(Vector2(head_pos.x - eye_offset - 3, eye_y - 2), Vector2(head_pos.x - eye_offset - 1, eye_y), outline_color, 1)
			draw_line(Vector2(head_pos.x + eye_offset + 3, eye_y - 2), Vector2(head_pos.x + eye_offset + 1, eye_y), outline_color, 1)
			# Open mouth in pain
			draw_circle(Vector2(head_pos.x, head_pos.y + hr * 0.45), 2.5, skin_shade)
			draw_arc(Vector2(head_pos.x, head_pos.y + hr * 0.45), 2.5, 0, TAU, 8, outline_color, 1)

		Expression.VICTORIOUS:
			# Happy closed eyes (^_^)
			draw_arc(Vector2(head_pos.x - eye_offset, eye_y + 1), 2.5, PI * 1.1, PI * 1.9, 8, outline_color, 2)
			draw_arc(Vector2(head_pos.x + eye_offset, eye_y + 1), 2.5, PI * 1.1, PI * 1.9, 8, outline_color, 2)
			# Big smile
			draw_arc(Vector2(head_pos.x, head_pos.y + hr * 0.35), 4, 0.1, PI - 0.1, 10, skin_shade, 2)
			draw_arc(Vector2(head_pos.x, head_pos.y + hr * 0.35), 4, 0.1, PI - 0.1, 10, outline_color, 1)
			# Teeth showing
			draw_line(Vector2(head_pos.x - 3, head_pos.y + hr * 0.35), Vector2(head_pos.x + 3, head_pos.y + hr * 0.35), Color.WHITE, 2)

		Expression.EXHAUSTED:
			# Tired droopy eyes with bags
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y + 1), 1.8, Color.WHITE)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y + 1), 1.8, Color.WHITE)
			draw_circle(Vector2(head_pos.x - eye_offset, eye_y + 1.5), 0.8, Color.BLACK)
			draw_circle(Vector2(head_pos.x + eye_offset, eye_y + 1.5), 0.8, Color.BLACK)
			# Droopy eyelids
			draw_line(Vector2(head_pos.x - eye_offset - 2.5, eye_y - 0.5), Vector2(head_pos.x - eye_offset + 2.5, eye_y + 1), skin_color, 2)
			draw_line(Vector2(head_pos.x + eye_offset - 2.5, eye_y - 0.5), Vector2(head_pos.x + eye_offset + 2.5, eye_y + 1), skin_color, 2)
			# Eye bags
			draw_arc(Vector2(head_pos.x - eye_offset, eye_y + 3), 2, 0, PI, 6, skin_shade, 1)
			draw_arc(Vector2(head_pos.x + eye_offset, eye_y + 3), 2, 0, PI, 6, skin_shade, 1)
			# Exhausted open mouth
			var mouth_y = head_pos.y + hr * 0.45
			draw_arc(Vector2(head_pos.x, mouth_y), 2, 0, PI, 6, skin_shade, 1.5)
			# Sweat drop
			var sweat_pos = head_pos + Vector2(-hr * 0.9, -hr * 0.3)
			draw_circle(sweat_pos, 1.5, Color(0.7, 0.85, 1.0, 0.8))


# Helper: Draw a detailed eye
func _draw_eye(pos: Vector2, size: float, narrowed: bool, intense: bool) -> void:
	var eye_height = size if not narrowed else size * 0.6

	# Eye white
	if narrowed:
		# Narrowed eye shape
		var points = PackedVector2Array([
			pos + Vector2(-size, 0),
			pos + Vector2(0, -eye_height * 0.5),
			pos + Vector2(size, 0),
			pos + Vector2(0, eye_height * 0.5)
		])
		draw_colored_polygon(points, Color.WHITE)
	else:
		draw_circle(pos, size, Color.WHITE)

	# Iris
	var iris_color = Color(0.3, 0.2, 0.1) if not intense else Color(0.8, 0.2, 0.1)
	var iris_size = size * 0.6
	draw_circle(pos + Vector2(0, eye_height * 0.1), iris_size, iris_color)

	# Pupil
	draw_circle(pos + Vector2(0, eye_height * 0.15), iris_size * 0.5, Color.BLACK)

	# Highlight
	draw_circle(pos + Vector2(-size * 0.25, -eye_height * 0.2), size * 0.2, Color(1, 1, 1, 0.8))

	# Eye outline
	if narrowed:
		draw_line(pos + Vector2(-size, 0), pos + Vector2(size, 0), outline_color, 1)
	else:
		draw_arc(pos, size, 0, TAU, 12, outline_color, 1)


func _draw_hair(hair_color: Color) -> void:
	var hr = HEAD_RADIUS

	# Check if we have physics-based hair
	var has_physics_hair = not hair_chains.is_empty()

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
			# Hair base on head
			draw_arc(head_pos, hr + 1, PI * 0.7, PI * 0.3, 12, hair_color, 3)
			# Physics-based ponytail
			if has_physics_hair and hair_chains.size() > 0:
				_draw_hair_chain(hair_chains[0], hair_color, 3.0)
			else:
				# Fallback static ponytail
				var tail_start = head_pos + Vector2(0, -hr * 0.3)
				var tail_end = tail_start + Vector2(8, 6)
				draw_line(tail_start, tail_end, hair_color, 3)
				draw_circle(tail_end, 2, hair_color)

		CharacterAppearanceClass.HairStyle.LONG:
			# Hair base on head
			draw_arc(head_pos, hr + 1, PI * 0.8, PI * 0.2, 12, hair_color, 3)
			# Physics-based flowing hair
			if has_physics_hair:
				for chain in hair_chains:
					_draw_hair_chain(chain, hair_color, 2.5)
			else:
				# Fallback static hair
				draw_line(head_pos + Vector2(-hr, 0), head_pos + Vector2(-hr - 2, 12), hair_color, 3)
				draw_line(head_pos + Vector2(hr, 0), head_pos + Vector2(hr + 2, 12), hair_color, 3)

		CharacterAppearanceClass.HairStyle.AFRO:
			# Big afro (no physics - too complex)
			draw_circle(head_pos + Vector2(0, -3), hr + 5, hair_color)
			draw_arc(head_pos + Vector2(0, -3), hr + 5, 0, TAU, 20, hair_color.darkened(0.1), 2)

		CharacterAppearanceClass.HairStyle.BRAIDS:
			# Hair base
			draw_arc(head_pos, hr + 1, PI * 0.7, PI * 0.3, 12, hair_color, 3)
			# Physics-based braids
			if has_physics_hair:
				for chain in hair_chains:
					_draw_braid_chain(chain, hair_color)
			else:
				# Fallback static braids
				for i in range(3):
					var braid_x = head_pos.x + (i - 1) * 5
					var braid_start = head_pos + Vector2((i - 1) * 4, hr * 0.3)
					for j in range(4):
						var by = braid_start.y + j * 3
						draw_circle(Vector2(braid_x, by), 1.5, hair_color)

		CharacterAppearanceClass.HairStyle.SLICKED:
			# Slicked back hair (no physics)
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
			# Hair base
			draw_arc(head_pos, hr + 2, PI * 0.9, PI * 0.1, 12, hair_color, 4)
			# Physics-based wild strands
			if has_physics_hair:
				for chain in hair_chains:
					_draw_hair_chain(chain, hair_color, 2.0)
			else:
				# Fallback static tufts
				for i in range(6):
					var angle = PI * 0.2 + i * PI * 0.13
					var tuft_start = head_pos + Vector2(cos(angle), -sin(angle)) * hr
					var tuft_end = tuft_start + Vector2(cos(angle), -sin(angle)) * 5
					draw_line(tuft_start, tuft_end, hair_color, 2)


func _draw_hair_chain(chain, hair_color: Color, width: float = 3.0) -> void:
	var positions = chain.get_positions()
	if positions.size() < 2:
		return

	# Draw as connected lines with decreasing width
	for i in range(positions.size() - 1):
		var t = float(i) / float(positions.size() - 1)
		var w = width * (1.0 - t * 0.5)  # Taper towards end
		draw_line(positions[i], positions[i + 1], hair_color, w)

	# Draw end circle
	draw_circle(positions[positions.size() - 1], width * 0.4, hair_color)


func _draw_braid_chain(chain, hair_color: Color) -> void:
	var positions = chain.get_positions()
	if positions.size() < 2:
		return

	# Draw beads along the braid
	for i in range(positions.size()):
		var t = float(i) / float(positions.size() - 1)
		var size = 2.0 * (1.0 - t * 0.3)
		draw_circle(positions[i], size, hair_color)
		if i > 0:
			draw_line(positions[i - 1], positions[i], hair_color, 1.5)


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


# MUGEN-style polygon arms rendering
func _draw_arms_polygon(skin_color: Color, skin_shade: Color, top_color: Color, top_shade: Color, glove_col: Color, build_mult: float) -> void:
	var upper_width = ARM_WIDTH_UPPER * build_mult
	var lower_width = ARM_WIDTH_LOWER * build_mult
	var hand_width = ARM_WIDTH_HAND * build_mult

	# Determine arm coverage based on top style
	var has_sleeves = appearance.top_style in [CharacterAppearanceClass.TopStyle.T_SHIRT, CharacterAppearanceClass.TopStyle.HOODIE, CharacterAppearanceClass.TopStyle.GI_TOP, CharacterAppearanceClass.TopStyle.JACKET]

	# Left arm (usually shaded)
	if has_sleeves:
		_draw_limb_polygon(left_shoulder, left_elbow, upper_width + 1, lower_width, top_shade, outline_color)
	else:
		_draw_limb_polygon(left_shoulder, left_elbow, upper_width, lower_width, skin_shade, outline_color)
	_draw_limb_polygon(left_elbow, left_hand, lower_width, hand_width, skin_color, outline_color)

	# Right arm
	if has_sleeves:
		_draw_limb_polygon(right_shoulder, right_elbow, upper_width + 1, lower_width, top_color, outline_color)
	else:
		_draw_limb_polygon(right_shoulder, right_elbow, upper_width, lower_width, skin_color, outline_color)
	_draw_limb_polygon(right_elbow, right_hand, lower_width, hand_width, skin_shade, outline_color)

	# Boxing gloves
	_draw_glove(left_hand, 5.0 * build_mult, glove_col, left_elbow)
	_draw_glove(right_hand, 5.0 * build_mult, glove_col, right_elbow)

	# Elbow and shoulder highlights
	_draw_joint_highlight(left_elbow)
	_draw_joint_highlight(right_elbow)
	_draw_joint_highlight(left_shoulder)
	_draw_joint_highlight(right_shoulder)


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


# KISS: Simplified using constant dictionary
func _get_pose_data(pose: Pose) -> Dictionary:
	return POSE_DATA.get(pose, {})


# KISS: Simplified using constant dictionary
func get_pose_for_move(move_name: String) -> Pose:
	return MOVE_POSE_MAP.get(move_name, Pose.JAB)
