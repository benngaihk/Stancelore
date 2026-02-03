extends Control
## TrainingScene - Upgrade stats

@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var info_label: Label = $VBoxContainer/InfoLabel

var stat_names: Array = ["strength", "agility", "vitality", "technique", "willpower", "intuition"]
var stat_labels: Array = ["STR", "AGI", "VIT", "TEC", "WIL", "INT"]


func _ready() -> void:
	_setup_stat_buttons()


func _setup_stat_buttons() -> void:
	var run = RunManager.get_current_run()
	if run == null or run.fighter_stats == null:
		return

	for i in range(stat_names.size()):
		var hbox = HBoxContainer.new()

		var label = Label.new()
		var stat_value = run.fighter_stats.get(stat_names[i])
		label.text = stat_labels[i] + ": " + str(stat_value)
		label.custom_minimum_size.x = 60
		hbox.add_child(label)

		var btn = Button.new()
		btn.text = "+1"
		btn.disabled = stat_value >= 10
		btn.pressed.connect(_on_stat_upgrade.bind(stat_names[i]))
		hbox.add_child(btn)

		stats_container.add_child(hbox)


func _on_stat_upgrade(stat_name: String) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if run.add_stat_point(stat_name):
		info_label.text = stat_name.to_upper() + " upgraded!"
		await get_tree().create_timer(1.0).timeout
		RunManager.on_node_action_completed()
