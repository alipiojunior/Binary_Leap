extends Node

@onready var game_board: GameBoard = $GameBoard
@onready var target_label = $Target
@onready var board = $Board
@onready var info_label = $Info
@onready var win_sound = $WinSound
@onready var move_sound = $MoveSound

func _ready():
	game_board.reset_board()
	board.init_board(game_board)
	target_label.text = "Target: " + game_board.target

	game_board.solved.connect(_on_board_solved)
	game_board.update_state.connect(_on_state_updated)
	game_board.update_index.connect(_on_index_updated)

func _on_state_updated(_old_state, new_state: Array):
	_update_info_label()
	move_sound.play()

func _on_index_updated(_old_index: int, _new_index: int):
	_update_info_label()

func _on_board_solved():
	if not win_sound.playing:
		win_sound.play()

func _update_info_label():
	if not info_label:
		return
	var parts: Array[String] = []
	for i in game_board.board_size:
		var c = game_board.cell_counters[i]
		var t = game_board.cell_types[i]
		var s: String
		match t:
			GameBoard.CellType.STANDARD:       s = str(c)
			GameBoard.CellType.FLIP_EVERY_N:   s = "(" + str(c) + ")"
			GameBoard.CellType.BLOCKER:        s = "{" + str(c) + "}"
			GameBoard.CellType.EXPLODING:      s = "<" + str(c) + ">"
			_:                                 s = "?" + str(c) + "?"
		parts.append(s)
	info_label.text = "[center]" + " ".join(parts) + "[/center]"
