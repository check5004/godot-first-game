extends CanvasLayer

## UI更新管理スクリプト
## 責務: ScoreManagerのシグナルを購読し、スコア・コンボ・判定結果を画面に表示

# ノード参照
@onready var score_label := $ScoreLabel as Label
@onready var combo_label := $ComboLabel as Label
@onready var judgement_label := $JudgementLabel as Label
@onready var accuracy_label := $AccuracyLabel as Label
@onready var grade_label := $GradeLabel as Label
@onready var debug_display := $DebugDisplay as Label

# アニメーション管理
var current_judgement_tween: Tween = null

## 初期化
## 事前条件: ScoreManagerがAutoLoad登録済み
## 事後条件: 全シグナル接続完了
func _ready() -> void:
	# ScoreManagerのシグナルに接続
	ScoreManager.score_updated.connect(_on_score_updated)
	ScoreManager.combo_changed.connect(_on_combo_changed)
	ScoreManager.judgement_made.connect(_on_judgement_made)
	ScoreManager.accuracy_updated.connect(_on_accuracy_updated)

	# 初期表示
	_on_score_updated(0)
	_on_combo_changed(0)

	# 判定ラベルは非表示
	if judgement_label:
		judgement_label.visible = false

	# 精度ラベルは初期値表示
	if accuracy_label:
		accuracy_label.text = "Accuracy: 0.0%"

	# グレードラベルは非表示
	if grade_label:
		grade_label.visible = false

## スコア更新ハンドラ
## 事前条件: new_score >= 0
## 事後条件: score_label.text更新
func _on_score_updated(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % new_score

## コンボ更新ハンドラ
## 事前条件: new_combo >= 0
## 事後条件: combo_label表示更新（コンボ0時は非表示）
func _on_combo_changed(new_combo: int) -> void:
	if combo_label == null:
		return

	if new_combo > 0:
		combo_label.text = "%d COMBO" % new_combo
		combo_label.visible = true
	else:
		combo_label.visible = false

## 判定更新ハンドラ
## 事前条件: judgementが"PERFECT"/"GOOD"/"OK"/"MISS"のいずれか
## 事後条件: 判定表示更新、色設定、フェードアウトアニメーション開始
func _on_judgement_made(judgement: String, _delta_time: float) -> void:
	if judgement_label == null:
		return

	# 既存のTweenアニメーションを停止
	if current_judgement_tween != null and is_instance_valid(current_judgement_tween):
		current_judgement_tween.kill()

	# 判定テキストと色を設定
	judgement_label.text = judgement
	judgement_label.modulate = _get_judgement_color(judgement)
	judgement_label.visible = true

	# フェードアウトアニメーション（0.5秒）
	current_judgement_tween = create_tween()
	current_judgement_tween.tween_property(judgement_label, "modulate:a", 0.0, 0.5)
	current_judgement_tween.finished.connect(_on_judgement_fade_complete)

## 判定フェードアウト完了ハンドラ
func _on_judgement_fade_complete() -> void:
	if judgement_label:
		judgement_label.visible = false
		judgement_label.modulate.a = 1.0  # 透明度をリセット

## 精度更新ハンドラ
## 事前条件: 0.0 <= accuracy <= 100.0
## 事後条件: accuracy_label.text更新、grade_label更新
func _on_accuracy_updated(accuracy: float) -> void:
	if accuracy_label == null or grade_label == null:
		return

	# 精度をクランプして表示
	var clamped_accuracy := clampf(accuracy, 0.0, 100.0)
	accuracy_label.text = "Accuracy: %.1f%%" % clamped_accuracy

	# グレード取得と表示
	var grade := ScoreManager.get_grade()
	grade_label.text = grade
	grade_label.modulate = _get_grade_color(grade)
	grade_label.visible = true

## 判定色取得ヘルパー
## 事前条件: judgementが"PERFECT"/"GOOD"/"OK"/"MISS"のいずれか
## 事後条件: 対応するColorオブジェクトを返す
func _get_judgement_color(judgement: String) -> Color:
	match judgement:
		"PERFECT": return Color.GOLD
		"GOOD": return Color.LIME_GREEN
		"OK": return Color.ORANGE
		"MISS": return Color.RED
		_: return Color.WHITE  # デフォルト

## グレード色取得ヘルパー
## 事前条件: gradeが"S"/"A"/"B"/"C"/"D"のいずれか
## 事後条件: 対応するColorオブジェクトを返す
func _get_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color.GOLD
		"A": return Color.LIME_GREEN
		"B": return Color.CYAN
		"C": return Color.ORANGE
		"D": return Color.RED
		_: return Color.WHITE  # デフォルト

## デバッグ情報更新（毎フレーム）
## 事前条件: GameConfig.debug_mode定義済み
## 事後条件: debug_mode=trueの場合のみdebug_display.text更新
func _process(_delta: float) -> void:
	# デバッグモード無効時は処理スキップ
	if not GameConfig.debug_mode:
		if debug_display:
			debug_display.visible = false
		return

	# デバッグ表示が存在しない場合はスキップ
	if debug_display == null:
		return

	# デバッグ表示を有効化
	debug_display.visible = true

	# Game.gdノード参照を取得
	var game = get_node_or_null("../")
	if game == null:
		debug_display.text = "Time: N/A\nFPS: N/A\nLatency: N/A\nActive Notes: N/A"
		return

	# パフォーマンス指標を取得
	var fps := Engine.get_frames_per_second()
	var latency_ms := AudioServer.get_output_latency() * 1000.0

	# Game.gdから時刻を取得
	var precise_time: float = game.precise_time_sec if "precise_time_sec" in game else 0.0

	# NoteSpawnerからアクティブノート数を取得
	var note_spawner = game.get_node_or_null("NoteSpawner")
	var active_notes: int = 0
	if note_spawner and note_spawner.has_method("get_active_note_count"):
		active_notes = note_spawner.get_active_note_count()

	# デバッグ情報を表示
	debug_display.text = "Time: %.3f\nFPS: %d\nLatency (ms): %.1f\nActive Notes: %d" % [
		precise_time,
		fps,
		latency_ms,
		active_notes
	]
