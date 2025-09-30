# 要件定義書：Phase 1 コアゲームプレイ

**バージョン:** 1.0  
**作成日:** 2025年9月30日  
**対象フェーズ:** Phase 1: コアゲームプレイ実装

---

## プロジェクト説明（入力）
Phase 1: コアゲームプレイ

Phase 0で構築したプロジェクト基盤（AutoLoadスクリプト、ディレクトリ構造、Input Map）の上に、リズムゲームの核となるゲームプレイ機能を実装します。

---

## 1. 概要と目的

### 1.1 フェーズの目的
- リズムゲームの基本的なゲームループを確立
- 音楽と視覚要素の高精度な同期を実現
- プレイヤーの入力に対する正確な判定システムを構築
- 最小限のUIで動作確認可能な状態を実現

### 1.2 前提条件
- Phase 0が完了していること（AutoLoad、ディレクトリ構造、Input Map設定済み）
- 以下のAutoLoadスクリプトが利用可能であること：
  - `GameConfig.gd`: ゲーム設定値の管理
  - `ScoreManager.gd`: スコア・コンボ管理
  - `ChartLoader.gd`: 譜面データ読み込み

### 1.3 成功基準
- [ ] テスト譜面を正常に読み込み、再生できる
- [ ] ノートが音楽と同期して正しいタイミングで生成される
- [ ] 4キー（D, F, J, K）の入力を正確に検知できる
- [ ] 判定システムが±25ms以内の精度でPERFECT判定を行える
- [ ] スコアとコンボが正しく計算され、基本的なUIに表示される

---

## 2. 機能要件

### 2.1 シーン構築

#### 2.1.1 Game.tscn（メインゲームシーン）
**目的**: ゲーム全体を統合するメインシーン

**必須ノード構成**:
```
Game (Node2D)
├── MusicPlayer (AudioStreamPlayer)
├── NoteSpawner (Node2D)
├── InputHandler (Node)
├── JudgementSystem (Node)
├── Visuals (Node2D)
│   ├── Background
│   ├── Lanes (4レーン表示)
│   └── JudgementLine
├── FX (Node2D)
│   └── (将来のエフェクト用コンテナ)
└── UI (CanvasLayer)
    ├── ScoreLabel
    ├── ComboLabel
    └── DebugDisplay
```

**要件**:
- ルートノード（Game）に`Game.gd`スクリプトをアタッチ
- 各ノードは明確に分離された責務を持つこと
- UI要素は`CanvasLayer`上に配置し、常に最前面に表示

#### 2.1.2 Note.tscn（ノート単体シーン）
**目的**: 個別のノートオブジェクトを表現

**必須ノード構成**:
```
Note (Area2D)
├── Sprite2D
└── CollisionShape2D
```

**プロパティ**:
- `lane_index: int` - レーン番号（0-3）
- `target_time_sec: float` - 判定ライン到達予定時刻（秒）
- `is_hit: bool` - ヒット済みフラグ

**要件**:
- レーンごとに色を変更できること（例: 0=赤, 1=青, 2=緑, 3=黄）
- `GameConfig.NOTE_SPEED`に従って下方向に移動すること
- 判定ラインを通過後、一定距離で自動削除（Miss判定）

---

### 2.2 時間同期システム

#### 2.2.1 高精度時間計算
**目的**: 音楽再生とゲームロジックの正確な同期

**実装要件**:
```gdscript
# Game.gd の _process 内で毎フレーム計算
precise_time_sec = music_player.get_playback_position() + 
                   AudioServer.get_time_since_last_mix() - 
                   AudioServer.get_output_latency()
```

**要件**:
- `MusicPlayer.get_playback_position()`を基準時刻とする
- `AudioServer.get_time_since_last_mix()`でミックス補正を適用
- `AudioServer.get_output_latency()`でレイテンシ補正を適用
- 計算された`precise_time_sec`を各システム（NoteSpawner, JudgementSystem）に伝達

#### 2.2.2 ゲーム起動シーケンス
**要件**:
1. `Game._ready()`で譜面データを`ChartLoader`経由で読み込み
2. 譜面データを`NoteSpawner`と`JudgementSystem`に渡す
3. 音楽ファイルを`MusicPlayer`にセット
4. `ScoreManager.reset_game()`でスコア初期化
5. 短い遅延後（0.5秒程度）に音楽再生開始

---

