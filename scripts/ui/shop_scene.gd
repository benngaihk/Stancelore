extends Control
## ShopScene - Buy items and services

var shop_items: Array = [
	{"name": "Heal Potion", "cost": 30, "effect": "heal_50"},
	{"name": "STR Training", "cost": 50, "effect": "stat_strength"},
	{"name": "AGI Training", "cost": 50, "effect": "stat_agility"},
	{"name": "Full Heal", "cost": 80, "effect": "heal_full"}
]

@onready var gold_label: Label = $VBoxContainer/GoldLabel
@onready var items_container: VBoxContainer = $VBoxContainer/ItemsContainer
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var leave_btn: Button = $VBoxContainer/LeaveBtn


func _ready() -> void:
	_update_gold_display()
	_setup_shop_items()
	leave_btn.pressed.connect(_on_leave_pressed)


func _update_gold_display() -> void:
	var run = RunManager.get_current_run()
	if run:
		gold_label.text = "Gold: " + str(run.gold)


func _setup_shop_items() -> void:
	for item in shop_items:
		var hbox = HBoxContainer.new()

		var label = Label.new()
		label.text = item["name"] + " - " + str(item["cost"]) + "g"
		label.custom_minimum_size.x = 120
		hbox.add_child(label)

		var btn = Button.new()
		btn.text = "BUY"
		btn.pressed.connect(_on_buy_item.bind(item))
		hbox.add_child(btn)

		items_container.add_child(hbox)


func _on_buy_item(item: Dictionary) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	if not run.spend_gold(item["cost"]):
		result_label.text = "Not enough gold!"
		return

	# Apply effect
	match item["effect"]:
		"heal_50":
			run.heal(50)
			result_label.text = "Healed 50 HP!"
		"heal_full":
			run.heal(run.max_hp)
			result_label.text = "Fully healed!"
		"stat_strength":
			run.add_stat_point("strength")
			result_label.text = "STR +1!"
		"stat_agility":
			run.add_stat_point("agility")
			result_label.text = "AGI +1!"

	_update_gold_display()


func _on_leave_pressed() -> void:
	RunManager.on_node_action_completed()
