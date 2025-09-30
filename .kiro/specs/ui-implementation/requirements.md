# Requirements Document

## Introduction

Phase 2のUI実装は、Phase 1で完成したコアゲームプレイシステムに、プレイヤーへの視覚的フィードバックを提供するUI層を追加します。ScoreManagerのシグナルシステムと連携し、スコア、コンボ、判定結果、精度、グレードをリアルタイムで表示するCanvasLayerベースのUIControllerを中心とした設計です。

本フェーズでは、ゲームプレイの体験を向上させるために必要な6つの主要UI要素を実装し、プレイヤーがパフォーマンスを即座に把握できるインターフェースを提供します。

## Requirements

### Requirement 1: UIController基盤システム
**Objective:** ゲーム開発者として、ScoreManagerのシグナルを購読してUI要素を更新する管理システムが必要です。これにより、ゲーム状態の変化を自動的にUIに反映できます。

#### Acceptance Criteria

1. WHEN UIControllerノードが`_ready()`メソッドで初期化される THEN UIControllerは、ScoreManagerの全てのシグナル（`score_updated`, `combo_changed`, `judgement_made`, `accuracy_updated`）に接続しなければならない
2. IF ScoreManagerからシグナルが発火される THEN UIControllerは、対応するハンドラメソッドを呼び出して、UI要素を更新しなければならない
3. WHEN UIControllerが初期化される THEN UIControllerは、CanvasLayerを継承し、全てのUI要素（Label、AnimationPlayerなど）への参照を`@onready`変数で保持しなければならない
4. IF いずれかのUI要素ノード参照がnullである THEN UIControllerは、そのノードへのアクセスをスキップし、エラーを発生させずに動作を継続しなければならない

### Requirement 2: スコア表示システム
**Objective:** プレイヤーとして、現在のスコアをリアルタイムで確認したいです。これにより、自分のパフォーマンスを継続的に把握できます。

#### Acceptance Criteria

1. WHEN ScoreManagerから`score_updated`シグナルが発火される THEN UIControllerは、ScoreLabelのテキストを"Score: [数値]"の形式で更新しなければならない
2. IF 受信したスコア値が0である THEN ScoreLabelは"Score: 0"と表示しなければならない
3. WHEN スコア値が更新される THEN ScoreLabelは、整数形式（カンマ区切りなし）でスコアを表示しなければならない
4. WHERE ゲーム開始時 THE UIControllerは、ScoreLabelを初期値"Score: 0"で表示しなければならない

### Requirement 3: コンボ表示システム
**Objective:** プレイヤーとして、現在のコンボ数を視覚的に確認したいです。これにより、コンボの維持状況を把握し、ゲームプレイの集中力を高めることができます。

#### Acceptance Criteria

1. WHEN ScoreManagerから`combo_changed`シグナルが発火され、かつコンボ値が0より大きい THEN UIControllerは、ComboLabelを表示し、テキストを"[数値] COMBO"の形式で更新しなければならない
2. IF 受信したコンボ値が0である THEN UIControllerは、ComboLabelを非表示にしなければならない
3. WHEN コンボ値が1以上に変化する THEN ComboLabelは、即座に表示状態に切り替わらなければならない
4. WHERE ゲーム開始時 THE ComboLabelは、非表示状態でなければならない

### Requirement 4: 判定表示アニメーションシステム
**Objective:** プレイヤーとして、各ノートのヒット判定（PERFECT、GOOD、OK、MISS）を視覚的なフィードバックで確認したいです。これにより、タイミング精度を瞬時に理解できます。

#### Acceptance Criteria

1. WHEN ScoreManagerから`judgement_made`シグナルが発火される THEN UIControllerは、JudgementLabelのテキストを判定結果（"PERFECT"、"GOOD"、"OK"、"MISS"）で更新し、表示しなければならない
2. IF 判定結果が"PERFECT"である THEN JudgementLabelの色をゴールド（Color.GOLD）に設定しなければならない
3. IF 判定結果が"GOOD"である THEN JudgementLabelの色をライムグリーン（Color.LIME_GREEN）に設定しなければならない
4. IF 判定結果が"OK"である THEN JudgementLabelの色をオレンジ（Color.ORANGE）に設定しなければならない
5. IF 判定結果が"MISS"である THEN JudgementLabelの色をレッド（Color.RED）に設定しなければならない
6. WHEN 判定が表示される THEN UIControllerは、Tweenアニメーションを使用して、0.5秒かけてJudgementLabelの透明度（modulate.a）を1.0から0.0にフェードアウトしなければならない
7. WHEN フェードアウトアニメーションが完了する THEN UIControllerは、JudgementLabelを非表示にしなければならない
8. IF 新しい判定シグナルが前の判定アニメーション中に受信される THEN UIControllerは、進行中のTweenアニメーションを停止し、新しい判定を即座に表示しなければならない

### Requirement 5: 精度・グレード表示システム
**Objective:** プレイヤーとして、現在の精度（Accuracy）とグレード（S、A、B、C、D）をリアルタイムで確認したいです。これにより、プレイ全体の品質を把握できます。

#### Acceptance Criteria

1. WHEN ScoreManagerから`accuracy_updated`シグナルが発火される THEN UIControllerは、AccuracyLabelのテキストを"Accuracy: [数値]%"の形式（小数点第1位まで）で更新しなければならない
2. WHEN Accuracyが更新される THEN UIControllerは、ScoreManager.get_grade()メソッドを呼び出し、GradeLabelのテキストを取得したグレード文字列（"S"、"A"、"B"、"C"、"D"）で更新しなければならない
3. IF グレードが"S"である THEN GradeLabelの色をゴールド（Color.GOLD）に設定しなければならない
4. IF グレードが"A"である THEN GradeLabelの色をライムグリーン（Color.LIME_GREEN）に設定しなければならない
5. IF グレードが"B"である THEN GradeLabelの色をシアン（Color.CYAN）に設定しなければならない
6. IF グレードが"C"である THEN GradeLabelの色をオレンジ（Color.ORANGE）に設定しなければならない
7. IF グレードが"D"である THEN GradeLabelの色をレッド（Color.RED）に設定しなければならない
8. WHERE ゲーム開始時 THE AccuracyLabelは"Accuracy: 0.0%"、GradeLabelは非表示でなければならない

### Requirement 6: デバッグ表示システム
**Objective:** ゲーム開発者として、開発・テスト時にゲーム内部状態を確認するためのデバッグ情報を表示したいです。これにより、タイミング精度やパフォーマンスの問題を特定できます。

#### Acceptance Criteria

1. WHEN GameConfig.debug_modeがtrueに設定される THEN UIControllerは、DebugDisplayLabelを表示しなければならない
2. WHEN GameConfig.debug_modeがfalseに設定される THEN UIControllerは、DebugDisplayLabelを非表示にしなければならない
3. WHILE GameConfig.debug_modeがtrueである THE UIControllerは、毎フレーム`_process(delta)`でデバッグ情報を更新しなければならない
4. WHEN デバッグ情報が更新される THEN DebugDisplayLabelは、以下の情報を複数行テキストで表示しなければならない：現在の音楽再生時刻（秒、小数点第3位まで）、現在のFPS（整数）、AudioServerの出力レイテンシ（ミリ秒、小数点第1位まで）、アクティブなノート数（整数）
5. IF デバッグモードが無効である THEN UIControllerは、DebugDisplayLabelの更新処理をスキップし、パフォーマンスへの影響を最小化しなければならない
6. WHERE ゲーム開始時 THE DebugDisplayLabelは、GameConfig.debug_modeの初期値に基づいて表示/非表示状態を設定しなければならない