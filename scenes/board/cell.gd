class_name Cell
extends Control

@export var index: int = -1
@export var current_state: bool = false
@export var cell_type: int = 0 # CellType enum
@export var param: int = 0
@export var counter: int = 0
@export var is_current: bool = false
@export var is_blocked: bool = false

@onready var bit_label = $BitLabel

func setup(p_index: int, p_type: int, p_param: int, initial_state: bool):
	index = p_index
	cell_type = p_type
	param = p_param
	current_state = initial_state
	refresh_visual()

func update_state(new_state: bool):
	current_state = new_state
	refresh_visual()

func update_counter(new_counter: int):
	counter = new_counter
	refresh_visual()

func set_current(active: bool):
	is_current = active
	refresh_visual()

func set_blocked(blocked: bool):
	is_blocked = blocked
	refresh_visual()

func refresh_visual():
	# Update the bit text
	bit_label.text = "1" if current_state else "0"

	# Underline if cursor is here
	if is_current:
		bit_label.add_theme_font_override("font", null) # reset
		bit_label.set("underline", true)
	else:
		bit_label.set("underline", false)

	# Strikethrough / gray if blocked
	if is_blocked:
		bit_label.modulate = Color.GRAY
		bit_label.set("strikethrough", true)
	else:
		bit_label.modulate = Color.WHITE
		bit_label.set("strikethrough", false)

	# Optionally change background color based on cell type
	match cell_type:
		GameBoard.CellType.FLIP_EVERY_N:
			modulate = Color(0.8, 1.0, 0.8)   # light green tint
		GameBoard.CellType.BLOCKER:
			modulate = Color(1.0, 0.8, 0.8)   # light red tint
		GameBoard.CellType.EXPLODING:
			modulate = Color(1.0, 0.8, 1.0)   # light magenta tint
		_:
			modulate = Color.WHITE
