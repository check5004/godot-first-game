# res://scripts/test_setup.gd
extends Node

func _ready() -> void:
	print("=== Project Setup Verification ===")
	
	# 1. AutoLoad検証
	verify_autoload()
	
	# 2. ディレクトリ検証
	verify_directories()
	
	# 3. 譜面ファイル検証
	verify_chart()
	
	print("=== Verification Complete ===")

func verify_autoload() -> void:
	print("\n[1] Verifying AutoLoad...")
	
	# GameConfig
	assert(GameConfig != null, "GameConfig not loaded")
	assert(GameConfig.PERFECT_WINDOW == 0.025, "PERFECT_WINDOW incorrect")
	assert(GameConfig.get_combo_multiplier(50) == 1.5, "Combo multiplier incorrect")
	print("✅ GameConfig OK")
	
	# ScoreManager
	assert(ScoreManager != null, "ScoreManager not loaded")
	ScoreManager.reset_game()
	assert(ScoreManager.current_score == 0, "Reset failed")
	print("✅ ScoreManager OK")
	
	# ChartLoader
	assert(ChartLoader != null, "ChartLoader not loaded")
	print("✅ ChartLoader OK")

func verify_directories() -> void:
	print("\n[2] Verifying Directories...")
	
	var required_dirs := [
		"res://scenes/",
		"res://scripts/autoload/",
		"res://assets/music/",
		"res://assets/charts/"
	]
	
	for dir_path in required_dirs:
		assert(DirAccess.dir_exists_absolute(dir_path), "Missing: " + dir_path)
	
	print("✅ All directories exist")

func verify_chart() -> void:
	print("\n[3] Verifying Chart File...")
	
	var chart_path := "res://assets/charts/test_song.json"
	var chart := ChartLoader.load_chart(chart_path)
	
	assert(not chart.is_empty(), "Chart loading failed")
	assert(chart["metadata"]["bpm"] == 120.0, "BPM incorrect")
	assert(chart["notes"].size() == 12, "Note count incorrect")
	assert(ChartLoader.validate_chart(chart), "Chart validation failed")
	
	print("✅ Chart file OK")
