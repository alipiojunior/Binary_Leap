extends Control

@onready var main_panel = $MainPanel
@onready var ready_panel = $ReadyPanel
@onready var credits_panel = $CreditsPanel

func _ready():
	show_panel(main_panel)

func show_panel(panel_to_show: Control):
	main_panel.visible = false
	ready_panel.visible = false
	credits_panel.visible = false
	
	panel_to_show.visible = true

func _on_start_button_pressed():
	show_panel(ready_panel)

func _on_credits_button_pressed():
	show_panel(credits_panel)

func _on_yes_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_not_yet_button_pressed():
	show_panel(main_panel)

func _on_back_button_pressed():
	show_panel(main_panel)

func _on_credits_back_button_pressed():
	show_panel(main_panel)
