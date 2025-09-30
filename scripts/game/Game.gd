extends Node2D

## メインゲームコントローラー
## 責務: ゲーム全体のライフサイクル管理、音楽再生制御、時間同期計算、各システムへの時刻配信

# 状態
var precise_time_sec: float = 0.0
var current_chart: Dictionary = {}
var debug_mode: bool = false

# ノード参照
@onready var music_player := $MusicPlayer as AudioStreamPlayer
@onready var note_spawner := $NoteSpawner as Node2D
@onready var judgement_system := $JudgementSystem as Node
@onready var ui := $UI as CanvasLayer
@onready var debug_display := $UI/DebugDisplay as Label

## 初期化処理
## 事前条件: ChartLoader, ScoreManagerがAutoLoad登録済み
## 事後条件: 譜面読み込み完了、音楽再生開始
func _ready() -> void:
	# 譜面データ読み込み
	current_chart = ChartLoader.load_chart("res://assets/charts/test_song.json")

	# 譜面データが空の場合はエラー
	if current_chart.is_empty():
		push_error("Failed to load chart")
		return

	# ScoreManagerをリセット
	ScoreManager.reset_game()

	# 各システムに譜面データを設定
	note_spawner.set_chart_data(current_chart)

	# 音楽ファイルをロード
	var audio_path: String = current_chart["metadata"].get("song_path", "")
	if audio_path.is_empty():
		push_error("No audio path in chart")
		return

	var audio_stream = load(audio_path) as AudioStream
	if audio_stream == null:
		push_error("Failed to load audio: " + audio_path)
		return

	music_player.stream = audio_stream

	# デバッグ表示の初期化
	if debug_display:
		debug_display.visible = debug_mode

	# 短い遅延後に音楽再生開始
	await get_tree().create_timer(0.5).timeout
	music_player.play()

	print("Game started")

## 毎フレーム処理
## 事前条件: 音楽が再生中
## 事後条件: precise_time_sec更新、各システムに時刻配信
func _process(_delta: float) -> void:
	# 音楽が再生中でない場合は処理しない
	if not music_player.playing:
		return

	# 高精度時間計算
	precise_time_sec = music_player.get_playback_position() + \
	                   AudioServer.get_time_since_last_mix() - \
	                   AudioServer.get_output_latency()

	# 各システムに時刻を配信
	note_spawner.update_time(precise_time_sec)
	judgement_system.update_time(precise_time_sec)

	# デバッグ表示更新
	if debug_mode:
		_update_debug_display()

## デバッグ表示更新
## 事前条件: GameConfig.debug_mode == true
## 事後条件: DebugDisplay.text更新
func _update_debug_display() -> void:
	if debug_display == null:
		return

	var fps := Engine.get_frames_per_second()
	var latency_ms := AudioServer.get_output_latency() * 1000.0
	var active_notes: int = note_spawner.get_active_note_count()

	debug_display.text = "Time: %.3f\nFPS: %d\nLatency (ms): %.1f\nActive Notes: %d" % [
		precise_time_sec,
		fps,
		latency_ms,
		active_notes
	]

## デバッグ切替入力処理
## 事前条件: "toggle_debug" アクション定義済み
## 事後条件: GameConfig.debug_mode反転、表示切替
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		debug_mode = not debug_mode
		if debug_display:
			debug_display.visible = debug_mode
		print("Debug mode: ", debug_mode)
