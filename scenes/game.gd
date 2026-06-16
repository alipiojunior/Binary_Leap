extends Node

signal level_cleared(record: ClearRecord)

@onready var game_board = $GameBoard
@onready var target_label = $Target
@onready var current_label = $Board
@onready var move_label = $MoveCounter
@onready var win_sound = $WinSound
@onready var move_sound = $MoveSound
@onready var instructions = $Instructions
@onready var finish_menu = $FinishMenu

var _latest_state_str: String = ""
var _latest_index: int = -1

var _level_queue: Array = []
var _current_pack: String = ""
var _current_level_name: String = ""
var _level_start_time: float = 0.0

var _leaderboard_labels: Array = []
var _name_input: LineEdit = null
var _pending_record: ClearRecord = null

var _solved = false

func queue_pack(pack_name: String) -> void:
	_current_pack = pack_name
	_level_queue = LevelManager.get_level_names(pack_name)

func next_level() -> bool:
	if _level_queue.is_empty():
		return false
	load_level(_current_pack, _level_queue.pop_front())
	return true

func load_level(pack_name: String, level_name: String) -> void:
	_solved = false
	
	var spec: LevelSpec = LevelManager.get_level(pack_name, level_name)
	if spec == null:
		push_error("Game: level not found - %s / %s" % [pack_name, level_name])
		return
 	
	game_board.board_definition = spec.definition
	game_board.target = spec.target
	game_board.starting_index = spec.start_index
	game_board.move_budget = spec.budget
 	
	if level_name != "Tutorial":
		instructions.visible = false
	
	game_board.reset_board()
	_current_level_name = level_name
	_level_start_time = Time.get_ticks_msec() / 1000.0
	_sync_display()

func _process(_delta) -> void:
	if _solved:
		if Input.is_action_just_pressed("main_menu"):
			_on_back_pressed()
		if Input.is_action_just_pressed("retry"):
			_on_retry_pressed()
		if Input.is_action_just_pressed("next_level"):
			_on_next_level_pressed()
		if Input.is_action_just_pressed("toggle_menu"):
			finish_menu.visible = !finish_menu.visible

func _ready() -> void:
	current_label.bbcode_enabled = true
	target_label.bbcode_enabled = true
	move_label.bbcode_enabled = true
	
	game_board.update_state.connect(_on_state_updated)
	game_board.update_index.connect(_on_index_updated)
	game_board.move_count_changed.connect(_on_move_count_changed)
	game_board.solved.connect(_on_board_solved)
	level_cleared.connect(_on_level_cleared)
	
	_build_finish_menu()
	finish_menu.hide()
	
	var pack := LevelManager.load_pack("res://assets/levels/tutorial.lvl")
	if pack:
		queue_pack(pack.pack_name)
		next_level()
		return
	
	# Fallback: use whatever @export values are set in the editor.
	game_board.reset_board()
	_latest_state_str = game_board.current_display
	_latest_index = game_board.current_index
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
	var record := ClearRecord.new()
	record.level_name = _current_level_name
	record.move_count = game_board.move_count
	record.move_budget = game_board.move_budget
	record.clear_time = (Time.get_ticks_msec() / 1000.0) - _level_start_time
	LevelManager.submit_clear(record)
	level_cleared.emit(record)
	
	var text = move_label.get_parsed_text()
	move_label.bbcode_text = "[center]" + text + " | Clear!" + "[/center]"
	
	for r in LevelManager.get_records_for(_current_level_name):
		print("clear - level: %s  moves: %d/%d  time: %.2fs  name: '%s'" \
		% [r.level_name, r.move_count, r.move_budget, r.clear_time, r.player_name])
	
	if not win_sound.playing:
		win_sound.play()
	
	_solved = true

func _sync_display() -> void:
	target_label.bbcode_text = "[center]" + game_board.target + "[/center]"
	_latest_state_str = game_board.current_display
	_latest_index = game_board.current_index
	_update_display()
	_update_move_label()

func _update_move_label() -> void:
	var count: int = game_board.move_count
	var budget: int = game_board.move_budget
	var text := str(count) if budget == 0 else str(count) + " / " + str(budget)
	if not _solved:
		move_label.bbcode_text = "[center]" + text + "[/center]"
	else:
		move_label.bbcode_text = "[center]" + text + " | Solved!" + "[/center]"

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

func _build_finish_menu() -> void:
	var vbox := $FinishMenu/MarginContainer/Panel/VBoxContainer
	
	for i in 5:
		var row := Label.new()
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(row)
		_leaderboard_labels.append(row)
	
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Enter name (optional)"
	_name_input.text_submitted.connect(func(_t): _apply_pending_name())
	vbox.add_child(_name_input)
	
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons)
	
	var back_btn := Button.new()
	back_btn.text = "(M)ain Menu"
	back_btn.pressed.connect(_on_back_pressed)
	buttons.add_child(back_btn)
	
	var retry_btn := Button.new()
	retry_btn.text = "(R)etry"
	retry_btn.pressed.connect(_on_retry_pressed)
	buttons.add_child(retry_btn)
	
	var next_btn := Button.new()
	next_btn.text = "(N)ext Level"
	next_btn.pressed.connect(_on_next_level_pressed)
	buttons.add_child(next_btn)

func _on_level_cleared(record: ClearRecord) -> void:
	_pending_record = record
	_name_input.text = ""
	_populate_leaderboard(record.level_name)
	finish_menu.show()

func _populate_leaderboard(level_name: String) -> void:
	var records := LevelManager.get_records_for(level_name)
	records.sort_custom(func(a, b): return a.clear_time < b.clear_time)
	for i in 5:
		if i < records.size():
			var r: ClearRecord = records[i]
			var name_str = r.player_name if not r.player_name.is_empty() else "---"
			_leaderboard_labels[i].text = "%d.  %-10s  %d moves  %.2fs" \
				% [i + 1, name_str, r.move_count, r.clear_time]
		else:
			_leaderboard_labels[i].text = "%d.  —" % (i + 1)

func _apply_pending_name() -> void:
	move_sound.play()
	if _pending_record == null:
		return
	var entered = _name_input.text.strip_edges()
	if not entered.is_empty():
		_pending_record.player_name = entered
		LevelManager.save_clears()
		_populate_leaderboard(_pending_record.level_name)
	_pending_record = null

func _on_back_pressed() -> void:
	_apply_pending_name()
	finish_menu.hide()
	# get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_retry_pressed() -> void:
	_apply_pending_name()
	finish_menu.hide()
	load_level(_current_pack, _current_level_name)

func _on_next_level_pressed() -> void:
	_apply_pending_name()
	finish_menu.hide()
	if not next_level():
		pass # TODO: update this to move between screens.