### 2.3 ノート生成システム（NoteSpawner）

#### 2.3.1 譜面データの解析
**目的**: JSON譜面データをゲーム内時間に変換

**入力**:
- 譜面データ（JSON形式）
  - `metadata.bpm`: BPM値
  - `metadata.offset_sec`: オフセット秒数
  - `notes[]`: ノート配列（`beat`, `lane`）

**処理**:
```
target_time_sec = offset_sec + (beat / bpm) * 60.0
```

**要件**:
- 全ノートを時間順にソートした「ノートキュー」を準備
- 各ノートに対して`target_time_sec`（判定ライン到達時刻）を計算
- ノートキューは変更不可とし、参照のみ行う

#### 2.3.2 ノート生成ロジック
**要件**:
- **先行生成時間**: `spawn_lead_time = 2.0秒`
  - ノートは判定ラインに到達する2秒前に生成
- **生成判定**: `current_time >= (target_time - spawn_lead_time)`で生成
- **生成処理**:
  1. `Note.tscn`をインスタンス化
  2. `lane_index`と`target_time_sec`を設定
  3. 初期位置を設定（X: レーン位置, Y: 画面外上部 -50）
  4. シーンツリーに`add_child()`で追加
  5. アクティブノート配列に追加
- **重複生成防止**: 各ノートに`spawned`フラグを設け、1度のみ生成

#### 2.3.3 ノート移動
**要件**（Note.gd内）:
- 毎フレーム`position.y += GameConfig.NOTE_SPEED * delta`で下方向に移動
- `NOTE_SPEED = 600.0` pixels/second（GameConfig定義）
- 判定ライン通過後、100px下で自動削除（Miss判定発動）

---

### 2.4 入力処理システム（InputHandler）

#### 2.4.1 キー入力検知
**要件**:
- 4キー（D, F, J, K）の入力をリアルタイムで検知
- `GameConfig.KEY_MAPPINGS`を参照してレーン番号に変換:
  ```gdscript
  {
    0: KEY_D,
    1: KEY_F,
    2: KEY_J,
    3: KEY_K
  }
  ```
- エコー入力（キー長押し時の連続入力）を無視
- キーが押された瞬間のみ反応（`event.pressed`かつ`not event.echo`）

#### 2.4.2 シグナル発行
**要件**:
- `input_received(lane_index: int)`シグナルを定義
- キー入力検知時に対応するレーン番号とともにシグナルを発行
- シグナルは`JudgementSystem`が購読

---

### 2.5 判定システム（JudgementSystem）

#### 2.5.1 判定ウィンドウ
**要件**（GameConfig定義値）:
- `PERFECT_WINDOW: 0.025秒`（±25ms）
- `GOOD_WINDOW: 0.050秒`（±50ms）
- `OK_WINDOW: 0.080秒`（±80ms）
- `MISS_WINDOW: 0.150秒`（±150ms、これ以上は無視）

#### 2.5.2 判定ロジック
**処理フロー**:
1. `InputHandler`から`input_received(lane_index)`シグナルを受信
2. 対象レーンのアクティブノートを`NoteSpawner`から取得
3. レーンにノートが存在しない場合は処理終了（ペナルティなし）
4. 判定ラインに最も近いノートを特定
   - 距離 = `abs(note.target_time_sec - current_time)`
   - 最小距離のノートを選択
5. タイミング差分を計算: `delta_time = note.target_time_sec - current_time`
6. 判定ウィンドウと比較:
   ```
   if abs(delta_time) <= PERFECT_WINDOW: "PERFECT"
   elif abs(delta_time) <= GOOD_WINDOW: "GOOD"
   elif abs(delta_time) <= OK_WINDOW: "OK"
   else: 無視（ウィンドウ外）
   ```
7. `ScoreManager.add_judgement(judgement, delta_time)`を呼び出し
8. ノートの`hit(judgement)`メソッドを呼び出して消滅処理

**要件**:
- 判定精度は±1ms以内の誤差であること
- 同時押し（複数レーン同時入力）に対応すること
- ノート消滅後は再判定されないこと

#### 2.5.3 Miss判定
**要件**:
- ノートが判定ライン通過後、100px下に到達したら自動的にMiss判定
- `ScoreManager.add_judgement("MISS", 0.0)`を呼び出し
- ノートをシーンから削除（`queue_free()`）

---

### 2.6 基本的なスコアリング実装

