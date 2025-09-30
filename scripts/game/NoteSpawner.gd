extends Node2D

## ノート生成管理スクリプト
## 責務: 譜面データを解析し、適切なタイミングでノートを生成・管理

# ノートシーンのプリロード
const NOTE_SCENE: PackedScene = preload("res://scenes/Note.tscn")

# データ
var chart_data: Dictionary = {}
var note_queue: Array[Dictionary] = []
var active_notes: Array[Node] = []

# 設定
var spawn_lead_time: float = 2.0  # ノート先行生成時間（秒）

## 譜面データ設定
## 事前条件: chart_dataに有効なmetadata（bpm, offset_sec）とnotesを含む
## 事後条件: note_queue準備完了（beat→時刻変換済み、時刻順ソート済み）
func set_chart_data(data: Dictionary) -> void:
	chart_data = data
	_prepare_note_queue()

## ノートキュー準備（内部メソッド）
## 事前条件: chart_dataセット済み
## 事後条件: note_queue内の全ノートに対してtarget_time計算完了
func _prepare_note_queue() -> void:
	note_queue.clear()

	if not chart_data.has("metadata") or not chart_data.has("notes"):
		push_error("Invalid chart data")
		return

	var metadata = chart_data["metadata"]
	var bpm: float = metadata.get("bpm", 120.0)
	var offset_sec: float = metadata.get("offset_sec", 0.0)

	# 各ノートのbeat値をtarget_time（秒）に変換
	for note in chart_data["notes"]:
		var beat: float = note.get("beat", 0.0)
		var lane: int = note.get("lane", 0)

		# target_time計算: offset_sec + (beat / bpm) * 60.0
		var target_time: float = offset_sec + (beat / bpm) * 60.0

		note_queue.append({
			"target_time": target_time,
			"lane": lane,
			"spawned": false
		})

	# 時刻順にソート
	note_queue.sort_custom(func(a, b): return a["target_time"] < b["target_time"])

	print("Note queue prepared: %d notes" % note_queue.size())

## 時刻更新とノート生成
## 事前条件: note_queue準備済み
## 事後条件: 生成条件を満たすノートがインスタンス化され、シーンツリーに追加
func update_time(current_time: float) -> void:
	# ノートキューをチェックして生成タイミングに達したノートを生成
	for note_info in note_queue:
		if note_info["spawned"]:
			continue

		var spawn_time = note_info["target_time"] - spawn_lead_time

		# 生成判定: current_time >= (target_time - spawn_lead_time)
		if current_time >= spawn_time:
			_spawn_note(note_info)
			note_info["spawned"] = true
		else:
			# ソート済みなので、まだ時刻に達していなければ後続もスキップ
			break

	# アクティブノート配列のクリーンアップ（削除済みノードを除外）
	active_notes = active_notes.filter(func(n): return is_instance_valid(n))

## ノート生成（内部メソッド）
## 事前条件: note_infoに有効なtarget_time, laneを含む
## 事後条件: Noteインスタンス生成、プロパティ設定、add_child、active_notes追加
func _spawn_note(note_info: Dictionary) -> void:
	var note := NOTE_SCENE.instantiate() as Area2D

	if note == null:
		push_error("Failed to instantiate note")
		return

	# プロパティ設定
	note.lane_index = note_info["lane"]
	note.target_time_sec = note_info["target_time"]

	# 初期位置設定
	var lane_x: float = GameConfig.LANE_POSITIONS[note.lane_index]
	note.position = Vector2(lane_x, -50.0)  # 画面外上部

	# シーンツリーに追加
	add_child(note)
	active_notes.append(note)

## アクティブノート数取得
## 事前条件: なし
## 事後条件: 現在シーンツリーに存在するノート数を返す
func get_active_note_count() -> int:
	return active_notes.size()

## レーン内ノート取得
## 事前条件: lane in [0, 1, 2, 3]
## 事後条件: 指定レーンのアクティブノート配列を返す
func get_notes_in_lane(lane: int) -> Array[Node]:
	var lane_notes: Array[Node] = []
	for note in active_notes:
		if is_instance_valid(note) and note.lane_index == lane:
			lane_notes.append(note)
	return lane_notes
