extends Control
class_name CoachSystem
## CoachSystem - Handles coach instruction UI and cooldown
## 6 Instructions: Aggressive(猛攻), Balanced(均衡), Defensive(防守), Evasive(回避), Counter(反击), Pressure(压制)

@export var cooldown_duration: float = 5.0

var current_instruction: String = "balanced"
var cooldown_timer: float = 0.0
var is_on_cooldown: bool = false

# UI References - Row 1
@onready var aggressive_btn: Button = $VBoxContainer/Row1/AggressiveBtn
@onready var balanced_btn: Button = $VBoxContainer/Row1/BalancedBtn
@onready var defensive_btn: Button = $VBoxContainer/Row1/DefensiveBtn
# UI References - Row 2
@onready var evasive_btn: Button = $VBoxContainer/Row2/EvasiveBtn
@onready var counter_btn: Button = $VBoxContainer/Row2/CounterBtn
@onready var pressure_btn: Button = $VBoxContainer/Row2/PressureBtn
# Other UI
@onready var cooldown_bar: ProgressBar = $VBoxContainer/CooldownBar
@onready var instruction_label: Label = $VBoxContainer/InstructionLabel


func _ready() -> void:
	# Connect buttons - Row 1
	aggressive_btn.pressed.connect(_on_aggressive_pressed)
	balanced_btn.pressed.connect(_on_balanced_pressed)
	defensive_btn.pressed.connect(_on_defensive_pressed)
	# Connect buttons - Row 2
	evasive_btn.pressed.connect(_on_evasive_pressed)
	counter_btn.pressed.connect(_on_counter_pressed)
	pressure_btn.pressed.connect(_on_pressure_pressed)

	# Initialize UI
	cooldown_bar.max_value = cooldown_duration
	cooldown_bar.value = 0
	_update_instruction_label()
	_update_button_states()


func _process(delta: float) -> void:
	if is_on_cooldown:
		cooldown_timer -= delta
		cooldown_bar.value = cooldown_timer

		if cooldown_timer <= 0:
			is_on_cooldown = false
			cooldown_timer = 0
			cooldown_bar.value = 0
			_update_button_states()
			EventBus.coach_instruction_cooldown_ended.emit()


func _give_instruction(instruction: String) -> void:
	if is_on_cooldown:
		return

	current_instruction = instruction
	EventBus.coach_instruction_given.emit(instruction)

	# Start cooldown
	is_on_cooldown = true
	cooldown_timer = cooldown_duration
	cooldown_bar.value = cooldown_duration
	EventBus.coach_instruction_cooldown_started.emit(cooldown_duration)

	_update_instruction_label()
	_update_button_states()


func _update_instruction_label() -> void:
	var display_text = ""
	match current_instruction:
		"aggressive":
			display_text = "AGGRESSIVE"
			instruction_label.add_theme_color_override("font_color", Color.RED)
		"balanced":
			display_text = "BALANCED"
			instruction_label.add_theme_color_override("font_color", Color.WHITE)
		"defensive":
			display_text = "DEFENSIVE"
			instruction_label.add_theme_color_override("font_color", Color.CYAN)
		"evasive":
			display_text = "EVASIVE"
			instruction_label.add_theme_color_override("font_color", Color.YELLOW)
		"counter":
			display_text = "COUNTER"
			instruction_label.add_theme_color_override("font_color", Color.PURPLE)
		"pressure":
			display_text = "PRESSURE"
			instruction_label.add_theme_color_override("font_color", Color.ORANGE)

	instruction_label.text = display_text


func _update_button_states() -> void:
	var can_press = not is_on_cooldown
	# Row 1
	aggressive_btn.disabled = not can_press
	balanced_btn.disabled = not can_press
	defensive_btn.disabled = not can_press
	# Row 2
	evasive_btn.disabled = not can_press
	counter_btn.disabled = not can_press
	pressure_btn.disabled = not can_press

	# Highlight current instruction - Row 1
	aggressive_btn.modulate = Color.WHITE if current_instruction != "aggressive" else Color(1.2, 0.8, 0.8)
	balanced_btn.modulate = Color.WHITE if current_instruction != "balanced" else Color(1.2, 1.2, 1.2)
	defensive_btn.modulate = Color.WHITE if current_instruction != "defensive" else Color(0.8, 0.8, 1.2)
	# Row 2
	evasive_btn.modulate = Color.WHITE if current_instruction != "evasive" else Color(1.2, 1.2, 0.8)
	counter_btn.modulate = Color.WHITE if current_instruction != "counter" else Color(1.0, 0.8, 1.2)
	pressure_btn.modulate = Color.WHITE if current_instruction != "pressure" else Color(1.2, 1.0, 0.8)


func _on_aggressive_pressed() -> void:
	_give_instruction("aggressive")


func _on_balanced_pressed() -> void:
	_give_instruction("balanced")


func _on_defensive_pressed() -> void:
	_give_instruction("defensive")


func _on_evasive_pressed() -> void:
	_give_instruction("evasive")


func _on_counter_pressed() -> void:
	_give_instruction("counter")


func _on_pressure_pressed() -> void:
	_give_instruction("pressure")


func _unhandled_input(event: InputEvent) -> void:
	# Row 1: Keys 1, 2, 3
	if event.is_action_pressed("coach_aggressive"):
		_on_aggressive_pressed()
	elif event.is_action_pressed("coach_balanced"):
		_on_balanced_pressed()
	elif event.is_action_pressed("coach_defensive"):
		_on_defensive_pressed()
	# Row 2: Keys 4, 5, 6
	elif event.is_action_pressed("coach_evasive"):
		_on_evasive_pressed()
	elif event.is_action_pressed("coach_counter"):
		_on_counter_pressed()
	elif event.is_action_pressed("coach_pressure"):
		_on_pressure_pressed()
