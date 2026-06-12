extends Node

@onready var game_board = $GameBoard
@onready var target_label = $Target
@onready var current_label = $Board
@onready var move_label = $MoveCounter
@onready var win_sound = $WinSound
@onready var move_sound = $MoveSound

var _latest_state_str: String = ""
var _latest_index: int = -1

func _ready() -> void:
	current_label.bbcode_enabled = true
	target_label.bbcode_enabled = true
	move_label.bbcode_enabled = true
	
	game_board.update_state.connect(_on_state_updated)
	game_board.update_index.connect(_on_index_updated)
	game_board.move_count_changed.connect(_on_move_count_changed)
	game_board.solved.connect(_on_board_solved)
	
	var pack := LevelManager.load_pack("res://assets/levels/tutorial.lvl")
	if pack and not pack.get_level_names().is_empty():
		load_level(pack.pack_name, pack.get_level_names()[0])
		return
	
	# Fallback: use whatever @export values are set in the editor.
	game_board.reset_board()
	_latest_state_str = game_board.current_display
	_latest_index     = game_board.current_index
	target_label.bbcode_text = "[center]" + game_board.target + "[/center]"
	_update_display()
	_update_move_label()

func _on_state_updated(_old_state: Array, new_state: Array) -> void:
	_latest_state_str = game_board.arr_to_binstr(new_state)
	_update_display()
	move_sound.play()

func _on_index_updated(_old_index: int, new_index: int) -> void:
	_latest_index = new_index
	_update_display()

func _on_move_count_changed(_count: int) -> void:
	_update_move_label()

func _on_board_solved() -> void:
	if not win_sound.playing:
		win_sound.play()

func load_level(pack_name: String, level_name: String) -> void:
	var spec: LevelSpec = LevelManager.get_level(pack_name, level_name)
	if spec == null:
		push_error("Game: level not found - %s / %s" % [pack_name, level_name])
		return
 
	game_board.board_definition = spec.definition
	game_board.target = spec.target
	game_board.starting_index = spec.start_index
	game_board.move_budget = spec.budget
 
	game_board.reset_board()
	_sync_display()
 
func _sync_display() -> void:
	target_label.bbcode_text = "[center]" + game_board.target + "[/center]"
	_latest_state_str = game_board.current_display
	_latest_index     = game_board.current_index
	_update_display()
	_update_move_label()

func _update_move_label() -> void:
	var count: int = game_board.move_count
	var budget: int = game_board.move_budget
	var text := str(count) if budget == 0 else str(count) + " / " + str(budget)
	move_label.bbcode_text = "[center]" + text + "[/center]"

func _update_display() -> void:
	var rich_text = ""
	for i in range(_latest_state_str.length()):
		var bit_char = _latest_state_str[i]
		var cell_type = game_board.cell_types[i]

		if cell_type == GameBoard.CellType.DELAYED:
			var struck = game_board.cell_counters[i] % 2 == 0
			if struck:
				bit_char = "[s]" + bit_char + "[/s]"
		if i == _latest_index:
			bit_char = "[u]" + bit_char + "[/u]"

		rich_text += bit_char

	current_label.bbcode_text = "[center]" + rich_text + "[/center]"
