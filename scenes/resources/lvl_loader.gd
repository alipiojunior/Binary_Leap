class_name LvlLoader
extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["lvl"])

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, &"Resource")

func _get_resource_type(path: String) -> String:
	return "Resource" if path.get_extension().to_lower() == "lvl" else ""

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LvlFormatLoader: cannot open '%s' (error %d)" % [path, FileAccess.get_open_error()])
		return ERR_FILE_NOT_FOUND
	
	var source := file.get_as_text()
	file.close()
	
	var pack := _parse(source)
	if pack == null:
		return ERR_PARSE_ERROR
	
	pack.resource_path = path
	return pack

var _src: String = ""
var _pos: int    = 0

func _parse(source: String) -> LevelPack:
	_src = source
	_pos = 0
	
	_skip_whitespace()
	if _pos >= _src.length():
		push_error("LvlFormatLoader: file is empty")
		return null
	
	# Outer block = the pack name
	var name := _read_identifier()
	if name.is_empty():
		push_error("LvlFormatLoader: expected pack name at pos %d" % _pos)
		return null
	
	_skip_whitespace()
	if not _expect('{'):
		return null
	
	var pack := LevelPack.new()
	pack.pack_name = name
	
	while _pos < _src.length():
		_skip_whitespace()
		if _pos >= _src.length():
			break
		if _src[_pos] == '}':
			_pos += 1
			break
		
		var level_name := _read_identifier()
		if level_name.is_empty():
			push_error("LvlFormatLoader: expected level name at pos %d" % _pos)
			break
		
		_skip_whitespace()
		if not _expect('{'):
			break
		
		var spec := _parse_level()
		pack.levels[level_name] = spec
	
	return pack


func _parse_level() -> LevelSpec:
	var spec := LevelSpec.new()
	
	while _pos < _src.length():
		_skip_whitespace()
		if _pos >= _src.length():
			break
		if _src[_pos] == '}':
			_pos += 1
			break
		
		var key := _read_identifier()
		if key.is_empty():
			push_error("LvlFormatLoader: expected key at pos %d" % _pos)
			break
		
		_skip_whitespace()
		if not _expect(':'):
			break
		
		_skip_inline_whitespace()
		var value := _read_to_eol()

		match key:
			"Def":      spec.definition  = value
			"Target":   spec.target      = value
			"StartIdx": spec.start_index = int(value)
			"Budget":   spec.budget      = int(value)
			_:          push_warning("LvlFormatLoader: unknown key '%s' - ignored" % key)
	
	return spec

func _is_word_char(c: String) -> bool:
	var code := c.unicode_at(0)
	var is_az := (code >= 97 and code <= 122)
	var is_AZ := (code >= 65 and code <= 90)
	var is_09 := (code >= 48 and code <= 57)
	var is_underline := code == 95
	
	return is_az or is_AZ or is_09 or is_underline

func _skip_whitespace() -> void:
	while _pos < _src.length() and _src[_pos] in [' ', '\t', '\n', '\r']:
		_pos += 1

func _skip_inline_whitespace() -> void:
	while _pos < _src.length() and _src[_pos] in [' ', '\t']:
		_pos += 1

func _read_identifier() -> String:
	var start := _pos
	while _pos < _src.length() and _is_word_char(_src[_pos]):
		_pos += 1
	return _src.substr(start, _pos - start)

func _read_to_eol() -> String:
	var start := _pos
	while _pos < _src.length() and _src[_pos] not in ['\n', '\r']:
		_pos += 1
	return _src.substr(start, _pos - start).strip_edges()

func _expect(ch: String) -> bool:
	if _pos >= _src.length() or _src[_pos] != ch:
		push_error("LvlFormatLoader: expected '%s' at pos %d (got '%s')" \
			% [ch, _pos, _src[_pos] if _pos < _src.length() else "EOF"])
		return false
	_pos += 1
	return true
