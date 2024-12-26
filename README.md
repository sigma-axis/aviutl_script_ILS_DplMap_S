# Inline Scene Displacement Map_S AviUtl スクリプト

[Inline Scene S](https://github.com/sigma-axis/aviutl_script_InlineScene_S) で保存したキャッシュ画像でディスプレイスメントマップ効果を適用するスクリプト．

フィルタ効果のディスプレイスメントマップで，マップ元画像としてシーンを選択した場合の「inline scene 版」です．

[ダウンロードはこちら．](https://github.com/sigma-axis/aviutl_script_ILS_DplMap_S/releases) \[紹介動画準備中...．\]

![ディスプレイスメントマップのデモ](https://github.com/user-attachments/assets/fd534cba-d405-4d96-9e8d-fcdfd82178a8)

## 動作要件

- AviUtl 1.10 (1.00 など他バージョンでは動作不可)

  http://spring-fragrance.mints.ne.jp/aviutl

- 拡張編集 0.92

  - 0.93rc1 など他バージョンでは動作不可．

- patch.aul (謎さうなフォーク版)

  https://github.com/nazonoSAUNA/patch.aul

- [LuaJIT](https://luajit.org/)

  バイナリのダウンロードは[こちら](https://github.com/Per-Terra/LuaJIT-Auto-Builds/releases)からできます．

  - 拡張編集 0.93rc1 同梱の `lua51jit.dll` は***バージョンが古く既知のバグもあるため非推奨***です．
  - AviUtl のフォルダにある `lua51.dll` と置き換えてください．

- Inline Scene S の導入

  https://github.com/sigma-axis/aviutl_script_InlineScene_S

## 導入方法

以下のフォルダに `@ILS_DplMap_S.anm` と `ILS_DplMap_S.lua` の 2 つのファイルをコピーしてください．

- `InlineScene_S.lua` のあるフォルダ

  [Inline Scene S](https://github.com/sigma-axis/aviutl_script_InlineScene_S) の導入先のフォルダです．

> [!TIP]
> 正確には「`require "InlineScene_S` の構文で `InlineScene_S.lua` が見つかること」が条件なので，例えば `InlineScene_S.lua` が `script` フォルダに配置されているなどの場合は，`script` フォルダ内の任意の名前のフォルダでも可能です．
>
> `patch.aul.json` で `"switch"` 以下の `"lua.path"` を `true` にすることで，`module` フォルダに `InlineScene_S.lua` を配置する方法も可能です（ただし一部 rikky_module.dll を使うスクリプトなどが動かなくなる報告もあります）．
>
> 詳しくは [Lua 5.1 の `require` の仕様](https://www.lua.org/manual/5.1/manual.html#5.3)と拡張編集のスクリプトの仕様を参照してください．

## 使い方

[`Inline Sceneここまで`](https://github.com/sigma-axis/aviutl_script_InlineScene_S?tab=readme-ov-file#inline-scene%E3%81%93%E3%81%93%E3%81%BE%E3%81%A7) や [`Inline Scene単品保存`](https://github.com/sigma-axis/aviutl_script_InlineScene_S?tab=readme-ov-file#inline-scene%E5%8D%98%E5%93%81%E4%BF%9D%E5%AD%98) などでキャッシュが保存されている状態で，オブジェクトに [`Displacement Map`](#displacement-map) のアニメーション効果を適用すると，現在オブジェクトがキャッシュ画像によって変形します．

通常はマップ元画像が対象画像に合わせてサイズ調整されます（拡張編集のディスプレイスメントマップで「元のサイズに合わせる」が ON の場合に相当する動作）．マップ元画像の位置や回転角度，サイズなどを変更・調整する場合は，[`Displacement Map設定(拡大率指定)`](#displacement-map設定拡大率指定) や [`Displacement Map設定(サイズ指定)`](#displacement-map設定サイズ指定) を `Displacement Map` の直前に適用してください．

![設定は連続して配置](https://github.com/user-attachments/assets/89fa5b71-1b1f-4589-9067-37c30c62aa62)

各アニメーション効果の「設定」にある `PI` は parameter injection です．初期値は `nil`. テーブル型を指定すると `obj.check0` や `obj.track0` などの代替値として使用されます．また，任意のスクリプトコードを実行する記述領域にもなります．

```lua
_0 = {
  [0] = check0, -- boolean または number (~= 0 で true 扱い). obj.check0 の代替値．それ以外の型だと無視．
  [1] = track0, -- number 型．obj.track0 の代替値．tonumber() して nil な場合は無視．
  [2] = track1, -- obj.track1 の代替値．その他は [1] と同様．
  [3] = track2, -- obj.track2 の代替値．その他は [1] と同様．
  [4] = track3, -- obj.track3 の代替値．その他は [1] と同様．
}
```

### `Displacement Map`

ディスプレイスメントマップを適用するアニメーション効果です．

この直前に [`Displacement Map設定(拡大率指定)`](#displacement-map設定拡大率指定) や [`Displacement Map設定(サイズ指定)`](#displacement-map設定サイズ指定) がかけられていた場合，そこで指定された位置や回転角度，サイズ等の設定も適用されます．これらがない場合は，「元のサイズに合わせる」に相当する効果になります．

#### 設定値
1.  `パラメタ1` / `パラメタ2`

    ディスプレイスメントマップの変形に関わるパラメタです．`変形方法` の指定に応じて取り扱いが変わります．最小値は `-2000`, 最大値は `2000`, 初期値は `0`.

1.  `ぼかし`

    マップ元画像にぼかしを設定します．最小値は `0`, 最大値は `200`, 初期値は `5`.

1.  `変形方法`

    ディスプレイスメントマップの変形方法を `1` から `3` の 3 つから指定します．指定に応じて `パラメタ1` と `パラメタ2` の解釈が変化します．対応は以下の表の通りです:

    |`変形方法`|効果|`パラメタ1` の対象|`パラメタ2` の対象|マップ元画像の解釈|
    |:---:|:---:|:---:|:---:|:---|
    |`1`|移動変形|変形X|変形Y|赤成分が水平方向への移動，緑成分が垂直方向への移動|
    |`2`|移動変形|拡大変形|拡大縦横|赤成分が水平方向の拡大率，緑成分が垂直方向の拡大率|
    |`3`|回転変形|回転変形|(効果なし)|赤成分が回転角度|

    初期値は `1` (移動変形).

1.  `ILシーン名`

    マップ元のキャッシュ画像を表す，`Inline Scene単品保存` などで指定した `ILシーン名` を指定します．初期値は `scn1`.

1.  `現在フレーム`

    ON の場合，inline scene がそのフレーム描画中に保存されたものでないときにはディスプレイスメントマップを適用しません．初期値は OFF.

### `Displacement Map設定(拡大率指定)`

[`Displacement Map`](#displacement-map) の処理に対して位置，回転角度，拡大率，縦横比を指定します．`Displacement Map` の直前に配置してください．

#### 設定値
1.  `X` / `Y`

    マップ元画像の位置を指定します．アンカーをマウス移動でも調整可能です．最小値は `-2000`, 最大値は `2000`, 初期値は原点 $(0, 0)$.

1.  `回転`

    マップ元画像の回転角度を指定します．度数法で時計回りが正．最小値は `-720`, 最大値は `720`, 初期値は `0`.

1.  `拡大率`

    マップ元画像の拡大率を % 単位で指定します．最小値は `0`, 最大値は `1600`, 初期値は `100`.

1.  `縦横比`

    マップ元画像の縦横比を指定します．最小値は `-100`, 最大値は `100`, 初期値は `0`. 負で横長，正で縦長．

### `Displacement Map設定(サイズ指定)`

[`Displacement Map`](#displacement-map) の処理に対して位置，回転角度，サイズ，縦横比を指定します．`Displacement Map` の直前に配置してください．

[`Displacement Map設定(拡大率指定)`](#displacement-map設定拡大率指定) とは `拡大率` と `サイズ` 以外の項目は同等です．

#### 設定値
1.  `サイズ`

    マップ元画像のサイズの長辺をピクセル単位で指定します．最小値は `0`, 最大値は `4000`, 初期値は `200`.

1.  その他の設定値

    [`Displacement Map設定(拡大率指定)`](#displacement-map設定拡大率指定) と同等です．

## TIPS

1.  [`Displacement Map設定(拡大率指定)`](#displacement-map設定拡大率指定) と [`Displacement Map設定(サイズ指定)`](#displacement-map設定サイズ指定) を同時に指定した場合は，最後に指定したものの効果が優先されます．また，[`Displacement Map`](#displacement-map) と別々のオブジェクトに配置されていた場合 (例: オブジェクトに `Displacement Map設定(拡大率指定)`, グループ制御に `Displacement Map`) は `Displacement Map設定(拡大率指定)` と `Displacement Map設定(サイズ指定)` は機能しません．

1.  テキストエディタで `@ILS_DplMap_S.anm`, `ILS_DplMap_S.lua` を開くと冒頭付近にファイルバージョンが付記されています．

    ```lua
    --
    -- VERSION: v1.00
    --
    ```

    ファイル間でバージョンが異なる場合，更新漏れの可能性があるためご確認ください．


## 改版履歴

- **v1.00** (2024-12-??)

  - 初版．


## ライセンス

このプログラムの利用・改変・再頒布等に関しては MIT ライセンスに従うものとします．

---

The MIT License (MIT)

Copyright (C) 2024 sigma-axis

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

https://mit-license.org/


#  連絡・バグ報告

- GitHub: https://github.com/sigma-axis
- Twitter: https://x.com/sigma_axis
- nicovideo: https://www.nicovideo.jp/user/51492481
- Misskey.io: https://misskey.io/@sigma_axis
- Bluesky: https://bsky.app/profile/sigma-axis.bsky.social
