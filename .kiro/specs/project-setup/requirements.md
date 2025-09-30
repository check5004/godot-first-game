# Requirements Document

## Project Description (Input)

**プロジェクトセットアップ**

Godot 4.5を使用したリズムゲームプロジェクトの初期セットアップを実施します。詳細設計書および要件定義書に基づき、以下を構築します：

- プロジェクトディレクトリ構造の構築
- AutoLoadスクリプトの作成（GameConfig.gd, ScoreManager.gd, ChartLoader.gd）
- Input Mapの設定（D, F, J, Kキー）
- プロジェクト設定の構成
- テスト用リソースファイルの準備

開発環境：Windows、PowerShell

## Requirements

### 1. ディレクトリ構造の構築

#### 1.1 必須ディレクトリ

以下のディレクトリ構造を構築すること：

```
project/
├── scenes/
│   ├── UI/
├── scripts/
│   ├── autoload/
│   ├── game/
│   ├── ui/
│   └── editor/
├── assets/
│   ├── music/
│   ├── charts/
│   ├── textures/
│   │   ├── notes/
│   │   └── ui/
│   └── fonts/
└── addons/
```

#### 1.2 ディレクトリの責務

- **scenes/**: ゲームシーンファイル（.tscn）を格納
  - **UI/**: UI関連シーンをサブディレクトリとして分離
- **scripts/**: GDScriptファイルを責務別に整理
  - **autoload/**: AutoLoad（シングルトン）スクリプト専用
  - **game/**: ゲームロジック関連スクリプト
  - **ui/**: UI制御スクリプト
  - **editor/**: 譜面エディタ関連スクリプト
- **assets/**: リソースファイルを種類別に分類
  - **music/**: WAV形式の音楽ファイル
  - **charts/**: JSON形式の譜面データ
  - **textures/**: 画像ファイル（ノート、UI要素）
  - **fonts/**: フォントファイル
- **addons/**: サードパーティプラグイン用ディレクトリ

### 2. AutoLoadスクリプトの作成

#### 2.1 GameConfig.gd（res://scripts/autoload/GameConfig.gd）

**責務**: ゲーム全体の設定値を一元管理

**必須定数**:
- タイミング判定ウィンドウ（秒単位）
  - `PERFECT_WINDOW: float = 0.025` (±25ms)
  - `GOOD_WINDOW: float = 0.050` (±50ms)
  - `OK_WINDOW: float = 0.080` (±80ms)
  - `MISS_WINDOW: float = 0.150` (±150ms)
- スコアリング
  - `SCORE_PERFECT: int = 100`
  - `SCORE_GOOD: int = 70`
  - `SCORE_OK: int = 40`
  - `SCORE_MISS: int = 0`
  - `COMBO_MULTIPLIER: Dictionary` - コンボ倍率テーブル
- ノート設定
  - `NOTE_SPEED: float = 600.0` (pixels per second)
  - `JUDGEMENT_LINE_Y: float = 600.0` (判定ラインY座標)
- キーマッピング
  - `KEY_MAPPINGS: Dictionary` - レーンインデックス → キーコード
  - `LANE_POSITIONS: Array[float]` - レーンのX座標配列
- 難易度設定
  - `Difficulty` 列挙型（EASY, NORMAL, HARD, EXPERT）
  - `DIFFICULTY_NAMES: Dictionary` - 難易度表示名マッピング

**必須メソッド**:
- `get_combo_multiplier(combo: int) -> float`: コンボ数から倍率を取得
- `get_judgement_window(judgement: String) -> float`: 判定種別からウィンドウ時間を取得

#### 2.2 ScoreManager.gd（res://scripts/autoload/ScoreManager.gd）

**責務**: プレイ中の状態管理とシグナル発行

**必須シグナル**:
- `score_updated(new_score: int)`: スコア更新時
- `combo_changed(new_combo: int)`: コンボ変更時
- `judgement_made(judgement: String, delta_time: float)`: 判定発生時
- `accuracy_updated(accuracy: float)`: 精度更新時

**必須状態変数**:
- `current_score: int`: 現在のスコア
- `current_combo: int`: 現在のコンボ数
- `max_combo: int`: 最大コンボ数
- `judgement_counts: Dictionary`: 判定種別ごとのカウント
- `total_notes: int`: 総ノート数

**必須メソッド**:
- `reset_game() -> void`: ゲーム開始時の状態リセット
- `add_judgement(judgement: String, delta_time: float) -> void`: 判定追加とスコア計算
- `get_accuracy() -> float`: 現在の精度（%）を取得
- `get_grade() -> String`: 精度に基づくグレード（S, A, B, C, D）を取得

#### 2.3 ChartLoader.gd（res://scripts/autoload/ChartLoader.gd）

**責務**: 譜面ファイルの読み込み、解析、バリデーション

**必須機能**:
- JSONファイルの読み込み
- 譜面データのキャッシュ機構
- データ構造の妥当性検証

**必須メソッド**:
- `load_chart(file_path: String) -> Dictionary`: 譜面JSONを読み込み
- `validate_chart(data: Dictionary) -> bool`: 譜面データの妥当性検証
- `save_chart(file_path: String, chart_data: Dictionary) -> Error`: 譜面をJSON保存
- `get_all_charts() -> Array[String]`: 利用可能な全譜面パスを取得

**バリデーション要件**:
- メタデータ必須キー: `song_title`, `artist`, `bpm`, `offset_sec`, `song_path`
- ノートデータ必須キー: `beat`, `lane`
- レーン番号範囲: 0-3

### 3. Input Map設定

#### 3.1 必須アクション定義

プロジェクト設定（`project.godot`）に以下のInput Actionを定義すること：

| アクション名 | 物理キーコード | デッドゾーン | 説明 |
|------------|--------------|------------|------|
| `lane_0` | `KEY_D` (68) | 0.5 | レーン0（左端） |
| `lane_1` | `KEY_F` (70) | 0.5 | レーン1（左中） |
| `lane_2` | `KEY_J` (74) | 0.5 | レーン2（右中） |
| `lane_3` | `KEY_K` (75) | 0.5 | レーン3（右端） |
| `toggle_debug` | `KEY_F3` (4194332) | 0.5 | デバッグ表示切替 |

#### 3.2 キー入力設定

- **物理キーコード**を使用（キーボードレイアウトに依存しない）
- **エコー無効化**: 長押し時の連続入力を防止
- **モディファイアキー**: 使用しない（Alt, Shift, Ctrl, Meta全て`false`）

### 4. プロジェクト設定

#### 4.1 基本設定（`project.godot`）

**Application設定**:
```ini
[application]
config/name="Rhythm Game"
run/main_scene="res://scenes/Main.tscn"
config/features=PackedStringArray("4.5", "Forward Plus")
```

**Display設定**:
```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/mode=2  # Windowed
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

**Audio設定**:
```ini
[audio]
buses/default_bus_layout="res://audio_bus_layout.tres"
```

#### 4.2 AutoLoad登録

プロジェクト設定のAutoLoadセクションに以下を登録：

| 名前 | パス | シングルトン |
|------|------|------------|
| `GameConfig` | `res://scripts/autoload/GameConfig.gd` | 有効 |
| `ScoreManager` | `res://scripts/autoload/ScoreManager.gd` | 有効 |
| `ChartLoader` | `res://scripts/autoload/ChartLoader.gd` | 有効 |

#### 4.3 オーディオバスレイアウト

`audio_bus_layout.tres`を作成し、以下のバス構成を定義：
- **Master**: メインバス
- **Music**: BGM専用バス（Masterの子）
- **SFX**: 効果音専用バス（Masterの子）

### 5. テスト用リソースファイル

#### 5.1 サンプル音楽ファイル

**ファイル**: `res://assets/music/test_song.wav`

**要件**:
- 形式: WAV（非圧縮）
- サンプリングレート: 44.1kHz以上
- チャンネル: モノラルまたはステレオ
- 長さ: 30秒以上推奨
- BPM: 120（標準テンポ）

#### 5.2 サンプル譜面ファイル

**ファイル**: `res://assets/charts/test_song.json`

**内容**:
```json
{
  "metadata": {
    "song_title": "Test Song - Basic Pattern",
    "artist": "Test Artist",
    "bpm": 120.0,
    "offset_sec": 2.0,
    "song_path": "res://assets/music/test_song.wav",
    "difficulty": "Normal",
    "chart_author": "System",
    "created_date": "2025-09-30"
  },
  "notes": [
    { "beat": 0.0, "lane": 0 },
    { "beat": 0.5, "lane": 1 },
    { "beat": 1.0, "lane": 2 },
    { "beat": 1.5, "lane": 3 },
    { "beat": 2.0, "lane": 0 },
    { "beat": 2.0, "lane": 2 }
  ]
}
```

**パターン要件**:
- 単一ノート（同時押しなし）のシンプルなパターン
- BPM基準の拍数（0.5刻み）
- 全レーン（0-3）を均等に使用
- 最低6ノート以上

#### 5.3 プレースホルダーテクスチャ

以下のプレースホルダー画像を作成：
- `res://assets/textures/notes/note_placeholder.png`: 64x64ピクセル、単色
- `res://assets/textures/ui/background_placeholder.png`: 1280x720ピクセル、グラデーション

### 6. 検証要件

#### 6.1 ディレクトリ検証

- すべての必須ディレクトリが存在すること
- `.gitkeep`または`.gdignore`ファイルで空ディレクトリを保持

#### 6.2 AutoLoadスクリプト検証

- 各AutoLoadスクリプトが構文エラーなくロードできること
- `_ready()`メソッドで初期化ログが出力されること
- プロジェクト設定のAutoLoadセクションに正しく登録されていること

#### 6.3 Input Map検証

- Godotエディタの「プロジェクト設定 → Input Map」で全アクションが表示されること
- 各アクションが正しいキーにマッピングされていること

#### 6.4 譜面データ検証

- `ChartLoader.validate_chart()`がサンプル譜面に対して`true`を返すこと
- 音楽ファイルが正しくロードできること

### 7. 非機能要件

#### 7.1 コード品質

- すべてのGDScriptファイルに型ヒント（`: Type`）を使用
- 公開関数には`-> ReturnType`を明記
- クラス変数に適切なスコープ（`var`, `const`, `@export`）を設定

#### 7.2 ドキュメント

- 各AutoLoadスクリプトの先頭にファイルパスコメント（`# res://scripts/...`）を記載
- 複雑なメソッドにはdocstring（`"""`）を追加
- 定数には必要に応じてコメントで単位や範囲を明記

#### 7.3 エラーハンドリング

- ファイル読み込み失敗時に`push_error()`でログ出力
- バリデーション失敗時に具体的なエラーメッセージを出力
- クリティカルなエラー時は空の辞書（`{}`）または適切なデフォルト値を返す

### 8. 開発環境特有の要件（Windows + PowerShell）

#### 8.1 パス表記

- Godot内部パスは常に`res://`プレフィックスを使用
- スラッシュは**前方スラッシュ**（`/`）を使用（バックスラッシュ`\`は使用しない）

#### 8.2 ファイル作成

- PowerShellの実行ポリシーによるブロックを回避するため、Godotエディタまたはファイルツールを使用
- 必要に応じて`New-Item`コマンドレットを使用

#### 8.3 文字エンコーディング

- すべてのGDScriptファイルは**UTF-8（BOMなし）**で保存
- JSON譜面ファイルも**UTF-8（BOMなし）**で保存

### 9. 成功基準

以下のすべてを満たすこと：

✅ **ディレクトリ**: 定義された構造が完全に作成されている  
✅ **AutoLoad**: 3つのスクリプトが構文エラーなく動作し、プロジェクト設定に登録されている  
✅ **Input Map**: 5つのアクション（lane_0〜3, toggle_debug）が正しく設定されている  
✅ **プロジェクト設定**: ウィンドウサイズ、ストレッチモード、オーディオバスが設定されている  
✅ **テストリソース**: サンプル音楽ファイルと譜面ファイルがロード可能  
✅ **検証**: `ChartLoader.validate_chart()`がサンプル譜面で`true`を返す  
✅ **エディタ起動**: Godotエディタでプロジェクトがエラーなく開ける

### 10. 参考資料

- **詳細設計書**: `docs/詳細設計書.md` - アーキテクチャとコード例
- **要件定義書**: `docs/要件定義書.md` - 設計思想と責務分離
- **Godot 4.5公式ドキュメント**: 
  - AutoLoadシステム
  - Input Mapの設定
  - AudioStreamPlayerの使用
  - JSONパース（`JSON.parse()`）
