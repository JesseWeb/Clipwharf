# Clipwharf

A tiny, local-only clipboard history for macOS. Copy as usual, press **⌘⇧V**,
pick a card, and Clipwharf puts it back on the clipboard and pastes it into the
app you were using.

![The Clipwharf history strip](docs/screenshot.png)

**[English](#english)** · **[简体中文](#简体中文)** · **[繁體中文](#繁體中文)** ·
**[日本語](#日本語)** · **[Français](#français)** · **[Español](#español)**

---

## English

Clipwharf is an independent clean-room project. It is not affiliated with,
derived from, or endorsed by Paste or any other clipboard manager, and it
contains no code, assets, or icons from them. No account, no cloud, no
telemetry: nothing ever leaves your Mac.

### Features

- **Five card types** — text, link, color, image, and file. Files are previewed
  with QuickLook, the way Finder does it; several copied files become a 2 × 2
  grid with a “+N” badge.
- **Pinboards** — press ⌘P to keep a card. Pinned cards get their own tab and
  are never dropped by the 200-entry history limit.
- **Search** — case-insensitive, all words must match. Matches text, file
  names, link hosts, and the name of the app you copied from.
- **Source app badge** — every card shows which app it came from.
- **Password-manager exclusion** — content copied from 1Password, Bitwarden,
  LastPass, Dashlane, Keychain Access, Passwords, or Keeper is skipped.
- **Launch at login** — menu-bar icon → *Launch at Login*.
- **Local only** — plain JSON index plus a folder of PNG blobs under
  `~/Library/Application Support/Clipwharf`.

### Requirements

- macOS 13 Ventura or newer
- Xcode 15 or newer (Swift 5.9+); the Command Line Tools alone are not enough
  to build the app bundle script comfortably

### Install

**Option 1 — let an AI agent do it (fastest).** Paste this into Claude Code,
Codex, Cursor, or any coding agent that can run shell commands:

> Clone https://github.com/JesseWeb/Clipwharf into a folder, read `AGENTS.md`,
> build `Clipwharf.app` with `./scripts/make-app.sh release`, copy it to
> `/Applications`, launch it, then tell me exactly which Accessibility toggle to
> switch on and how to verify that auto-paste works.

The agent follows [`AGENTS.md`](AGENTS.md), which contains the build steps, the
permission sequence, and the pitfalls. A longer prompt with variations is in
[`docs/ai-install.md`](docs/ai-install.md).

**Option 2 — build it yourself.**

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
./scripts/make-app.sh release      # builds and signs dist/Clipwharf.app
open dist/Clipwharf.app
```

Then drag `dist/Clipwharf.app` into `/Applications` so macOS keeps the app (and
its permissions) in one place.

**Option 3 — nothing to download.** Clipwharf publishes no binaries; GitHub
Actions only compiles and tests each push. Build it yourself (option 2) so the
app is signed with your own identity.

### First run

1. A paperclip appears in the menu bar. Clipwharf has no Dock icon and no main
   window; quit it from the right-click menu.
2. Copy some text, an image, or a file, then press **⌘⇧V**.
3. Grant Accessibility so Clipwharf can press ⌘V for you:
   **System Settings → Privacy & Security → Accessibility → switch Clipwharf on.**
   Without it, Clipwharf still puts the clip on your clipboard and asks you to
   press ⌘V yourself.

### Shortcuts

| Key | Action |
|---|---|
| ⌘⇧V | Open or close the strip (global) |
| ← / → | Move the selection |
| ⏎ | Paste the selected card |
| ⌘P | Pin / unpin the selected card |
| ⌘1 / ⌘2 | History / Pinned tab |
| esc | Close the strip |
| click | Paste that card |
| right-click | Pin/Unpin, Copy |

### Where data lives

```
~/Library/Application Support/Clipwharf/
├── history.json   # newest-first index
└── Blobs/         # image payloads (<uuid>.png)
```

Everything is plain JSON and files. Quit Clipwharf and delete that folder to
reset. Nothing is written anywhere else.

### Signing, and why this repository ships source only

- **No binaries and no signing material are committed.** `dist/` is ignored, so
  the repository never contains a `.app`, an `.icns`, or a certificate.
- `scripts/make-app.sh` detects the **building machine's** signing identity: it
  uses an Apple Development certificate if that Mac has one, and otherwise falls
  back to ad-hoc signing. No developer name or team ID is hard-coded.
- So a build on your Mac carries *your* code identity. It does not use, borrow,
  or depend on anybody else's certificate, and the maintainer's certificate is
  irrelevant to your copy.
- **Ad-hoc builds and Accessibility:** macOS ties an Accessibility grant to the
  code identity. An ad-hoc identity changes on every rebuild, so the switch in
  System Settings can look “on” while the new binary is untrusted. Fix it from
  the menu-bar icon → **Fix Accessibility Permission…**, which resets the stale
  record and asks again. Builds signed with a stable certificate keep the grant
  across rebuilds.
- **Distributing a signed `.app` to other people is a different problem:** they
  would need a Developer ID signature plus notarization, and the signing key
  must never be published. This project deliberately avoids that by shipping
  source and letting everyone sign locally.

### Troubleshooting

| Symptom | Fix |
|---|---|
| “Clipwharf needs Accessibility access” although the switch is on | Menu-bar icon → **Fix Accessibility Permission…**, then switch Clipwharf on again |
| ⌘⇧V does nothing | Another clipboard manager (e.g. Paste) owns the shortcut; quit it or use the menu-bar icon |
| “Clipwharf.app would like to access data from other apps” | macOS privacy prompt shown the first time QuickLook previews a file owned by another app — allow it once |
| The strip closes when I click another app | By design: it hides when it loses focus. Press ⌘⇧V to bring it back |
| History looks empty after an update | The index is per-user; check `~/Library/Application Support/Clipwharf/history.json` |

### Development

```sh
swift test                                  # core model, storage, search, classification
swift build -c release --product Clipwharf  # compile only
./scripts/make-app.sh debug                 # debug build of the .app
swift scripts/make-icon.swift               # regenerate Support/AppIcon.png
```

### License

MIT. See [LICENSE](LICENSE).

---

## 简体中文

Clipwharf 是一个纯本地的 macOS 剪贴板历史工具。照常复制，按 **⌘⇧V**，选一张卡片，它会把内容放回剪贴板并粘贴到你刚才使用的 App 里。

独立实现（clean-room），与 Paste 等商业剪贴板管理软件没有关联，也不包含它们的任何代码、素材或图标。无账号、无云端、无统计，数据不会离开你的 Mac。

### 功能

- **五种卡片**：文本、链接、颜色、图片、文件。文件用系统 QuickLook 预览（和访达一致），一次复制多个文件会显示 2×2 缩略图网格和 “+N” 角标。
- **固定板**：`⌘P` 固定卡片，固定项有独立页签，且不会被 200 条历史上限淘汰。
- **搜索**：忽略大小写，多个词需同时匹配；可搜正文、文件名、链接域名，以及**来源 App 名称**。
- **来源 App 标识**：每张卡片显示复制时所在 App 的图标。
- **跳过密码管理器**：1Password、Bitwarden、LastPass、Dashlane、钥匙串访问、Passwords、Keeper 复制的内容不会入库。
- **登录时启动**：菜单栏图标 → *Launch at Login*。
- **纯本地**：`~/Library/Application Support/Clipwharf` 下的 JSON 索引 + PNG 图片目录。

### 系统要求

- macOS 13 Ventura 或更新
- Xcode 15 或更新（Swift 5.9+）

### 安装

**方式一：让 AI 帮你装（最省事）**

把下面这段发给 Claude Code / Codex / Cursor 等能执行命令的 AI 编程工具：

> 把 https://github.com/JesseWeb/Clipwharf 克隆到本地，阅读 AGENTS.md，
> 用 `./scripts/make-app.sh release` 构建 Clipwharf.app 并安装到 /Applications，
> 启动后告诉我需要在辅助功能里打开哪一项、以及怎么验证自动粘贴生效。

AI 会按 [`AGENTS.md`](AGENTS.md) 里的步骤构建、安装并引导授权；更多提示词变体见 [`docs/ai-install.md`](docs/ai-install.md)。

**方式二：自己构建**

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
./scripts/make-app.sh release
open dist/Clipwharf.app
```

构建完把 `dist/Clipwharf.app` 拖进 `/Applications`，以后就从那里启动（权限也记在这个路径上）。

**方式三：无需下载。**

Clipwharf 不发布任何二进制，GitHub Actions 只做编译与测试校验。请用方式二在本地构建，这样 app 带的是你自己的代码身份。

### 首次使用

1. 菜单栏出现回形针图标（无 Dock 图标、无主窗口；退出请右键图标 → Quit）。
2. 复制一段文字 / 一张图片 / 一个文件，按 **⌘⇧V**。
3. 打开辅助功能授权，让它能替你按 ⌘V：**系统设置 → 隐私与安全性 → 辅助功能 → 打开 Clipwharf**。未授权时会先把内容放进剪贴板，并提示你手动按 ⌘V。

### 快捷键

| 按键 | 作用 |
|---|---|
| ⌘⇧V | 打开/关闭历史面板（全局） |
| ← / → | 移动选中卡片 |
| ⏎ | 粘贴选中项 |
| ⌘P | 固定/取消固定 |
| ⌘1 / ⌘2 | 历史 / 固定页签 |
| esc | 关闭面板 |
| 单击 | 粘贴该卡片 |
| 右键 | 固定/取消固定、复制 |

### 数据位置

```
~/Library/Application Support/Clipwharf/
├── history.json   # 最新在前的索引
└── Blobs/         # 图片数据（<uuid>.png）
```

全部是明文 JSON 和普通文件。退出 Clipwharf 后删除该目录即可清空，不会写入其他位置。

### 关于签名与分发（重要）

- **仓库只放源码，不含任何二进制或签名材料**：`dist/` 已被 `.gitignore` 忽略，不会提交 `.app`、`.icns` 或证书。
- `scripts/make-app.sh` 使用的是**构建者本机**的签名身份：有 Apple Development 证书就用它，没有就退回 ad-hoc 签名。代码里没有硬编码任何开发者名称或 Team ID。
- 因此你在自己 Mac 上构建出来的 app 带的是**你自己的**代码身份，跟维护者的证书毫无关系，也不会因为维护者证书到期而受影响。
- **ad-hoc 签名与辅助功能**：macOS 把授权绑定在代码身份上。ad-hoc 身份每次重新构建都会变，于是列表里的开关看着是开的、新二进制却没权限。此时点菜单栏图标 → **Fix Accessibility Permission…** 重置后重新授权即可；用固定证书签名的构建不受影响。
- **把签好的 `.app` 发给别人是另一回事**：那需要 Developer ID + 公证，而且私钥绝不能公开。所以本项目只分发源码，让每个人在本地自行签名。

### 常见问题

| 现象 | 处理 |
|---|---|
| 辅助功能开关已打开，仍提示需要权限 | 菜单栏图标 → **Fix Accessibility Permission…**，再重新打开开关 |
| ⌘⇧V 没反应 | 可能被其他剪贴板工具（如 Paste）占用，退出它或用菜单栏图标 |
| 首次预览文件时提示“想访问其他 App 的数据” | macOS 隐私提示，允许一次即可 |
| 一点其他 App 面板就消失 | 这是设计：面板失焦会自动收起，再按 ⌘⇧V 即可 |
| 更新后历史为空 | 索引按用户存储，检查 `~/Library/Application Support/Clipwharf/history.json` |

### 开发

```sh
swift test                                  # 核心模型/存储/搜索/分类
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
swift scripts/make-icon.swift               # 重新生成 Support/AppIcon.png
```

### 许可

MIT，见 [LICENSE](LICENSE)。

---

## 繁體中文

Clipwharf 是一套純本地的 macOS 剪貼簿歷史工具。照平常複製，按 **⌘⇧V**，挑一張卡片，它會把內容放回剪貼簿並貼回你剛才使用的 App。

獨立實作（clean-room），與 Paste 等商業剪貼簿軟體沒有任何關聯，也不包含它們的程式碼、素材或圖示。沒有帳號、沒有雲端、沒有統計，資料不會離開你的 Mac。

### 功能

- **五種卡片**：文字、連結、顏色、圖片、檔案。檔案以系統 QuickLook 預覽（與 Finder 一致），一次複製多個檔案會顯示 2×2 縮圖與 “+N” 標記。
- **固定板**：`⌘P` 固定卡片，固定項目有獨立分頁，且不會被 200 筆上限淘汰。
- **搜尋**：不分大小寫，多個關鍵字需同時符合；可搜內文、檔名、連結網域，以及**來源 App 名稱**。
- **來源 App 標示**：每張卡片顯示複製時所在 App 的圖示。
- **略過密碼管理員**：1Password、Bitwarden、LastPass、Dashlane、鑰匙圈存取、Passwords、Keeper 的內容不會被記錄。
- **登入時啟動**：選單列圖示 → *Launch at Login*。
- **純本地**：`~/Library/Application Support/Clipwharf` 下的 JSON 索引與 PNG 圖檔。

### 系統需求

- macOS 13 Ventura 或更新版本
- Xcode 15 或更新版本（Swift 5.9+）

### 安裝

**方式一：交給 AI 安裝（最快）**

把下面這段貼給 Claude Code / Codex / Cursor 等可執行指令的 AI 工具：

> 將 https://github.com/JesseWeb/Clipwharf clone 到本機，閱讀 AGENTS.md，
> 用 `./scripts/make-app.sh release` 建置 Clipwharf.app 並安裝到 /Applications，
> 啟動後告訴我要在輔助使用裡開啟哪一項，以及如何驗證自動貼上成功。

AI 會依 [`AGENTS.md`](AGENTS.md) 的步驟建置、安裝並引導授權；更多提示詞見 [`docs/ai-install.md`](docs/ai-install.md)。

**方式二：自行建置**

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
./scripts/make-app.sh release
open dist/Clipwharf.app
```

建置完成後把 `dist/Clipwharf.app` 拖進 `/Applications`，之後都從那裡啟動（權限也綁在這個路徑）。

**方式三：無需下載。**

Clipwharf 不發佈任何二進位檔，GitHub Actions 只做編譯與測試檢查。請用方式二在本機建置，這樣 app 帶的是你自己的程式碼身分。

### 首次使用

1. 選單列出現迴紋針圖示（沒有 Dock 圖示、沒有主視窗；要退出請右鍵圖示 → Quit）。
2. 複製文字／圖片／檔案，按 **⌘⇧V**。
3. 開啟「輔助使用」權限讓它替你按 ⌘V：**系統設定 → 隱私權與安全性 → 輔助使用 → 開啟 Clipwharf**。未授權時仍會先放進剪貼簿，並提示你手動按 ⌘V。

### 快速鍵

| 按鍵 | 動作 |
|---|---|
| ⌘⇧V | 開啟／關閉面板（全域） |
| ← / → | 移動選取 |
| ⏎ | 貼上選取項目 |
| ⌘P | 固定／取消固定 |
| ⌘1 / ⌘2 | 歷史／固定分頁 |
| esc | 關閉面板 |
| 單擊 | 貼上該卡片 |
| 右鍵 | 固定／取消固定、複製 |

### 資料位置

```
~/Library/Application Support/Clipwharf/
├── history.json   # 最新在前的索引
└── Blobs/         # 圖片資料（<uuid>.png）
```

全部是明文 JSON 與一般檔案。退出 Clipwharf 後刪除該目錄即可清空，不會寫入其他地方。

### 關於簽章與發佈（重要）

- **本倉庫只放原始碼，不含任何二進位檔或簽章素材**：`dist/` 已被 `.gitignore` 忽略，不會提交 `.app`、`.icns` 或憑證。
- `scripts/make-app.sh` 會偵測**建置者本機**的簽章身分：有 Apple Development 憑證就用，沒有則退回 ad-hoc 簽章；程式碼中沒有寫死任何開發者名稱或 Team ID。
- 因此在你自己的 Mac 上建置的 app 帶的是**你自己的**程式碼身分，與維護者的憑證無關，也不會因維護者憑證到期而失效。
- **ad-hoc 簽章與輔助使用**：macOS 會把授權綁在程式碼身分上，ad-hoc 身分每次重新建置都會改變，於是設定裡的開關看起來是開的、新的執行檔卻沒有權限。此時點選單列圖示 → **Fix Accessibility Permission…** 重置後重新授權；使用固定憑證的建置不受影響。
- **把簽好的 `.app` 發給別人是另一回事**：需要 Developer ID 加公證，且私鑰絕不能公開，因此本專案只發佈原始碼。

### 常見問題

| 現象 | 處理方式 |
|---|---|
| 輔助使用已開啟仍跳出提示 | 選單列圖示 → **Fix Accessibility Permission…**，再重新開啟 |
| ⌘⇧V 沒反應 | 可能被其他剪貼簿工具（如 Paste）佔用，先退出它 |
| 第一次預覽檔案時詢問「取用其他 App 的資料」 | macOS 隱私提示，允許一次即可 |
| 一點其他 App 面板就消失 | 這是設計：面板失焦會自動收起，再按 ⌘⇧V 即可 |

### 開發

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

### 授權

MIT，見 [LICENSE](LICENSE)。

---

## 日本語

Clipwharf は macOS 用の**完全ローカル**なクリップボード履歴ツールです。いつもどおりコピーして **⌘⇧V** を押し、カードを選ぶと、クリップボードに戻して直前のアプリに貼り付けます。

Paste などの商用クリップボードマネージャとは無関係のクリーンルーム実装で、それらのコード・素材・アイコンは含みません。アカウント不要、クラウドなし、テレメトリなし。データは Mac の外に出ません。

### 機能

- **5 種類のカード**：テキスト、リンク、カラー、画像、ファイル。ファイルは Finder と同じ QuickLook でプレビューし、複数ファイルは 2×2 のサムネイルと “+N” バッジになります。
- **ピン**：`⌘P` でカードを固定。固定したカードは専用タブに入り、200 件の履歴上限でも削除されません。
- **検索**：大文字小文字を区別せず、複数語は AND 検索。本文・ファイル名・リンクのホスト・**コピー元アプリ名**を対象にします。
- **コピー元アプリのバッジ**：各カードにコピー時のアプリのアイコンを表示。
- **パスワードマネージャを除外**：1Password、Bitwarden、LastPass、Dashlane、キーチェーンアクセス、Passwords、Keeper からのコピーは保存しません。
- **ログイン時に起動**：メニューバーのアイコン → *Launch at Login*。
- **ローカルのみ**：`~/Library/Application Support/Clipwharf` に JSON と PNG。

### 動作環境

- macOS 13 Ventura 以降
- Xcode 15 以降（Swift 5.9 以降）

### インストール

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

**方法 3：ダウンロードするものはありません。**

Clipwharf はバイナリを配布しません。GitHub Actions はコンパイルとテストの確認のみを行います。アプリに自分のコード ID を持たせるため、方法 2 でローカルにビルドしてください。

### 初回起動

1. メニューバーにクリップのアイコンが現れます（Dock アイコンもメインウィンドウもありません。終了は右クリック → Quit）。
2. テキスト・画像・ファイルをコピーして **⌘⇧V**。
3. 自動貼り付けのためにアクセシビリティを許可：**システム設定 → プライバシーとセキュリティ → アクセシビリティ → Clipwharf をオン**。未許可でもクリップボードには入り、⌘V を自分で押すよう案内されます。

### ショートカット

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

### データの場所

```
~/Library/Application Support/Clipwharf/
├── history.json   # 新しい順のインデックス
└── Blobs/         # 画像データ（<uuid>.png）
```

すべて平文の JSON とファイルです。Clipwharf を終了してこのフォルダを削除すれば初期化できます。

### 署名と配布について（重要）

- **リポジトリにはソースのみ**。`dist/` は `.gitignore` 済みで、`.app`・`.icns`・証明書は含まれません。
- `scripts/make-app.sh` は**ビルドする Mac の**署名 ID を使います（Apple Development 証明書があればそれ、なければ ad-hoc）。特定の開発者名や Team ID は埋め込まれていません。
- したがって、あなたがビルドしたアプリは**あなた自身の**コード ID を持ち、メンテナの証明書とは無関係です。
- **ad-hoc 署名とアクセシビリティ**：macOS は許可をコード ID に結び付けるため、ad-hoc では再ビルドのたびに無効になります（設定のスイッチがオンに見えても実際は無効）。メニューバー → **Fix Accessibility Permission…** でリセットして再許可してください。固定証明書で署名したビルドは影響を受けません。
- **署名済み `.app` を他人に配る場合は別問題**で、Developer ID と公証が必要です。秘密鍵を公開できないため、本プロジェクトはソース配布のみとしています。

### トラブルシューティング

| 症状 | 対処 |
|---|---|
| アクセシビリティがオンなのに毎回ダイアログが出る | メニューバー → **Fix Accessibility Permission…** の後に再度オンにする |
| ⌘⇧V が効かない | 他のクリップボードツール（Paste など）が占有している可能性。終了するかメニューバーから開く |
| 「他のアプリのデータへのアクセス」を求められる | QuickLook プレビュー時の macOS の確認。一度許可すれば以後は出ません |
| 他のアプリをクリックするとパネルが閉じる | 仕様です（フォーカスを失うと隠れます）。⌘⇧V で再度開けます |

### 開発

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

### ライセンス

MIT。[LICENSE](LICENSE) を参照。

---

## Français

Clipwharf est un historique de presse-papiers **entièrement local** pour macOS. Copiez comme d'habitude, appuyez sur **⌘⇧V**, choisissez une carte : le contenu retourne dans le presse-papiers et se colle dans l'application que vous utilisiez.

Implémentation indépendante (clean-room), sans lien avec Paste ni aucun autre gestionnaire commercial, et sans aucun de leurs codes, ressources ou icônes. Pas de compte, pas de cloud, pas de télémétrie : rien ne quitte votre Mac.

### Fonctionnalités

- **Cinq types de cartes** : texte, lien, couleur, image, fichier. Les fichiers sont prévisualisés avec QuickLook (comme le Finder) ; plusieurs fichiers donnent une grille 2 × 2 avec un badge « +N ».
- **Épingles** : `⌘P` épingle une carte. Les épingles ont leur propre onglet et ne sont jamais supprimées par la limite de 200 entrées.
- **Recherche** : insensible à la casse, tous les mots doivent correspondre. Cherche dans le texte, les noms de fichiers, l'hôte des liens et le **nom de l'application source**.
- **Badge de l'application source** : chaque carte indique d'où elle vient.
- **Gestionnaires de mots de passe ignorés** : 1Password, Bitwarden, LastPass, Dashlane, Trousseau d'accès, Passwords et Keeper ne sont pas enregistrés.
- **Lancement à l'ouverture de session** : icône de la barre des menus → *Launch at Login*.
- **100 % local** : index JSON et fichiers PNG dans `~/Library/Application Support/Clipwharf`.

### Prérequis

- macOS 13 Ventura ou plus récent
- Xcode 15 ou plus récent (Swift 5.9+)

### Installation

**Option 1 — laisser un agent IA le faire (le plus rapide).** Collez ceci dans Claude Code, Codex, Cursor ou tout agent capable d'exécuter des commandes :

> Clone https://github.com/JesseWeb/Clipwharf, lis AGENTS.md, construis Clipwharf.app avec `./scripts/make-app.sh release`, installe-le dans /Applications, lance-le, puis indique-moi précisément quel réglage d'Accessibilité activer et comment vérifier que le collage automatique fonctionne.

Les étapes détaillées sont dans [`AGENTS.md`](AGENTS.md), avec des variantes de prompt dans [`docs/ai-install.md`](docs/ai-install.md).

**Option 2 — compiler soi-même.**

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
./scripts/make-app.sh release
open dist/Clipwharf.app
```

Déplacez ensuite `dist/Clipwharf.app` dans `/Applications` (les autorisations sont liées à ce chemin).

**Option 3 — rien à télécharger.** Clipwharf ne publie aucun binaire ; GitHub
Actions se contente de compiler et tester à chaque push. Compilez localement
(option 2) pour que l'app porte votre propre identité de signature.

### Premier lancement

1. Un trombone apparaît dans la barre des menus (pas d'icône dans le Dock, pas de fenêtre principale ; quitter via le menu contextuel).
2. Copiez du texte, une image ou un fichier, puis appuyez sur **⌘⇧V**.
3. Accordez l'Accessibilité pour le collage automatique : **Réglages Système → Confidentialité et sécurité → Accessibilité → activez Clipwharf.** Sans cela, le contenu est quand même copié et Clipwharf vous demande de faire ⌘V vous-même.

### Raccourcis

| Touche | Action |
|---|---|
| ⌘⇧V | Ouvrir/fermer le panneau (global) |
| ← / → | Déplacer la sélection |
| ⏎ | Coller la carte sélectionnée |
| ⌘P | Épingler / désépingler |
| ⌘1 / ⌘2 | Onglet Historique / Épingles |
| esc | Fermer |
| clic | Coller cette carte |
| clic droit | Épingler/désépingler, copier |

### Emplacement des données

```
~/Library/Application Support/Clipwharf/
├── history.json   # index du plus récent au plus ancien
└── Blobs/         # images (<uuid>.png)
```

Tout est en JSON et en fichiers simples. Quittez Clipwharf et supprimez ce dossier pour repartir de zéro.

### Signature et distribution (important)

- **Le dépôt ne contient que le code source** : `dist/` est ignoré, aucun `.app`, `.icns` ni certificat n'est versionné.
- `scripts/make-app.sh` utilise l'identité de signature de **la machine qui compile** : certificat Apple Development s'il existe, sinon signature ad-hoc. Aucun nom de développeur ni Team ID n'est codé en dur.
- Votre compilation porte donc **votre** identité de code, sans lien avec le certificat du mainteneur.
- **Signature ad-hoc et Accessibilité** : macOS lie l'autorisation à l'identité du code ; une identité ad-hoc change à chaque compilation, donc l'interrupteur peut paraître activé alors que le nouveau binaire n'est pas autorisé. Utilisez l'icône de la barre des menus → **Fix Accessibility Permission…** puis réactivez. Les compilations signées avec un certificat stable conservent l'autorisation.
- **Distribuer un `.app` signé à d'autres** exige un Developer ID et une notarisation, avec une clé privée qui ne doit jamais être publiée. C'est pourquoi le projet ne distribue que le code source.

### Dépannage

| Symptôme | Solution |
|---|---|
| L'interrupteur Accessibilité est activé mais la demande revient | Barre des menus → **Fix Accessibility Permission…**, puis réactivez |
| ⌘⇧V ne fait rien | Un autre gestionnaire (Paste, etc.) occupe le raccourci : quittez-le ou passez par l'icône |
| « Clipwharf.app souhaite accéder aux données d'autres apps » | Invite macOS lors du premier aperçu QuickLook d'un fichier appartenant à une autre app : autorisez une fois |
| Le panneau se ferme dès que je clique ailleurs | C'est voulu : il se masque en perdant le focus. Rouvrez-le avec ⌘⇧V |

### Développement

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

### Licence

MIT. Voir [LICENSE](LICENSE).

---

## Español

Clipwharf es un historial de portapapeles **totalmente local** para macOS. Copia como siempre, pulsa **⌘⇧V**, elige una tarjeta y el contenido vuelve al portapapeles y se pega en la app que estabas usando.

Implementación independiente (clean-room), sin relación con Paste ni con otros gestores comerciales, y sin su código, recursos ni iconos. Sin cuenta, sin nube, sin telemetría: nada sale de tu Mac.

### Funciones

- **Cinco tipos de tarjeta**: texto, enlace, color, imagen y archivo. Los archivos se previsualizan con QuickLook (como en Finder); varios archivos forman una cuadrícula 2 × 2 con la insignia «+N».
- **Fijados**: `⌘P` fija una tarjeta. Los fijados tienen su propia pestaña y nunca se eliminan por el límite de 200 entradas.
- **Búsqueda**: sin distinguir mayúsculas, todas las palabras deben coincidir. Busca en el texto, nombres de archivo, dominio del enlace y el **nombre de la app de origen**.
- **Insignia de la app de origen** en cada tarjeta.
- **Gestores de contraseñas excluidos**: 1Password, Bitwarden, LastPass, Dashlane, Llavero, Passwords y Keeper no se guardan.
- **Inicio al iniciar sesión**: icono de la barra de menús → *Launch at Login*.
- **Solo local**: índice JSON y archivos PNG en `~/Library/Application Support/Clipwharf`.

### Requisitos

- macOS 13 Ventura o posterior
- Xcode 15 o posterior (Swift 5.9+)

### Instalación

**Opción 1 — que lo haga un agente de IA (la más rápida).** Pega esto en Claude Code, Codex, Cursor o cualquier agente que pueda ejecutar comandos:

> Clona https://github.com/JesseWeb/Clipwharf, lee AGENTS.md, compila Clipwharf.app con `./scripts/make-app.sh release`, instálalo en /Applications, ábrelo y dime exactamente qué opción de Accesibilidad activar y cómo comprobar que el pegado automático funciona.

Los pasos están en [`AGENTS.md`](AGENTS.md); hay variantes del prompt en [`docs/ai-install.md`](docs/ai-install.md).

**Opción 2 — compilar tú mismo.**

```sh
git clone https://github.com/JesseWeb/Clipwharf.git
cd Clipwharf
./scripts/make-app.sh release
open dist/Clipwharf.app
```

Luego arrastra `dist/Clipwharf.app` a `/Applications` (los permisos quedan ligados a esa ruta).

**Opción 3 — no hay nada que descargar.** Clipwharf no publica binarios;
GitHub Actions solo compila y prueba en cada push. Compila en local (opción 2)
para que la app lleve tu propia identidad de firma.

### Primer uso

1. Aparece un clip en la barra de menús (sin icono en el Dock ni ventana principal; se cierra desde el menú contextual).
2. Copia texto, una imagen o un archivo y pulsa **⌘⇧V**.
3. Concede Accesibilidad para pegar automáticamente: **Ajustes del Sistema → Privacidad y seguridad → Accesibilidad → activa Clipwharf**. Sin permiso, el contenido se copia igualmente y se te pide pulsar ⌘V.

### Atajos

| Tecla | Acción |
|---|---|
| ⌘⇧V | Abrir/cerrar el panel (global) |
| ← / → | Mover la selección |
| ⏎ | Pegar la tarjeta seleccionada |
| ⌘P | Fijar / quitar fijado |
| ⌘1 / ⌘2 | Pestaña Historial / Fijados |
| esc | Cerrar |
| clic | Pegar esa tarjeta |
| clic derecho | Fijar/quitar, copiar |

### Dónde están los datos

```
~/Library/Application Support/Clipwharf/
├── history.json   # índice, lo más reciente primero
└── Blobs/         # imágenes (<uuid>.png)
```

Todo es JSON y archivos normales. Sal de Clipwharf y borra esa carpeta para reiniciar.

### Firma y distribución (importante)

- **El repositorio solo contiene código fuente**: `dist/` está ignorado; no se versiona ningún `.app`, `.icns` ni certificado.
- `scripts/make-app.sh` usa la identidad de firma de **la máquina que compila**: certificado Apple Development si existe; si no, firma ad-hoc. No hay ningún nombre de desarrollador ni Team ID escrito en el código.
- Por eso tu compilación lleva **tu** identidad de código y no depende del certificado del mantenedor.
- **Firma ad-hoc y Accesibilidad**: macOS vincula el permiso a la identidad del código; con ad-hoc cambia en cada compilación, así que el interruptor puede parecer activado mientras el binario nuevo no lo está. Usa el icono de la barra de menús → **Fix Accessibility Permission…** y vuelve a activarlo. Las compilaciones con certificado estable conservan el permiso.
- **Distribuir un `.app` firmado a otras personas** requiere Developer ID y notarización, y la clave privada nunca debe publicarse; por eso el proyecto solo distribuye código.

### Solución de problemas

| Síntoma | Solución |
|---|---|
| El interruptor de Accesibilidad está activo pero sigue pidiendo permiso | Barra de menús → **Fix Accessibility Permission…** y actívalo de nuevo |
| ⌘⇧V no hace nada | Otro gestor (Paste, etc.) ocupa el atajo: ciérralo o usa el icono |
| «Clipwharf.app desea acceder a datos de otras apps» | Aviso de macOS al previsualizar con QuickLook un archivo de otra app: permite una vez |
| El panel se cierra al hacer clic en otra app | Es intencionado: se oculta al perder el foco. Vuelve a abrirlo con ⌘⇧V |

### Desarrollo

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

### Licencia

MIT. Ver [LICENSE](LICENSE).
