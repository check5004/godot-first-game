# res://scripts/autoload/ScoreManager.gd
extends Node

# ===== シグナル =====
signal score_updated(new_score: int)
signal combo_changed(new_combo: int)
signal judgement_made(judgement: String, delta_time: float)
signal accuracy_updated(accuracy: float)

# ===== 状態変数 =====
var current_score: int = 0
var current_combo: int = 0
var max_combo: int = 0

# 統計
var judgement_counts: Dictionary = {
	"PERFECT": 0,
	"GOOD": 0,
	"OK": 0,
	"MISS": 0
}

var total_notes: int = 0

func _ready() -> void:
	print("[ScoreManager] Initialized")

func reset_game() -> void:
	"""ゲーム開始時にリセット"""
	current_score = 0
	current_combo = 0
	max_combo = 0
	judgement_counts = {
		"PERFECT": 0,
		"GOOD": 0,
		"OK": 0,
		"MISS": 0
	}
	score_updated.emit(0)
	combo_changed.emit(0)

func add_judgement(judgement: String, delta_time: float) -> void:
	"""判定を追加してスコアを計算"""
	judgement_counts[judgement] += 1
	
	if judgement == "MISS":
		current_combo = 0
	else:
		current_combo += 1
		max_combo = max(max_combo, current_combo)
	
	# スコア計算（コンボ倍率適用）
	var base_score := 0
	match judgement:
		"PERFECT": base_score = GameConfig.SCORE_PERFECT
		"GOOD": base_score = GameConfig.SCORE_GOOD
		"OK": base_score = GameConfig.SCORE_OK
		"MISS": base_score = GameConfig.SCORE_MISS
	
	var multiplier := GameConfig.get_combo_multiplier(current_combo)
	var final_score := int(base_score * multiplier)
	current_score += final_score
	
	# シグナル発火
	score_updated.emit(current_score)
	combo_changed.emit(current_combo)
	judgement_made.emit(judgement, delta_time)
	
	# 精度計算
	var total := float(judgement_counts.values().reduce(func(a, b): return a + b, 0))
	if total > 0:
		var accuracy := (judgement_counts["PERFECT"] + judgement_counts["GOOD"] * 0.7 + judgement_counts["OK"] * 0.4) / total * 100.0
		accuracy_updated.emit(accuracy)

func get_accuracy() -> float:
	"""現在の精度（%）を取得"""
	var total := float(judgement_counts.values().reduce(func(a, b): return a + b, 0))
	if total == 0:
		return 0.0
	return (judgement_counts["PERFECT"] + judgement_counts["GOOD"] * 0.7 + judgement_counts["OK"] * 0.4) / total * 100.0

func get_grade() -> String:
	"""精度に基づいてグレードを返す"""
	var acc := get_accuracy()
	if acc >= 95.0:
		return "S"
	elif acc >= 90.0:
		return "A"
	elif acc >= 80.0:
		return "B"
	elif acc >= 70.0:
		return "C"
	else:
		return "D"
