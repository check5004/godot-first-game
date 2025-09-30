extends CanvasLayer

## UI更新管理スクリプト
## 責務: ScoreManagerのシグナルを購読し、スコア・コンボ・判定結果を画面に表示

# ノード参照
@onready var score_label := $ScoreLabel as Label
@onready var combo_label := $ComboLabel as Label

## 初期化
## 事前条件: ScoreManagerがAutoLoad登録済み
## 事後条件: 全シグナル接続完了
func _ready() -> void:
	# ScoreManagerのシグナルに接続
	ScoreManager.score_updated.connect(_on_score_updated)
	ScoreManager.combo_changed.connect(_on_combo_changed)

	# 初期表示
	_on_score_updated(0)
	_on_combo_changed(0)

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
