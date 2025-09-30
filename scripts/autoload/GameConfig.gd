# res://scripts/autoload/GameConfig.gd
extends Node

# ===== タイミング判定ウィンドウ（秒） =====
const PERFECT_WINDOW: float = 0.025  # ±25ms
const GOOD_WINDOW: float = 0.050     # ±50ms
const OK_WINDOW: float = 0.080       # ±80ms
const MISS_WINDOW: float = 0.150     # ±150ms（これ以上は無視）

# ===== スコアリング =====
const SCORE_PERFECT: int = 100
const SCORE_GOOD: int = 70
const SCORE_OK: int = 40
const SCORE_MISS: int = 0

# コンボボーナス（コンボ数に応じた倍率）
const COMBO_MULTIPLIER: Dictionary = {
	10: 1.1,   # 10コンボで1.1倍
	25: 1.2,   # 25コンボで1.2倍
	50: 1.5,   # 50コンボで1.5倍
	100: 2.0   # 100コンボで2.0倍
}

# ===== ノート設定 =====
const NOTE_SPEED: float = 600.0  # pixels per second
const JUDGEMENT_LINE_Y: float = 600.0  # 判定ラインのY座標

# ===== キーマッピング =====
const KEY_MAPPINGS: Dictionary = {
	0: KEY_D,
	1: KEY_F,
	2: KEY_J,
	3: KEY_K
}

# レーン位置（X座標）
const LANE_POSITIONS: Array[float] = [400.0, 520.0, 640.0, 760.0]

# ===== 難易度設定 =====
enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	EXPERT
}

const DIFFICULTY_NAMES: Dictionary = {
	Difficulty.EASY: "Easy",
	Difficulty.NORMAL: "Normal",
	Difficulty.HARD: "Hard",
	Difficulty.EXPERT: "Expert"
}

# ===== デバッグ設定 =====
var debug_mode: bool = false

func _ready() -> void:
	print("[GameConfig] Initialized")

func get_combo_multiplier(combo: int) -> float:
	"""現在のコンボ数に対する倍率を取得"""
	var multiplier := 1.0
	for threshold in COMBO_MULTIPLIER.keys():
		if combo >= threshold:
			multiplier = COMBO_MULTIPLIER[threshold]
	return multiplier

func get_judgement_window(judgement: String) -> float:
	"""判定種別に対応するウィンドウ時間を取得"""
	match judgement:
		"PERFECT": return PERFECT_WINDOW
		"GOOD": return GOOD_WINDOW
		"OK": return OK_WINDOW
		"MISS": return MISS_WINDOW
		_: return 0.0
