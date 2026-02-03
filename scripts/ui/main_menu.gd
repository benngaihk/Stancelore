extends Control
## MainMenu - Game main menu

@onready var start_btn: Button = $VBoxContainer/StartBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn


func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Focus on start button
	start_btn.grab_focus()


func _on_start_pressed() -> void:
	RunManager.go_to_character_select()


func _on_quit_pressed() -> void:
	get_tree().quit()
