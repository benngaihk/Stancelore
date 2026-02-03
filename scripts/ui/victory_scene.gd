extends Control
## VictoryScene - Victory screen

@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var menu_btn: Button = $VBoxContainer/MenuBtn


func _ready() -> void:
	var run = RunManager.get_current_run()
	if run:
		var text = "Battles Won: " + str(run.battles_won)
		text += "\nElites Defeated: " + str(run.elites_defeated)
		text += "\nGold Earned: " + str(run.gold)
		stats_label.text = text

	menu_btn.pressed.connect(_on_menu_pressed)


func _on_menu_pressed() -> void:
	RunManager.go_to_main_menu()
