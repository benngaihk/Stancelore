extends Node2D
class_name StickFigure
## StickFigure - Simple skeleton visualization for fighter animations
## Can be replaced with actual sprites later

# Body part colors
@export var body_color: Color = Color.WHITE
@export var head_color: Color = Color.WHITE
@export var line_width: float = 2.0

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
enum Pose { IDLE, WALK_1, WALK_2, JAB, STRAIGHT, HOOK, UPPERCUT, DEFEND, EVADE, HIT, RECOVERY }


func _ready() -> void:
	set_pose(Pose.IDLE)


func _process(delta: float) -> void:
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
	# Draw head
	draw_circle(head_pos, HEAD_RADIUS, head_color)
	draw_arc(head_pos, HEAD_RADIUS, 0, TAU, 16, body_color, line_width)

	# Draw torso
	draw_line(neck_pos, hip_pos, body_color, line_width)

	# Draw arms
	draw_line(left_shoulder, left_elbow, body_color, line_width)
	draw_line(left_elbow, left_hand, body_color, line_width)
	draw_line(right_shoulder, right_elbow, body_color, line_width)
	draw_line(right_elbow, right_hand, body_color, line_width)

	# Draw legs
	draw_line(left_hip, left_knee, body_color, line_width)
	draw_line(left_knee, left_foot, body_color, line_width)
	draw_line(right_hip, right_knee, body_color, line_width)
	draw_line(right_knee, right_foot, body_color, line_width)

	# Draw joints
	_draw_joint(left_elbow)
	_draw_joint(right_elbow)
	_draw_joint(left_knee)
	_draw_joint(right_knee)


func _draw_joint(pos: Vector2) -> void:
	draw_circle(pos, 1.5, body_color)


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
			return Pose.WALK_1  # Use walk pose for kick
		_:
			return Pose.JAB  # Default attack pose
