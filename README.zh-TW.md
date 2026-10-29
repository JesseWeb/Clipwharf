# Clipwharf

極簡、純本地的 macOS 剪貼簿歷史工具。

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/) [![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org) [![Release](https://img.shields.io/github/v/release/JesseWeb/Clipwharf)](https://github.com/JesseWeb/Clipwharf/releases) [![License](https://img.shields.io/badge/license-noncommercial-lightgrey)](LICENSE)

![Clipwharf: press ⌘⇧V, pick a card, it pastes](docs/demo.gif)

[English](README.md) · [简体中文](README.zh-CN.md) · **[繁體中文](README.zh-TW.md)** · [日本語](README.ja.md) · [Français](README.fr.md) · [Español](README.es.md)

Clipwharf 是一套純本地的 macOS 剪貼簿歷史工具。照平常複製，按 **⌘⇧V**，挑一張卡片，它會把內容放回剪貼簿並貼回你剛才使用的 App。

獨立實作（clean-room），與 Paste 等商業剪貼簿軟體沒有任何關聯，也不包含它們的程式碼、素材或圖示。沒有帳號、沒有雲端、沒有統計，資料不會離開你的 Mac。

## 功能

- **五種卡片**：文字、連結、顏色、圖片、檔案。檔案以系統 QuickLook 預覽（與 Finder 一致），一次複製多個檔案會顯示 2×2 縮圖與 “+N” 標記。
- **固定板**：`⌘P` 固定卡片，固定項目有獨立分頁，且不會被 200 筆上限淘汰。
- **搜尋**：不分大小寫，多個關鍵字需同時符合；可搜內文、檔名、連結網域，以及**來源 App 名稱**。
- **來源 App 標示**：每張卡片顯示複製時所在 App 的圖示。
- **略過密碼管理員**：1Password、Bitwarden、LastPass、Dashlane、鑰匙圈存取、Passwords、Keeper 的內容不會被記錄。
- **登入時啟動**：選單列圖示 → *Launch at Login*。
- **純本地**：`~/Library/Application Support/Clipwharf` 下的 JSON 索引與 PNG 圖檔。

## 系統需求

- macOS 13 Ventura 或更新版本
- Xcode 15 或更新版本（Swift 5.9+）

## 安裝

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

## 首次使用

1. 選單列出現迴紋針圖示（沒有 Dock 圖示、沒有主視窗；要退出請右鍵圖示 → Quit）。
2. 複製文字／圖片／檔案，按 **⌘⇧V**。
3. 開啟「輔助使用」權限讓它替你按 ⌘V：**系統設定 → 隱私權與安全性 → 輔助使用 → 開啟 Clipwharf**。未授權時仍會先放進剪貼簿，並提示你手動按 ⌘V。

## 快速鍵

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

## 資料位置

```
~/Library/Application Support/Clipwharf/
├── history.json   # 最新在前的索引
└── Blobs/         # 圖片資料（<uuid>.png）
```

全部是明文 JSON 與一般檔案。退出 Clipwharf 後刪除該目錄即可清空，不會寫入其他地方。

## 關於簽章與發佈（重要）

- **本倉庫只放原始碼，不含任何二進位檔或簽章素材**：`dist/` 已被 `.gitignore` 忽略，不會提交 `.app`、`.icns` 或憑證。
- `scripts/make-app.sh` 會偵測**建置者本機**的簽章身分：有 Apple Development 憑證就用，沒有則退回 ad-hoc 簽章；程式碼中沒有寫死任何開發者名稱或 Team ID。
- 因此在你自己的 Mac 上建置的 app 帶的是**你自己的**程式碼身分，與維護者的憑證無關，也不會因維護者憑證到期而失效。
- **ad-hoc 簽章與輔助使用**：macOS 會把授權綁在程式碼身分上，ad-hoc 身分每次重新建置都會改變，於是設定裡的開關看起來是開的、新的執行檔卻沒有權限。此時點選單列圖示 → **Fix Accessibility Permission…** 重置後重新授權；使用固定憑證的建置不受影響。
- **把簽好的 `.app` 發給別人是另一回事**：需要 Developer ID 加公證，且私鑰絕不能公開，因此本專案只發佈原始碼。

## 常見問題

| 現象 | 處理方式 |
|---|---|
| 輔助使用已開啟仍跳出提示 | 選單列圖示 → **Fix Accessibility Permission…**，再重新開啟 |
| ⌘⇧V 沒反應 | 可能被其他剪貼簿工具（如 Paste）佔用，先退出它 |
| 第一次預覽檔案時詢問「取用其他 App 的資料」 | macOS 隱私提示，允許一次即可 |
| 一點其他 App 面板就消失 | 這是設計：面板失焦會自動收起，再按 ⌘⇧V 即可 |

## 開發

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

## 授權

Clipwharf 採用**非商業原始碼授權（source-available, noncommercial）**。你可以基於**非商業目的**
使用、修改與散布它；但**不得**將其用於商業用途、販售或收費。商業使用需另行取得書面授權。

具法律效力的條款見 [LICENSE](LICENSE)。未經授權的商業使用構成違約，權利人可主張損害賠償、
返還所得利潤、訴訟費用及律師費。

商業授權與價格見 [COMMERCIAL.md](COMMERCIAL.md)；參與貢獻見 [CONTRIBUTING.md](CONTRIBUTING.md)。
