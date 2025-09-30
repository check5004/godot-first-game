# UI テクスチャ配置ディレクトリ

## 必要なファイル

### background_placeholder.png

**仕様**:
- サイズ: 1280x720ピクセル
- 内容: 上から下へのグラデーション（濃い青 → 黒）
- 背景: 不透明

**作成方法**:

### オプション1: GIMPを使用
1. GIMP を開く
2. 新しい画像を作成: 1280x720ピクセル
3. グラデーションツールを選択
4. 前景色: 濃い青 (#000080)、背景色: 黒 (#000000)
5. 上から下へドラッグしてグラデーションを適用
6. PNG形式でエクスポート → `background_placeholder.png`

### オプション2: Inkscapeを使用
1. Inkscape を開く
2. ドキュメントのプロパティで 1280x720px に設定
3. 矩形ツールで全画面を覆う長方形を描画
4. 線形グラデーションを設定（濃い青 → 黒、上から下）
5. PNG形式でエクスポート → `background_placeholder.png`

### オプション3: Pythonスクリプト (PIL使用)
```python
from PIL import Image, ImageDraw

img = Image.new('RGB', (1280, 720))
draw = ImageDraw.Draw(img)

for y in range(720):
    # 濃い青から黒へのグラデーション
    r = int((0x00) * (1 - y/720))
    g = int((0x00) * (1 - y/720))
    b = int((0x80) * (1 - y/720))
    draw.line([(0, y), (1280, y)], fill=(r, g, b))

img.save('background_placeholder.png')
```

### オプション4: 簡易的な代替
- 任意の1280x720pxの画像を使用可能
- 単色の背景でもテストには十分です
