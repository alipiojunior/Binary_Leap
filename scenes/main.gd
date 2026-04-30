extends Node

@onready var game_board = $GameBoard
@onready var target_label = $Target
@onready var current_label = $Board
@onready var info_label = $Info
@onready var win_sound = $WinSound
@onready var move_sound = $MoveSound

var _latest_state_str: String = ""
var _latest_index: int = -1


func _ready():
	# basic setup
	current_label.bbcode_enabled = true
	game_board.reset_board()

	target_label.text = "Target: " + game_board.target

	# wire signals
	game_board.update_state.connect(_on_state_updated)
	game_board.update_index.connect(_on_index_updated)
	game_board.solved.connect(_on_board_solved)

	# initial values
	_latest_state_str = game_board.current_display
	_latest_index = game_board.current_index
	_update_display()


func _on_state_updated(_old_state: Array, new_state: Array) -> void:
	_latest_state_str = game_board.arr_to_binstr(new_state)
	_update_display()
	move_sound.play()


func _on_index_updated(_old_index: int, new_index: int) -> void:
	_latest_index = new_index
	_update_display()


func _on_board_solved() -> void:
	if not win_sound.playing:
		win_sound.play()


func _update_display() -> void:
	# ---- Board display ----
	var rich_text = ""
	for i in range(_latest_state_str.length()):
		var bit_char = _latest_state_str[i]
		if i == _latest_index:
			rich_text += "[u]" + bit_char + "[/u]"
		else:
			rich_text += bit_char
	current_label.bbcode_text = "[center]" + rich_text + "[/center]"

	# ---- Info display (visit counters) ----
	if info_label:
		var info_parts: Array[String] = []
		for i in range(game_board.board_size):
			var counter: int = game_board.cell_counters[i]
			var cell_type: int = game_board.cell_types[i]
			var bracket_str: String

			match cell_type:
				GameBoard.CellType.STANDARD:
					bracket_str = str(counter)                # no brackets
				GameBoard.CellType.FLIP_EVERY_N:
					bracket_str = "(" + str(counter) + ")"    # parentheses
				GameBoard.CellType.BLOCKER:
					bracket_str = "{" + str(counter) + "}"    # curly braces
				GameBoard.CellType.EXPLODING:
					bracket_str = "<" + str(counter) + ">"    # angle brackets
				_:
					bracket_str = "?" + str(counter) + "?"

			info_parts.append(bracket_str)

		info_label.text = "[center]" + " ".join(info_parts) + "[/center]"
