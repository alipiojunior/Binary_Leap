class_name ClearData
extends Resource

@export var records: Array[ClearRecord] = []

func get_records_for(level_name: String) -> Array[ClearRecord]:
	return records.filter(func(r): return r.level_name == level_name)
