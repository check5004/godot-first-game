extends Node

## キー入力検知スクリプト
## 責務: 4キー（D, F, J, K）の入力を検知し、レーン番号に変換してシグナルで通知

# シグナル定義
signal input_received(lane_index: int)

## 入力処理
## 事前条件: GameConfig.KEY_MAPPINGSに有効なマッピング定義済み
## 事後条件: 対応するキー押下時、input_receivedシグナル発火
func _input(event: InputEvent) -> void:
	# キー入力イベントのみ処理
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	# キーが押された瞬間のみ反応（エコー入力を無視）
	if not key_event.pressed or key_event.echo:
		return

	# 物理キーコードからレーン番号に変換
	var keycode := key_event.physical_keycode

	for lane_index in GameConfig.KEY_MAPPINGS:
		if GameConfig.KEY_MAPPINGS[lane_index] == keycode:
			# 対応するレーン番号でシグナル発火
			input_received.emit(lane_index)
			return
