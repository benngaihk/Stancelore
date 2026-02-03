extends Control
## RestScene - Heal HP

@onready var info_label: Label = $VBoxContainer/InfoLabel
@onready var rest_btn: Button = $VBoxContainer/RestBtn


func _ready() -> void:
	var run = RunManager.get_current_run()
	if run:
		info_label.text = "HP: " + str(int(run.current_hp)) + "/" + str(int(run.max_hp))
	rest_btn.pressed.connect(_on_rest_pressed)


func _on_rest_pressed() -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	# Heal 30% of max HP
	var heal_amount = run.max_hp * 0.3
	var healed = run.heal(heal_amount)

	info_label.text = "Healed " + str(int(healed)) + " HP!"
	rest_btn.disabled = true

	await get_tree().create_timer(1.5).timeout
	RunManager.on_node_action_completed()