#### 2.6.1 スコア計算
**要件**（ScoreManager実装）:
- 基本スコア:
  - PERFECT: 100点
  - GOOD: 70点
  - OK: 40点
  - MISS: 0点
- コンボ倍率（Phase 1では簡易実装）:
  - 10コンボ未満: 1.0倍
  - 10コンボ以上: 1.1倍
- 最終スコア計算: `基本スコア × コンボ倍率`

#### 2.6.2 コンボ管理
**要件**:
- PERFECT/GOOD/OKでコンボ+1
- MISSでコンボリセット（0に戻す）
- 最大コンボ（`max_combo`）を記録

#### 2.6.3 統計情報
**要件**:
- 判定カウント（`judgement_counts`）の記録:
  ```gdscript
  {
    "PERFECT": 0,
    "GOOD": 0,
    "OK": 0,
    "MISS": 0
  }
  ```
- 各判定が発生するたびにカウントを増加

---

## 3. 非機能要件

### 3.1 パフォーマンス
- **フレームレート**: 60 FPS を安定維持
- **入力遅延**: 16ms以内（1フレーム以内）
- **音楽同期精度**: ±1ms以内の誤差
- **ノート生成**: 同時に100ノートまで処理可能

### 3.2 品質
- **コードの可読性**: 各スクリプトは単一責任原則に従う
- **エラーハンドリング**: 譜面ファイル読み込み失敗時の適切なエラーメッセージ
- **デバッグ機能**: F1キーでデバッグ情報の表示/非表示を切り替え可能

### 3.3 保守性
- **設定の集中管理**: 全定数を`GameConfig.gd`に集約
- **シグナルベース通信**: 疎結合なアーキテクチャを維持
- **将来の拡張性**: ロングノート、スライダーノートへの拡張を考慮した設計

---

## 4. データ要件

### 4.1 入力データ
#### テスト用譜面ファイル
**ファイル名**: `res://assets/charts/test_song.json`

**必須フィールド**:
```json
{
  "metadata": {
    "song_title": "Test Song",
    "artist": "Test Artist",
    "bpm": 120.0,
    "offset_sec": 2.0,
    "song_path": "res://assets/music/test_song.wav",
    "difficulty": "Normal"
  },
  "notes": [
    { "beat": 0.0, "lane": 0 },
    { "beat": 0.5, "lane": 1 }
    // ... 最低20ノート以上
  ]
}
```

**要件**:
- BPM: 100-150の範囲
- ノート数: 20-50個程度
- レーン配置: 全4レーンを均等に使用
- 難易度: 初見でクリア可能な簡単なパターン

#### 音楽ファイル
**ファイル名**: `res://assets/music/test_song.wav`

**要件**:
- フォーマット: WAV形式（`.wav`）
- 長さ: 30秒程度
- BPM: 譜面データと一致
- 音質: 16bit, 44.1kHz以上

### 4.2 出力データ
#### 実行時データ（ScoreManager管理）
- `current_score: int` - 現在のスコア
- `current_combo: int` - 現在のコンボ数
- `max_combo: int` - 最大コンボ数
- `judgement_counts: Dictionary` - 判定カウント

---

## 5. UI/UX要件（最小限）

### 5.1 ゲーム画面表示
**必須UI要素**:
1. **スコア表示**:
   - 位置: 画面上部中央
   - フォーマット: "Score: 12345"
   - 更新: リアルタイム（ScoreManager.score_updatedシグナル）

2. **コンボ表示**:
   - 位置: 画面中央やや下
   - フォーマット: "50 COMBO"
   - 表示条件: コンボ1以上
   - 非表示条件: コンボ0（Miss時）

3. **デバッグ表示**:
   - 位置: 画面左上
   - 内容:
     ```
     Time: 12.345
     FPS: 60
     Latency (ms): 5.2
     Active Notes: 8
     ```
   - 表示切替: F1キー（Input Map: `toggle_debug`）

### 5.2 視覚要素
**レーン表示**:
- 4本の垂直レーン（X座標: 400, 520, 640, 760）
- 各レーン幅: 100px程度
- 背景: 半透明の縦線

**判定ライン**:
- Y座標: 600.0（GameConfig定義）
- 表示: 水平の明るい線
- 幅: 画面全体（1280px）

