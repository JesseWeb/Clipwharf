# Clipwharf

macOS 向けの、小さくて完全ローカルなクリップボード履歴ツール。

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/) [![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org) [![Release](https://img.shields.io/github/v/release/JesseWeb/Clipwharf)](https://github.com/JesseWeb/Clipwharf/releases) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)

![Clipwharf: press ⌘⇧V, pick a card, it pastes](docs/screenshot.png)

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · **[日本語](README.ja.md)** · [Français](README.fr.md) · [Español](README.es.md)

Clipwharf は macOS 用の**完全ローカル**なクリップボード履歴ツールです。いつもどおりコピーして **⌘⇧V** を押し、カードを選ぶと、クリップボードに戻して直前のアプリに貼り付けます。

Paste などの商用クリップボードマネージャとは無関係のクリーンルーム実装で、それらのコード・素材・アイコンは含みません。アカウント不要、クラウドなし、テレメトリなし。データは Mac の外に出ません。

## 機能

- **5 種類のカード**：テキスト、リンク、カラー、画像、ファイル。ファイルは Finder と同じ QuickLook でプレビューし、複数ファイルは 2×2 のサムネイルと “+N” バッジになります。
- **ピン**：`⌘P` でカードを固定。固定したカードは専用タブに入り、200 件の履歴上限でも削除されません。
- **検索**：大文字小文字を区別せず、複数語は AND 検索。本文・ファイル名・リンクのホスト・**コピー元アプリ名**を対象にします。
- **コピー元アプリのバッジ**：各カードにコピー時のアプリのアイコンを表示。
- **パスワードマネージャを除外**：1Password、Bitwarden、LastPass、Dashlane、キーチェーンアクセス、Passwords、Keeper からのコピーは保存しません。
- **ログイン時に起動**：メニューバーのアイコン → *Launch at Login*。
- **ローカルのみ**：`~/Library/Application Support/Clipwharf` に JSON と PNG。

## 動作環境

- macOS 13 Ventura 以降
- Xcode 15 以降（Swift 5.9 以降）

## インストール

**方法 1：AI エージェントに任せる（最短）**

Claude Code / Codex / Cursor など、シェルコマンドを実行できる AI に次を貼り付けます。

> https://github.com/JesseWeb/Clipwharf をローカルに clone し、AGENTS.md を読んで、
> `./scripts/make-app.sh release` で Clipwharf.app をビルドして /Applications に導入してください。
> 起動後、アクセシビリティで有効にする項目と、自動貼り付けの確認方法を教えてください。

手順は [`AGENTS.md`](AGENTS.md) に、プロンプト例は [`docs/ai-install.md`](docs/ai-install.md) にあります。

**方法 2：自分でビルド**

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
./scripts/make-app.sh release
open dist/Clipwharf.app
```

`dist/Clipwharf.app` を `/Applications` に移動して使います（権限もこのパスに紐づきます）。

**方法 3：DMG をダウンロード。**

[最新リリース](https://github.com/JesseWeb/Clipwharf/releases/latest) にユニバーサルビルド（Apple シリコン + Intel、約 2 MB）があります。
**ad-hoc 署名・未公証**のため、初回起動は右クリックが必要です。

1. DMG を開き、**Clipwharf** をアプリケーションフォルダへドラッグ
2. **Clipwharf を右クリック → 開く → 「開く」**
3. アクセシビリティを求められたら許可

新しい ad-hoc ビルドへ更新するとコード ID が変わるため、スイッチがオンに見えても貼り付けが
ブロックされる場合は、メニューバーの **Fix Accessibility Permission…** で再設定してください。
自分の署名で Gatekeeper の手間を省きたい場合は方法 1 か 2 を。

## 初回起動

1. メニューバーにクリップのアイコンが現れます（Dock アイコンもメインウィンドウもありません。終了は右クリック → Quit）。
2. テキスト・画像・ファイルをコピーして **⌘⇧V**。
3. 自動貼り付けのためにアクセシビリティを許可：**システム設定 → プライバシーとセキュリティ → アクセシビリティ → Clipwharf をオン**。未許可でもクリップボードには入り、⌘V を自分で押すよう案内されます。

## ショートカット

| キー | 動作 |
|---|---|
| ⌘⇧V | パネルを開く／閉じる（グローバル） |
| ← / → | 選択を移動 |
| ⏎ | 選択したカードを貼り付け |
| ⌘P | ピン留め／解除 |
| ⌘1 / ⌘2 | 履歴／ピン留めタブ |
| esc | 閉じる |
| クリック | そのカードを貼り付け |
| 右クリック | ピン留め／解除、コピー |

## データの場所

```
~/Library/Application Support/Clipwharf/
├── history.json   # 新しい順のインデックス
└── Blobs/         # 画像データ（<uuid>.png）
```

すべて平文の JSON とファイルです。Clipwharf を終了してこのフォルダを削除すれば初期化できます。

## 署名と配布について（重要）

- **リポジトリにはソースのみ**。`dist/` は `.gitignore` 済みで、`.app`・`.icns`・証明書は含まれません。
- `scripts/make-app.sh` は**ビルドする Mac の**署名 ID を使います（Apple Development 証明書があればそれ、なければ ad-hoc）。特定の開発者名や Team ID は埋め込まれていません。
- したがって、あなたがビルドしたアプリは**あなた自身の**コード ID を持ち、メンテナの証明書とは無関係です。
- **ad-hoc 署名とアクセシビリティ**：macOS は許可をコード ID に結び付けるため、ad-hoc では再ビルドのたびに無効になります（設定のスイッチがオンに見えても実際は無効）。メニューバー → **Fix Accessibility Permission…** でリセットして再許可してください。固定証明書で署名したビルドは影響を受けません。
- **署名済み `.app` を他人に配る場合は別問題**で、Developer ID と公証が必要です。秘密鍵を公開できないため、本プロジェクトはソース配布のみとしています。

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| アクセシビリティがオンなのに毎回ダイアログが出る | メニューバー → **Fix Accessibility Permission…** の後に再度オンにする |
| ⌘⇧V が効かない | 他のクリップボードツール（Paste など）が占有している可能性。終了するかメニューバーから開く |
| 「他のアプリのデータへのアクセス」を求められる | QuickLook プレビュー時の macOS の確認。一度許可すれば以後は出ません |
| 他のアプリをクリックするとパネルが閉じる | 仕様です（フォーカスを失うと隠れます）。⌘⇧V で再度開けます |

## 開発

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

## ライセンス

Clipwharf は **GNU Affero General Public License v3.0（AGPL-3.0）** で提供されます。
商用を含め自由に使用・改変・再配布できますが、派生物やネットワークサービスは同じ
ライセンスでソースを公開する必要があります。

コピーレフトを受け入れられない製品向けに**商用ライセンス**を用意しています。価格と条件は
[COMMERCIAL.md](COMMERCIAL.md)、貢献については [CONTRIBUTING.md](CONTRIBUTING.md) を参照。

著作権および通知は [NOTICE](NOTICE) を参照。
