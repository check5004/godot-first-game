# res://scripts/autoload/ChartLoader.gd
extends Node

# ロード済み譜面のキャッシュ
var chart_cache: Dictionary = {}

func _ready() -> void:
	print("[ChartLoader] Initialized")

func load_chart(file_path: String) -> Dictionary:
	"""譜面JSONファイルを読み込む"""
	# キャッシュチェック
	if chart_cache.has(file_path):
		return chart_cache[file_path]
	
	# ファイル読み込み
	if not FileAccess.file_exists(file_path):
		push_error("[ChartLoader] File not found: " + file_path)
		return {}
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[ChartLoader] Failed to open file: " + file_path)
		return {}
	
	var json_string := file.get_as_text()
	file.close()
	
	# JSON解析
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("[ChartLoader] JSON Parse Error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return {}
	
	var data: Dictionary = json.data
	
	# バリデーション
	if not validate_chart(data):
		push_error("[ChartLoader] Invalid chart format: " + file_path)
		return {}
	
	# キャッシュに保存
	chart_cache[file_path] = data
	
	print("[ChartLoader] Loaded chart: " + file_path)
	return data

func validate_chart(data: Dictionary) -> bool:
	"""譜面データの妥当性を検証"""
	if not data.has("metadata") or not data.has("notes"):
		return false
	
	var metadata: Dictionary = data["metadata"]
	var required_keys := ["song_title", "artist", "bpm", "offset_sec", "song_path"]
	for key in required_keys:
		if not metadata.has(key):
			push_error("[ChartLoader] Missing metadata key: " + key)
			return false
	
	# ノートの検証
	var notes: Array = data["notes"]
	for note in notes:
		if not note.has("beat") or not note.has("lane"):
			return false
		if note["lane"] < 0 or note["lane"] > 3:
			return false
	
	return true

func save_chart(file_path: String, chart_data: Dictionary) -> Error:
	"""譜面データをJSONファイルに保存"""
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[ChartLoader] Failed to create file: " + file_path)
		return FileAccess.get_open_error()
	
	var json_string := JSON.stringify(chart_data, "  ", false)
	file.store_string(json_string)
	file.close()
	
	# キャッシュ更新
	chart_cache[file_path] = chart_data
	
	print("[ChartLoader] Saved chart: " + file_path)
	return OK

func get_all_charts() -> Array[String]:
	"""利用可能な全譜面ファイルのパスを取得"""
	var charts: Array[String] = []
	var dir := DirAccess.open("res://assets/charts/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				charts.append("res://assets/charts/" + file_name)
			file_name = dir.get_next()
	return charts
