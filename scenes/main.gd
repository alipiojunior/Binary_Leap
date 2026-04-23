extends Node

@onready var game_board = $GameBoard
@onready var target_label = $Target
@onready var current_label = $Board

@onready var win_sound = $WinSound
@onready var move_sound = $MoveSound

var _latest_state_str: String = ""
var _latest_index: int = -1

var _bits_durability: Array = []

func _ready():
	current_label.bbcode_enabled = true
	
	game_board.reset_board()
	
	_bits_durability.resize(game_board.target.length())
	_bits_durability.fill(-1) 
	
	_bits_durability[2] = 1 
	
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

func _on_index_updated(old_index, new_index):
	if old_index != -1 and _bits_durability[old_index] > 0:
		_bits_durability[old_index] -= 1
		
		if _bits_durability[old_index] == 0:
			game_board.broken_bits.append(old_index)
	
	_latest_index = new_index
	_update_display()

func _on_board_solved():
	if not win_sound.playing:
		win_sound.play()

func _update_display():
	var rich_text = ""
	
	for i in range(_latest_state_str.length()):
		var bit_char = _latest_state_str[i]
		
		if i == _latest_index:
			# Destaque do jogador (Hubert)
			rich_text += "[u]" + bit_char + "[/u]"
		elif i in game_board.broken_bits:
			# Visual de bit "quebrado" (cinza e riscado)
			rich_text += "[color=gray][s]" + bit_char + "[/s][/color]"
		else:
			# Bit normal
			rich_text += bit_char
	
	var centered_text = "[center]" + rich_text + "[/center]"
	current_label.bbcode_text = centered_text
