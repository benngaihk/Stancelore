extends Control
## CharacterSelect - Fighter selection screen

const FighterStatsScript = preload("res://scripts/battle/fighter_stats.gd")

# Fighter presets
var fighter_presets: Array = [
	{
		"name": "Balanced",
		"description": "Jack of all trades",
		"stats_func": "create_balanced"
	},
	{
		"name": "Brawler",
		"description": "High power, slow",
		"stats_func": "create_brawler"
	},
	{
		"name": "Speedster",
		"description": "Fast and technical",
		"stats_func": "create_speedster"
	},
	{
		"name": "Tank",
		"description": "High defense, low offense",
		"stats_func": "create_tank"
	},
	{
		"name": "Technician",
		"description": "Crit master, reads opponents",
		"stats_func": "create_technician"
	},
	{
		"name": "Counter",
		"description": "Waits and punishes",
		"stats_func": "create_counter_puncher"
	},
	{
		"name": "Glass Cannon",
		"description": "Kill or be killed",
		"stats_func": "create_glass_cannon"
	},
	{
		"name": "Survivor",
		"description": "Never gives up",
		"stats_func": "create_survivor"
	},
	{
		"name": "Wild Card",
		"description": "Random stats each run",
		"stats_func": "create_wild_card"
	}
]

var selected_index: int = 0

@onready var fighter_list: VBoxContainer = $HBoxContainer/FighterList
@onready var stats_panel: VBoxContainer = $HBoxContainer/StatsPanel
@onready var name_label: Label = $HBoxContainer/StatsPanel/NameLabel
@onready var desc_label: Label = $HBoxContainer/StatsPanel/DescLabel
@onready var stats_label: Label = $HBoxContainer/StatsPanel/StatsLabel
@onready var start_btn: Button = $HBoxContainer/StatsPanel/StartBtn
@onready var back_btn: Button = $BackBtn


func _ready() -> void:
	_setup_fighter_list()
	_update_stats_display()

	start_btn.pressed.connect(_on_start_pressed)
	back_btn.pressed.connect(_on_back_pressed)


func _setup_fighter_list() -> void:
	# Clear existing buttons
	for child in fighter_list.get_children():
		if child is Button:
			child.queue_free()

	# Create buttons for each preset
	for i in range(fighter_presets.size()):
		var preset = fighter_presets[i]
		var btn = Button.new()
		btn.text = preset["name"]
		btn.pressed.connect(_on_fighter_selected.bind(i))
		fighter_list.add_child(btn)

	# Select first by default
	if fighter_list.get_child_count() > 0:
		fighter_list.get_child(0).grab_focus()


func _on_fighter_selected(index: int) -> void:
	selected_index = index
	_update_stats_display()


func _update_stats_display() -> void:
	if selected_index < 0 or selected_index >= fighter_presets.size():
		return

	var preset = fighter_presets[selected_index]
	name_label.text = preset["name"]
	desc_label.text = preset["description"]

	# Get stats
	var stats = _create_stats(preset["stats_func"])
	if stats == null:
		return

	var stats_text = ""
	stats_text += "STR: " + str(stats.strength) + "  "
	stats_text += "AGI: " + str(stats.agility) + "\n"
	stats_text += "VIT: " + str(stats.vitality) + "  "
	stats_text += "TEC: " + str(stats.technique) + "\n"
	stats_text += "WIL: " + str(stats.willpower) + "  "
	stats_text += "INT: " + str(stats.intuition)

	stats_label.text = stats_text


func _create_stats(func_name: String) -> Resource:
	match func_name:
		"create_balanced":
			return FighterStatsScript.create_balanced()
		"create_brawler":
			return FighterStatsScript.create_brawler()
		"create_speedster":
			return FighterStatsScript.create_speedster()
		"create_tank":
			return FighterStatsScript.create_tank()
		"create_technician":
			return FighterStatsScript.create_technician()
		"create_counter_puncher":
			return FighterStatsScript.create_counter_puncher()
		"create_glass_cannon":
			return FighterStatsScript.create_glass_cannon()
		"create_survivor":
			return FighterStatsScript.create_survivor()
		"create_wild_card":
			return FighterStatsScript.create_wild_card()
	return FighterStatsScript.create_balanced()


func _on_start_pressed() -> void:
	var preset = fighter_presets[selected_index]
	var stats = _create_stats(preset["stats_func"])
	RunManager.start_new_run(stats, preset["name"])


func _on_back_pressed() -> void:
	RunManager.go_to_main_menu()