**ノート表示**:
- サイズ: 80x80 px程度
- 色: レーンごとに異なる（0=赤, 1=青, 2=緑, 3=黄）
- シェイプ: 正方形または円形

---

## 6. 技術的制約

### 6.1 使用技術
- **エンジン**: Godot 4.5 Stable以降
- **言語**: GDScript
- **オーディオシステム**: Godot組み込みのAudioStreamPlayer
- **レンダリング**: 2Dレンダラー

### 6.2 依存関係
- **AutoLoadスクリプト**（Phase 0で実装済み）:
  - `GameConfig.gd`
  - `ScoreManager.gd`
  - `ChartLoader.gd`
- **Input Map**（Phase 0で設定済み）:
  - `lane_0` (D キー)
  - `lane_1` (F キー)
  - `lane_2` (J キー)
  - `lane_3` (K キー)
  - `toggle_debug` (F1 キー)

### 6.3 ファイル配置
**作成するスクリプト**:
- `scripts/game/Game.gd`
- `scripts/game/NoteSpawner.gd`
- `scripts/game/InputHandler.gd`
- `scripts/game/JudgementSystem.gd`
- `scripts/game/Note.gd`

**作成するシーン**:
- `scenes/Game.tscn`
- `scenes/Note.tscn`

---

## 7. テスト要件

### 7.1 機能テスト
#### 時間同期テスト
- [ ] 音楽再生開始から10秒後、`precise_time_sec`が10.0±0.01の範囲内であること
- [ ] デバッグ表示のLatencyが0-20msの範囲内であること

#### ノート生成テスト
- [ ] BPM 120, beat 4.0のノートが、4秒後に判定ラインに到達すること
- [ ] 全20ノートが正常に生成され、漏れがないこと
- [ ] ノートが正しいレーン（X座標）に生成されること

#### 判定テスト
- [ ] タイミングぴったりで入力した場合、PERFECT判定が出ること
- [ ] ±30ms遅延で入力した場合、GOOD判定が出ること
- [ ] ±60ms遅延で入力した場合、OK判定が出ること
- [ ] ノート通過後の入力が無視されること（次のノートに影響しない）

#### スコアリングテスト
- [ ] PERFECT 10回で1000点（倍率1.0）
- [ ] コンボ10達成後、PERFECT 1回で110点（倍率1.1）
- [ ] MISS発生時、コンボが0にリセットされること

### 7.2 統合テスト
- [ ] テスト譜面を最初から最後まで完走できること
- [ ] 60 FPSを維持したまま動作すること
- [ ] 音楽とノート移動が同期していること（視覚的確認）

---

## 8. スコープ外（Phase 2以降）

以下の機能はPhase 1のスコープ外とし、後続フェーズで実装します:

- [ ] 判定表示アニメーション（"PERFECT"等のテキスト表示）
- [ ] 精度（Accuracy）計算とグレード判定
- [ ] ヒットエフェクト・パーティクル
- [ ] 効果音（ヒット音、Miss音）
- [ ] リザルト画面
- [ ] 曲選択画面
- [ ] セーブデータ機能

---

## 9. リスク管理

### 9.1 技術リスク
| リスク | 影響度 | 対策 |
|--------|--------|------|
| 音楽同期のズレ | 高 | `AudioServer`のレイテンシ補正を確実に実装 |
| フレームレート低下 | 中 | ノート数を制限、パフォーマンスプロファイリング |
| 譜面データ読み込み失敗 | 中 | エラーハンドリング、デフォルト譜面の準備 |
| キー入力の取りこぼし | 高 | `_input`メソッドで確実に処理、エコー無視 |

### 9.2 スケジュールリスク
- **想定期間**: 3-5日
- **クリティカルパス**: 時間同期システムの実装と検証
- **バッファ**: 各機能に0.5日のバッファを確保

---

## 10. 承認基準

以下の条件を満たした場合、要件定義を承認し、設計フェーズへ移行します:

- [ ] 全機能要件が明確に定義されている
- [ ] 成功基準が測定可能である
- [ ] スコープ（Phase 1で実装する/しない）が明確である
- [ ] 技術的制約が明記されている
- [ ] Phase 0との依存関係が明確である

---

## 11. 次のステップ

要件定義承認後、以下のコマンドで設計フェーズに進みます:

```
/kiro/spec-design core-gameplay
```

設計フェーズでは、この要件定義を基に、具体的なクラス設計、シーケンス図、詳細な実装手順を策定します。