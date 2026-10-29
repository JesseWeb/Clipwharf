# Install Clipwharf with an AI agent

Clipwharf has no installer and no download button on purpose: you build it from
source on your own Mac, so the app carries **your** code signature. That makes
the build step the only awkward part — which is exactly what a coding agent can
do for you.

## What you need

- macOS 13 or newer with Xcode 15+ installed (`xcodebuild -version` must work)
- A coding agent that can run shell commands: Claude Code, Codex, Cursor,
  Gemini CLI, or similar

## Copy-paste prompt

### 简体中文

> 帮我在这台 Mac 上安装 Clipwharf：
> 1. 把 https://github.com/JesseWeb/Clipwharf 克隆到 ~/Developer/Clipwharf
> 2. 阅读仓库里的 AGENTS.md，按它执行构建和测试
> 3. 用 `./scripts/make-app.sh release` 构建，然后把 `dist/Clipwharf.app` 安装到 /Applications
> 4. 启动后引导我完成「辅助功能」授权，并实际验证一次自动粘贴是否成功
> 5. 最后告诉我：签名用的是哪个身份、数据存在哪里、怎么卸载

### 繁體中文

> 幫我在這台 Mac 上安裝 Clipwharf：
> 1. 把 https://github.com/JesseWeb/Clipwharf clone 到 ~/Developer/Clipwharf
> 2. 閱讀倉庫裡的 AGENTS.md，依它執行建置與測試
> 3. 用 `./scripts/make-app.sh release` 建置，並把 `dist/Clipwharf.app` 安裝到 /Applications
> 4. 啟動後引導我完成「輔助使用」授權，並實際驗證一次自動貼上是否成功
> 5. 最後告訴我：簽章用的是哪個身分、資料存在哪裡、如何移除

### English

> Install Clipwharf on this Mac:
> 1. Clone https://github.com/JesseWeb/Clipwharf to ~/Developer/Clipwharf
> 2. Read AGENTS.md in the repo and follow it for the build and tests
> 3. Build with `./scripts/make-app.sh release` and install `dist/Clipwharf.app` to /Applications
> 4. Launch it, walk me through the Accessibility grant, and verify that auto-paste actually works
> 5. Then tell me which signing identity was used, where the data lives, and how to uninstall

### 日本語

> この Mac に Clipwharf を入れてください：
> 1. https://github.com/JesseWeb/Clipwharf を ~/Developer/Clipwharf に clone
> 2. リポジトリの AGENTS.md を読んで、その手順でビルドとテストを実行
> 3. `./scripts/make-app.sh release` でビルドし、`dist/Clipwharf.app` を /Applications に導入
> 4. 起動後、アクセシビリティの許可を案内し、自動貼り付けが実際に動くか確認
> 5. 最後に、使用した署名 ID・データの場所・アンインストール方法を教えてください

### Français

> Installe Clipwharf sur ce Mac :
> 1. Clone https://github.com/JesseWeb/Clipwharf dans ~/Developer/Clipwharf
> 2. Lis AGENTS.md et suis-le pour la compilation et les tests
> 3. Compile avec `./scripts/make-app.sh release` et installe `dist/Clipwharf.app` dans /Applications
> 4. Lance l'app, guide-moi pour l'autorisation Accessibilité, puis vérifie que le collage automatique fonctionne vraiment
> 5. Indique-moi ensuite l'identité de signature utilisée, l'emplacement des données et la procédure de désinstallation

### Español

> Instala Clipwharf en este Mac:
> 1. Clona https://github.com/JesseWeb/Clipwharf en ~/Developer/Clipwharf
> 2. Lee AGENTS.md y síguelo para compilar y ejecutar las pruebas
> 3. Compila con `./scripts/make-app.sh release` e instala `dist/Clipwharf.app` en /Applications
> 4. Ábrelo, guíame con el permiso de Accesibilidad y verifica que el pegado automático funciona de verdad
> 5. Dime qué identidad de firma se usó, dónde están los datos y cómo desinstalarlo

## What the agent will do

1. Check macOS/Xcode versions.
2. `git clone` the repository into a working folder.
3. `swift test` (31 core tests, no UI) and `./scripts/make-app.sh release`.
4. Copy the bundle to `/Applications/Clipwharf.app` and launch it.
5. Ask you to switch Clipwharf on under
   **System Settings → Privacy & Security → Accessibility**, then verify a paste
   into TextEdit.

## What the agent cannot do for you

- Flip the Accessibility switch. macOS only accepts that from a human in System
  Settings. The agent can open the right pane and tell you what to toggle.
- Approve the login item, if you enable *Launch at Login*.

## If something goes wrong

| Message | Meaning |
|---|---|
| `xcodebuild: error: tool 'xcodebuild' requires Xcode` | Only Command Line Tools are installed — install Xcode |
| The Accessibility switch is on but Clipwharf still asks | Ad-hoc signature changed after a rebuild: menu-bar icon → **Fix Accessibility Permission…** |
| `⌘⇧V does nothing` | Another clipboard manager owns the shortcut |
| "Clipwharf.app would like to access data from other apps" | Expected macOS privacy prompt the first time QuickLook previews a foreign file |

All of this is also in [`AGENTS.md`](../AGENTS.md) and the
[README](../README.md).
