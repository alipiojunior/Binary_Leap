extends Node

@onready var game_board = $GameBoard
@onready var target_label = $Target
@onready var current_label = $Board

@onready var win_sound = $WinSound
@onready var move_sound = $MoveSound

var _latest_state_str: String = ""
var _latest_index: int = -1

func _ready():
	current_label.bbcode_enabled = true
	
	game_board.reset_board()
	
	target_label.text = "Target: " + game_board.target
	
	game_board.update_state.connect(_on_state_updated)
	game_board.update_index.connect(_on_index_updated)
	game_board.solved.connect(_on_board_solved)
	
	_latest_state_str = game_board.current_display
	_latest_index = game_board.current_index
	_update_display()

func _on_state_updated(_old_state, new_state):
	_latest_state_str = game_board.arr_to_binstr(new_state)
	_update_display()
	
	move_sound.play()

func _on_index_updated(_old_index, new_index):
	_latest_index = new_index
	_update_display()

func _on_board_solved():
	if not win_sound.playing:
		win_sound.play()

func _update_display():
	var rich_text = ""
	if _latest_index >= 0 and _latest_index < _latest_state_str.length():
		rich_text = _latest_state_str.substr(0, _latest_index) + \
					"[u]" + _latest_state_str[_latest_index] + "[/u]" + \
					_latest_state_str.substr(_latest_index + 1)
	else:
		rich_text = _latest_state_str
	
	var centered_text = "[center]" + rich_text + "[/center]"
	
	current_label.bbcode_text = centered_text
