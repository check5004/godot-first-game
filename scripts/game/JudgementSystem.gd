extends Node

## タイミング判定スクリプト
## 責務: 入力タイミングとノート到達時刻の差分を計算し、判定を決定

# 状態
var current_time: float = 0.0
var note_spawner: Node = null

## 初期化
## 事前条件: InputHandlerが同じシーンツリー内に存在
## 事後条件: input_receivedシグナルに接続完了
func _ready() -> void:
	# InputHandlerのシグナルに接続
	var input_handler = get_node_or_null("../InputHandler")
	if input_handler:
		input_handler.input_received.connect(_on_input_received)
	else:
		push_error("InputHandler not found")

	# NoteSpawnerの参照を取得
	note_spawner = get_node_or_null("../NoteSpawner")
	if not note_spawner:
		push_error("NoteSpawner not found")

## 時刻更新
## 事前条件: time >= 0.0
## 事後条件: current_time更新
func update_time(time: float) -> void:
	current_time = time

## 入力受信ハンドラ
## 事前条件: lane_index in [0, 1, 2, 3], note_spawner != null
## 事後条件:
##   - レーンにノートあり → 判定処理実行、ScoreManager通知、ノートヒット処理
##   - レーンにノートなし → 何もしない
func _on_input_received(lane_index: int) -> void:
	if note_spawner == null:
		return

	# 対象レーンのアクティブノートを取得
	var lane_notes = note_spawner.get_notes_in_lane(lane_index)

	# レーンにノートがない場合は処理終了（ペナルティなし）
	if lane_notes.is_empty():
		return

	# 判定ラインに最も近いノートを特定
	var closest_note: Node = null
	var min_distance: float = INF

	for note in lane_notes:
		if note.is_hit:
			continue

		var distance = abs(note.target_time_sec - current_time)
		if distance < min_distance:
			min_distance = distance
			closest_note = note

	# 有効なノートがない場合は処理終了
	if closest_note == null:
		return

	# タイミング差分を計算
	var delta_time: float = closest_note.target_time_sec - current_time
	var abs_delta: float = abs(delta_time)

	# 判定ウィンドウと比較
	var judgement: String = ""

	if abs_delta <= GameConfig.PERFECT_WINDOW:
		judgement = "PERFECT"
	elif abs_delta <= GameConfig.GOOD_WINDOW:
		judgement = "GOOD"
	elif abs_delta <= GameConfig.OK_WINDOW:
		judgement = "OK"
	else:
		# ウィンドウ外（無視）
		return

	# 判定成功時のログ（デバッグ用）
	print("Lane %d: %s (delta: %.3fs)" % [lane_index, judgement, delta_time])

	# ScoreManagerに判定結果を通知
	ScoreManager.add_judgement(judgement, delta_time)

	# ノートのヒット処理を呼び出し
	closest_note.hit(judgement)
