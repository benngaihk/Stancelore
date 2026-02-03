extends Control
## EventScene - Random events

var events: Array = [
	{
		"title": "Mysterious Trainer",
		"description": "An old fighter offers advice.",
		"choices": [
			{"text": "Listen (+1 TEC)", "effect": "stat_technique"},
			{"text": "Decline", "effect": "nothing"}
		]
	},
	{
		"title": "Street Fight",
		"description": "You witness a brawl.",
		"choices": [
			{"text": "Join in (+1 STR, -10 HP)", "effect": "stat_str_damage"},
			{"text": "Watch (+1 INT)", "effect": "stat_intuition"}
		]
	},
	{
		"title": "Lucky Find",
		"description": "You find something on the ground.",
		"choices": [
			{"text": "Take it (+20 Gold)", "effect": "gold"},
			{"text": "Leave it", "effect": "nothing"}
		]
	},
	{
		"title": "Shady Dealer",
		"description": "A man offers you a strange drink.",
		"choices": [
			{"text": "Drink it (Random stat +2)", "effect": "random_stat_boost"},
			{"text": "Refuse", "effect": "nothing"}
		]
	},
	{
		"title": "Training Dummy",
		"description": "You find an abandoned training area.",
		"choices": [
			{"text": "Practice combos (+1 AGI)", "effect": "stat_agility"},
			{"text": "Hit it hard (+1 STR)", "effect": "stat_strength"}
		]
	},
	{
		"title": "Injured Fighter",
		"description": "A wounded fighter asks for help.",
		"choices": [
			{"text": "Help (-20 HP, +30 Gold)", "effect": "help_fighter"},
			{"text": "Ignore", "effect": "nothing"}
		]
	},
	{
		"title": "Meditation Spot",
		"description": "A peaceful place to clear your mind.",
		"choices": [
			{"text": "Meditate (+1 WIL)", "effect": "stat_willpower"},
			{"text": "Rest (+15 HP)", "effect": "small_heal"}
		]
	},
	{
		"title": "Gambler",
		"description": "A gambler offers a bet.",
		"choices": [
			{"text": "Bet 30 Gold (50% double)", "effect": "gamble"},
			{"text": "Walk away", "effect": "nothing"}
		]
	},
	{
		"title": "Ancient Scroll",
		"description": "You find a scroll with fighting techniques.",
		"choices": [
			{"text": "Study it (+1 TEC, +1 INT)", "effect": "double_mental"},
			{"text": "Sell it (+40 Gold)", "effect": "gold_big"}
		]
	},
	{
		"title": "Heavy Bag",
		"description": "A punching bag hangs from a tree.",
		"choices": [
			{"text": "Train endurance (+1 VIT)", "effect": "stat_vitality"},
			{"text": "Skip", "effect": "nothing"}
		]
	}
]

var current_event: Dictionary = {}

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel
@onready var choices_container: VBoxContainer = $VBoxContainer/ChoicesContainer
@onready var result_label: Label = $VBoxContainer/ResultLabel


func _ready() -> void:
	# Pick random event
	current_event = events[randi() % events.size()]
	_display_event()


func _display_event() -> void:
	title_label.text = current_event["title"]
	desc_label.text = current_event["description"]
	result_label.text = ""

	for choice in current_event["choices"]:
		var btn = Button.new()
		btn.text = choice["text"]
		btn.pressed.connect(_on_choice_selected.bind(choice["effect"]))
		choices_container.add_child(btn)


func _on_choice_selected(effect: String) -> void:
	var run = RunManager.get_current_run()
	if run == null:
		return

	# Disable all buttons
	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true

	# Apply effect
	match effect:
		"stat_technique":
			run.add_stat_point("technique")
			result_label.text = "TEC +1!"
		"stat_intuition":
			run.add_stat_point("intuition")
			result_label.text = "INT +1!"
		"stat_strength":
			run.add_stat_point("strength")
			result_label.text = "STR +1!"
		"stat_agility":
			run.add_stat_point("agility")
			result_label.text = "AGI +1!"
		"stat_vitality":
			run.add_stat_point("vitality")
			result_label.text = "VIT +1!"
		"stat_willpower":
			run.add_stat_point("willpower")
			result_label.text = "WIL +1!"
		"stat_str_damage":
			run.add_stat_point("strength")
			run.take_damage(10)
			result_label.text = "STR +1, but took 10 damage!"
		"gold":
			run.add_gold(20)
			result_label.text = "+20 Gold!"
		"gold_big":
			run.add_gold(40)
			result_label.text = "+40 Gold!"
		"random_stat_boost":
			var stats = ["strength", "agility", "vitality", "technique", "willpower", "intuition"]
			var chosen = stats[randi() % stats.size()]
			run.add_stat_point(chosen)
			run.add_stat_point(chosen)
			result_label.text = chosen.to_upper() + " +2!"
		"help_fighter":
			run.take_damage(20)
			run.add_gold(30)
			result_label.text = "-20 HP, +30 Gold"
		"small_heal":
			var healed = run.heal(15)
			result_label.text = "Healed " + str(int(healed)) + " HP!"
		"double_mental":
			run.add_stat_point("technique")
			run.add_stat_point("intuition")
			result_label.text = "TEC +1, INT +1!"
		"gamble":
			if run.spend_gold(30):
				if randf() < 0.5:
					run.add_gold(60)
					result_label.text = "Won! +60 Gold!"
				else:
					result_label.text = "Lost 30 Gold..."
			else:
				result_label.text = "Not enough gold!"
		"nothing":
			result_label.text = "Nothing happened."

	await get_tree().create_timer(1.5).timeout
	RunManager.on_node_action_completed()
