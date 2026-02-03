extends Control
class_name CoachSystem
## CoachSystem - Handles coach instruction UI and cooldown

@export var cooldown_duration: float = 5.0

var current_instruction: String = "balanced"
var cooldown_timer: float = 0.0
var is_on_cooldown: bool = false

# UI References
@onready var aggressive_btn: Button = $VBoxContainer/HBoxContainer/AggressiveBtn
@onready var balanced_btn: Button = $VBoxContainer/HBoxContainer/BalancedBtn
@onready var defensive_btn: Button = $VBoxContainer/HBoxContainer/DefensiveBtn
@onready var cooldown_bar: ProgressBar = $VBoxContainer/CooldownBar
@onready var instruction_label: Label = $VBoxContainer/InstructionLabel


func _ready() -> void:
	# Connect buttons
	aggressive_btn.pressed.connect(_on_aggressive_pressed)
	balanced_btn.pressed.connect(_on_balanced_pressed)
	defensive_btn.pressed.connect(_on_defensive_pressed)

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

	instruction_label.text = display_text


func _update_button_states() -> void:
	var can_press = not is_on_cooldown
	aggressive_btn.disabled = not can_press
	balanced_btn.disabled = not can_press
	defensive_btn.disabled = not can_press

	# Highlight current instruction
	aggressive_btn.modulate = Color.WHITE if current_instruction != "aggressive" else Color(1.2, 0.8, 0.8)
	balanced_btn.modulate = Color.WHITE if current_instruction != "balanced" else Color(1.2, 1.2, 1.2)
	defensive_btn.modulate = Color.WHITE if current_instruction != "defensive" else Color(0.8, 0.8, 1.2)


func _on_aggressive_pressed() -> void:
	_give_instruction("aggressive")


func _on_balanced_pressed() -> void:
	_give_instruction("balanced")


func _on_defensive_pressed() -> void:
	_give_instruction("defensive")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("coach_aggressive"):
		_on_aggressive_pressed()
	elif event.is_action_pressed("coach_balanced"):
		_on_balanced_pressed()
	elif event.is_action_pressed("coach_defensive"):
		_on_defensive_pressed()
