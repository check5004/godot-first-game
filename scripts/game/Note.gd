extends Area2D

## ノート個体スクリプト
## 責務: 自己の移動、視覚表現、ヒット/Miss時の処理

# プロパティ
var lane_index: int = 0              # レーン番号（0-3）
var target_time_sec: float = 0.0     # 判定ライン到達予定時刻（秒）
var is_hit: bool = false             # ヒット済みフラグ

# ノード参照
@onready var sprite := $Sprite2D as Sprite2D

# レーン別カラー定義
const LANE_COLORS = [
	Color(1.0, 0.2, 0.2),  # 0: 赤
	Color(0.2, 0.5, 1.0),  # 1: 青
	Color(0.2, 1.0, 0.3),  # 2: 緑
	Color(1.0, 0.9, 0.2)   # 3: 黄
]

func _ready() -> void:
	# レーンに応じた色設定
	if lane_index >= 0 and lane_index < LANE_COLORS.size():
		sprite.modulate = LANE_COLORS[lane_index]

func _process(delta: float) -> void:
	# ヒット済みの場合は移動しない
	if is_hit:
		return

	# NOTE_SPEEDに従って下方向に移動
	position.y += GameConfig.NOTE_SPEED * delta

	# Miss判定: 判定ライン通過後100px地点
	if position.y > GameConfig.JUDGEMENT_LINE_Y + 100.0:
		_miss()

## ヒット処理
## 事前条件: judgement in ["PERFECT", "GOOD", "OK"], is_hit == false
## 事後条件: is_hit = true, ノート削除予約
func hit(_judgement: String) -> void:
	if is_hit:
		return

	is_hit = true
	# 即座に削除（Phase 2でjudgementに応じたアニメーション実装予定）
	queue_free()

## Miss処理（内部メソッド）
## 事前条件: is_hit == false
## 事後条件: ScoreManager.add_judgement("MISS", 0.0)呼び出し、削除
func _miss() -> void:
	if is_hit:
		return

	is_hit = true
	ScoreManager.add_judgement("MISS", 0.0)
	queue_free()
