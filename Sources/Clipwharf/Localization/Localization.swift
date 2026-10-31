import Combine
import Foundation
import ClipwharfCore

/// Interface text for every supported language.
///
/// The tables live in code rather than in `.lproj` resources: the app needs a
/// user-selectable language (not just the system one), and a dictionary avoids
/// shipping a resource bundle that the build script would have to copy by hand.
final class Localization: ObservableObject {
    static let shared = Localization()

    @Published private(set) var selection: AppLanguage

    private let defaults: UserDefaults
    private static let defaultsKey = "app.language"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.string(forKey: Self.defaultsKey).flatMap(AppLanguage.init(rawValue:))
        self.selection = saved ?? .system
    }

    /// The language actually drawn, after resolving `.system`.
    var language: AppLanguage {
        AppLanguage.effective(selection: selection)
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    func setLanguage(_ new: AppLanguage) {
        defaults.set(new.rawValue, forKey: Self.defaultsKey)
        selection = new
        objectWillChange.send()
    }

    // MARK: - Lookup

    func t(_ key: String) -> String {
        Self.table(for: language)[key] ?? Self.english[key] ?? key
    }

    func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    /// Relative timestamps ("3 minutes ago") in the selected language.
    func relativeTime(for date: Date, now: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }

    // MARK: - Tables

    private static func table(for language: AppLanguage) -> [String: String] {
        switch language {
        case .simplifiedChinese: return simplifiedChinese
        case .traditionalChinese: return traditionalChinese
        case .japanese: return japanese
        case .french: return french
        case .spanish: return spanish
        case .system, .english: return english
        }
    }

    private static let english: [String: String] = [
        "panel.search": "Search clips",
        "panel.clearSearch": "Clear search",
        "panel.tab.history": "History",
        "panel.tab.pinned": "Pinned",
        "panel.count.one": "%d entry",
        "panel.count.other": "%d entries",
        "panel.count.filtered": "%d of %d",
        "panel.empty.clips.title": "No clips yet",
        "panel.empty.clips.body": "Copy text, an image, or files, then press ⌘⇧V.",
        "panel.empty.pins.title": "No pins yet",
        "panel.empty.pins.body": "Select a card and press ⌘P to keep it here.",
        "panel.empty.matches.title": "No matches",
        "panel.empty.matches.body": "No clips match this search.",
        "panel.footer.select": "←→ Select",
        "panel.footer.pin": "⌘P Pin",
        "panel.footer.tabs": "⌘1/2 Tabs",
        "panel.footer.paste": "⏎ Paste",
        "panel.footer.close": "esc Close",
        "card.kind.text": "Text",
        "card.kind.link": "Link",
        "card.kind.image": "Image",
        "card.kind.files": "File",
        "card.kind.color": "Color",
        "card.characters.one": "1 character",
        "card.characters.other": "%d characters",
        "card.files.one": "1 file",
        "card.files.other": "%d files",
        "card.rgb": "RGB %d, %d, %d",
        "card.image": "Image",
        "card.pin": "Pin",
        "card.unpin": "Unpin",
        "card.copy": "Copy",
        "menu.open": "Open History (⌘⇧V)",
        "menu.launchAtLogin": "Launch at Login",
        "menu.fixAccess": "Fix Accessibility Permission…",
        "menu.about": "About Clipwharf",
        "menu.quit": "Quit Clipwharf",
        "menu.language": "Language",
        "menu.language.system": "System",
        "tooltip": "Clipwharf — clipboard history (⌘⇧V)",
        "alert.access.title": "Clipwharf needs Accessibility access to auto-paste",
        "alert.access.body": """
        The clip is on your clipboard — press ⌘V to paste it now.

        If System Settings already shows Clipwharf switched on, that grant belongs \
        to an older build: rebuilding the app gives it a new code identity. Use \
        “Fix Permission…” to clear the stale entry and grant access again.
        """,
        "alert.fix": "Fix Permission…",
        "alert.notNow": "Not Now",
        "alert.login.title": "Approve Clipwharf in Login Items",
        "alert.login.body": """
        macOS added Clipwharf to your login items but needs you to allow it.

        Turn on Clipwharf under System Settings → General → Login Items.
        """,
        "alert.openSettings": "Open Settings…",
        "alert.later": "Later",
        "alert.hotkey.title": "⌘⇧V is already in use",
        "alert.hotkey.body": """
        Another app has claimed the global shortcut, so Clipwharf could not \
        register it. You can still open history from the paperclip menu-bar icon.
        """,
        "alert.ok": "OK",
        "alert.error.loginItem": "Could not update the login item",
        "alert.error.restore": "Could not restore this clip",
        "about.tagline": "A tiny, local clipboard history for macOS.",
        "about.body": """
        %@

        Version %@ · %@
        Free and local. No accounts, no cloud, no tracking.

        Source: %@
        """,
        "about.done": "Done",
        "error.missingContent": "This entry no longer has any content to paste.",
        "error.unreadableImage": "The saved image could not be read."
    ]

    private static let simplifiedChinese: [String: String] = [
        "panel.search": "搜索剪贴记录",
        "panel.clearSearch": "清除搜索",
        "panel.tab.history": "历史",
        "panel.tab.pinned": "固定",
        "panel.count.one": "%d 条",
        "panel.count.other": "%d 条",
        "panel.count.filtered": "%d / %d",
        "panel.empty.clips.title": "还没有记录",
        "panel.empty.clips.body": "复制文字、图片或文件，然后按 ⌘⇧V。",
        "panel.empty.pins.title": "还没有固定项",
        "panel.empty.pins.body": "选中卡片后按 ⌘P 固定到这里。",
        "panel.empty.matches.title": "没有匹配",
        "panel.empty.matches.body": "没有记录符合这个搜索。",
        "panel.footer.select": "←→ 选择",
        "panel.footer.pin": "⌘P 固定",
        "panel.footer.tabs": "⌘1/2 页签",
        "panel.footer.paste": "⏎ 粘贴",
        "panel.footer.close": "esc 关闭",
        "card.kind.text": "文本",
        "card.kind.link": "链接",
        "card.kind.image": "图片",
        "card.kind.files": "文件",
        "card.kind.color": "颜色",
        "card.characters.one": "1 个字符",
        "card.characters.other": "%d 个字符",
        "card.files.one": "1 个文件",
        "card.files.other": "%d 个文件",
        "card.rgb": "RGB %d, %d, %d",
        "card.image": "图片",
        "card.pin": "固定",
        "card.unpin": "取消固定",
        "card.copy": "复制",
        "menu.open": "打开历史（⌘⇧V）",
        "menu.launchAtLogin": "登录时启动",
        "menu.fixAccess": "修复辅助功能权限…",
        "menu.about": "关于 Clipwharf",
        "menu.quit": "退出 Clipwharf",
        "menu.language": "语言",
        "menu.language.system": "跟随系统",
        "tooltip": "Clipwharf — 剪贴板历史（⌘⇧V）",
        "alert.access.title": "Clipwharf 需要辅助功能权限才能自动粘贴",
        "alert.access.body": """
        内容已经在剪贴板里了 —— 现在按 ⌘V 即可粘贴。

        如果系统设置里 Clipwharf 已经打开，那可能是旧版本留下的授权：重新构建会让 App \
        获得新的代码身份。点「修复权限…」可以清除失效记录并重新授权。
        """,
        "alert.fix": "修复权限…",
        "alert.notNow": "以后再说",
        "alert.login.title": "请在登录项中允许 Clipwharf",
        "alert.login.body": """
        macOS 已把 Clipwharf 加入登录项，但需要你手动允许。

        前往「系统设置 → 通用 → 登录项」打开 Clipwharf。
        """,
        "alert.openSettings": "打开设置…",
        "alert.later": "稍后",
        "alert.hotkey.title": "⌘⇧V 已被占用",
        "alert.hotkey.body": """
        另一个 App 已注册这个全局快捷键，Clipwharf 无法注册。你仍然可以点菜单栏的 \
        回形针图标打开历史。
        """,
        "alert.ok": "好",
        "alert.error.loginItem": "无法更新登录项",
        "alert.error.restore": "无法恢复这条记录",
        "about.tagline": "极简、纯本地的 macOS 剪贴板历史工具。",
        "about.body": """
        %@

        版本 %@ · %@
        免费、纯本地。无账号、无云端、无追踪。

        源码：%@
        """,
        "about.done": "完成",
        "error.missingContent": "这条记录已经没有可粘贴的内容了。",
        "error.unreadableImage": "保存的图片无法读取。"
    ]

    private static let traditionalChinese: [String: String] = [
        "panel.search": "搜尋剪貼記錄",
        "panel.clearSearch": "清除搜尋",
        "panel.tab.history": "歷史",
        "panel.tab.pinned": "固定",
        "panel.count.one": "%d 筆",
        "panel.count.other": "%d 筆",
        "panel.count.filtered": "%d / %d",
        "panel.empty.clips.title": "還沒有記錄",
        "panel.empty.clips.body": "複製文字、圖片或檔案，然後按 ⌘⇧V。",
        "panel.empty.pins.title": "還沒有固定項目",
        "panel.empty.pins.body": "選取卡片後按 ⌘P 固定到這裡。",
        "panel.empty.matches.title": "沒有符合",
        "panel.empty.matches.body": "沒有記錄符合這個搜尋。",
        "panel.footer.select": "←→ 選擇",
        "panel.footer.pin": "⌘P 固定",
        "panel.footer.tabs": "⌘1/2 分頁",
        "panel.footer.paste": "⏎ 貼上",
        "panel.footer.close": "esc 關閉",
        "card.kind.text": "文字",
        "card.kind.link": "連結",
        "card.kind.image": "圖片",
        "card.kind.files": "檔案",
        "card.kind.color": "顏色",
        "card.characters.one": "1 個字元",
        "card.characters.other": "%d 個字元",
        "card.files.one": "1 個檔案",
        "card.files.other": "%d 個檔案",
        "card.rgb": "RGB %d, %d, %d",
        "card.image": "圖片",
        "card.pin": "固定",
        "card.unpin": "取消固定",
        "card.copy": "複製",
        "menu.open": "開啟歷史（⌘⇧V）",
        "menu.launchAtLogin": "登入時啟動",
        "menu.fixAccess": "修復輔助使用權限…",
        "menu.about": "關於 Clipwharf",
        "menu.quit": "結束 Clipwharf",
        "menu.language": "語言",
        "menu.language.system": "跟隨系統",
        "tooltip": "Clipwharf — 剪貼簿歷史（⌘⇧V）",
        "alert.access.title": "Clipwharf 需要輔助使用權限才能自動貼上",
        "alert.access.body": """
        內容已在剪貼簿裡 —— 現在按 ⌘V 即可貼上。

        若系統設定中 Clipwharf 已經開啟，那可能是舊版本留下的授權：重新建置會讓 App \
        取得新的程式碼身分。按「修復權限…」可清除失效記錄並重新授權。
        """,
        "alert.fix": "修復權限…",
        "alert.notNow": "稍後再說",
        "alert.login.title": "請在登入項目中允許 Clipwharf",
        "alert.login.body": """
        macOS 已將 Clipwharf 加入登入項目，但需要你手動允許。

        前往「系統設定 → 一般 → 登入項目」開啟 Clipwharf。
        """,
        "alert.openSettings": "開啟設定…",
        "alert.later": "稍後",
        "alert.hotkey.title": "⌘⇧V 已被佔用",
        "alert.hotkey.body": """
        另一個 App 已註冊這個全域快速鍵，Clipwharf 無法註冊。你仍可點選單列的 \
        迴紋針圖示開啟歷史。
        """,
        "alert.ok": "好",
        "alert.error.loginItem": "無法更新登入項目",
        "alert.error.restore": "無法還原這筆記錄",
        "about.tagline": "極簡、純本機的 macOS 剪貼簿歷史工具。",
        "about.body": """
        %@

        版本 %@ · %@
        免費、純本機。無帳號、無雲端、無追蹤。

        原始碼：%@
        """,
        "about.done": "完成",
        "error.missingContent": "這筆記錄已經沒有可貼上的內容。",
        "error.unreadableImage": "儲存的圖片無法讀取。"
    ]

    private static let japanese: [String: String] = [
        "panel.search": "クリップを検索",
        "panel.clearSearch": "検索をクリア",
        "panel.tab.history": "履歴",
        "panel.tab.pinned": "ピン",
        "panel.count.one": "%d 件",
        "panel.count.other": "%d 件",
        "panel.count.filtered": "%d / %d",
        "panel.empty.clips.title": "クリップがありません",
        "panel.empty.clips.body": "テキスト・画像・ファイルをコピーして ⌘⇧V を押してください。",
        "panel.empty.pins.title": "ピンがありません",
        "panel.empty.pins.body": "カードを選んで ⌘P を押すとここに残ります。",
        "panel.empty.matches.title": "一致なし",
        "panel.empty.matches.body": "この検索に一致するクリップはありません。",
        "panel.footer.select": "←→ 選択",
        "panel.footer.pin": "⌘P ピン",
        "panel.footer.tabs": "⌘1/2 タブ",
        "panel.footer.paste": "⏎ 貼り付け",
        "panel.footer.close": "esc 閉じる",
        "card.kind.text": "テキスト",
        "card.kind.link": "リンク",
        "card.kind.image": "画像",
        "card.kind.files": "ファイル",
        "card.kind.color": "カラー",
        "card.characters.one": "1 文字",
        "card.characters.other": "%d 文字",
        "card.files.one": "1 ファイル",
        "card.files.other": "%d ファイル",
        "card.rgb": "RGB %d, %d, %d",
        "card.image": "画像",
        "card.pin": "ピン留め",
        "card.unpin": "ピン解除",
        "card.copy": "コピー",
        "menu.open": "履歴を開く（⌘⇧V）",
        "menu.launchAtLogin": "ログイン時に起動",
        "menu.fixAccess": "アクセシビリティ権限を修復…",
        "menu.about": "Clipwharf について",
        "menu.quit": "Clipwharf を終了",
        "menu.language": "言語",
        "menu.language.system": "システムに従う",
        "tooltip": "Clipwharf — クリップボード履歴（⌘⇧V）",
        "alert.access.title": "自動貼り付けにはアクセシビリティ権限が必要です",
        "alert.access.body": """
        クリップはクリップボードにあります。⌘V で貼り付けてください。

        システム設定で Clipwharf が既にオンなのに表示される場合、その許可は古いビルドの \
        ものです。再ビルドするとコード ID が変わります。「権限を修復…」で古い記録を \
        消して再許可できます。
        """,
        "alert.fix": "権限を修復…",
        "alert.notNow": "後で",
        "alert.login.title": "ログイン項目で Clipwharf を許可してください",
        "alert.login.body": """
        macOS は Clipwharf をログイン項目に追加しましたが、許可が必要です。

        「システム設定 → 一般 → ログイン項目」で Clipwharf をオンにしてください。
        """,
        "alert.openSettings": "設定を開く…",
        "alert.later": "後で",
        "alert.hotkey.title": "⌘⇧V は既に使用されています",
        "alert.hotkey.body": """
        別の App がこのグローバルショートカットを登録しているため、Clipwharf は \
        登録できませんでした。メニューバーのクリップアイコンからは開けます。
        """,
        "alert.ok": "OK",
        "alert.error.loginItem": "ログイン項目を更新できませんでした",
        "alert.error.restore": "このクリップを復元できませんでした",
        "about.tagline": "macOS 向けの、小さくて完全ローカルなクリップボード履歴ツール。",
        "about.body": """
        %@

        バージョン %@ · %@
        無料・ローカル。アカウントなし、クラウドなし、追跡なし。

        ソース：%@
        """,
        "about.done": "完了",
        "error.missingContent": "この項目には貼り付ける内容が残っていません。",
        "error.unreadableImage": "保存された画像を読み込めませんでした。"
    ]

    private static let french: [String: String] = [
        "panel.search": "Rechercher",
        "panel.clearSearch": "Effacer la recherche",
        "panel.tab.history": "Historique",
        "panel.tab.pinned": "Épingles",
        "panel.count.one": "%d élément",
        "panel.count.other": "%d éléments",
        "panel.count.filtered": "%d sur %d",
        "panel.empty.clips.title": "Aucun clip",
        "panel.empty.clips.body": "Copiez du texte, une image ou des fichiers, puis appuyez sur ⌘⇧V.",
        "panel.empty.pins.title": "Aucune épingle",
        "panel.empty.pins.body": "Sélectionnez une carte et appuyez sur ⌘P pour la garder ici.",
        "panel.empty.matches.title": "Aucun résultat",
        "panel.empty.matches.body": "Aucun clip ne correspond à cette recherche.",
        "panel.footer.select": "←→ Choisir",
        "panel.footer.pin": "⌘P Épingler",
        "panel.footer.tabs": "⌘1/2 Onglets",
        "panel.footer.paste": "⏎ Coller",
        "panel.footer.close": "esc Fermer",
        "card.kind.text": "Texte",
        "card.kind.link": "Lien",
        "card.kind.image": "Image",
        "card.kind.files": "Fichier",
        "card.kind.color": "Couleur",
        "card.characters.one": "1 caractère",
        "card.characters.other": "%d caractères",
        "card.files.one": "1 fichier",
        "card.files.other": "%d fichiers",
        "card.rgb": "RVB %d, %d, %d",
        "card.image": "Image",
        "card.pin": "Épingler",
        "card.unpin": "Détacher",
        "card.copy": "Copier",
        "menu.open": "Ouvrir l'historique (⌘⇧V)",
        "menu.launchAtLogin": "Lancer à l'ouverture de session",
        "menu.fixAccess": "Réparer l'autorisation Accessibilité…",
        "menu.about": "À propos de Clipwharf",
        "menu.quit": "Quitter Clipwharf",
        "menu.language": "Langue",
        "menu.language.system": "Système",
        "tooltip": "Clipwharf — historique du presse-papiers (⌘⇧V)",
        "alert.access.title": "Clipwharf a besoin de l'accès Accessibilité pour coller",
        "alert.access.body": """
        Le clip est dans le presse-papiers — appuyez sur ⌘V pour le coller.

        Si Clipwharf est déjà activé dans Réglages Système, cette autorisation \
        appartient à une ancienne version : recompiler l'app change son identité de \
        code. Utilisez « Réparer l'autorisation… » pour effacer l'ancienne entrée.
        """,
        "alert.fix": "Réparer l'autorisation…",
        "alert.notNow": "Plus tard",
        "alert.login.title": "Autorisez Clipwharf dans les éléments d'ouverture",
        "alert.login.body": """
        macOS a ajouté Clipwharf aux éléments d'ouverture mais attend votre accord.

        Activez Clipwharf dans Réglages Système → Général → Éléments d'ouverture.
        """,
        "alert.openSettings": "Ouvrir les réglages…",
        "alert.later": "Plus tard",
        "alert.hotkey.title": "⌘⇧V est déjà utilisé",
        "alert.hotkey.body": """
        Une autre app a pris ce raccourci global, Clipwharf n'a pas pu l'enregistrer. \
        L'icône trombone de la barre des menus reste disponible.
        """,
        "alert.ok": "OK",
        "alert.error.loginItem": "Impossible de mettre à jour l'élément d'ouverture",
        "alert.error.restore": "Impossible de restaurer ce clip",
        "about.tagline": "Un historique de presse-papiers minimaliste et 100 % local pour macOS.",
        "about.body": """
        %@

        Version %@ · %@
        Gratuit et local. Sans compte, sans cloud, sans suivi.

        Source : %@
        """,
        "about.done": "Terminé",
        "error.missingContent": "Cet élément n'a plus de contenu à coller.",
        "error.unreadableImage": "L'image enregistrée est illisible."
    ]

    private static let spanish: [String: String] = [
        "panel.search": "Buscar clips",
        "panel.clearSearch": "Borrar búsqueda",
        "panel.tab.history": "Historial",
        "panel.tab.pinned": "Fijados",
        "panel.count.one": "%d elemento",
        "panel.count.other": "%d elementos",
        "panel.count.filtered": "%d de %d",
        "panel.empty.clips.title": "Aún no hay clips",
        "panel.empty.clips.body": "Copia texto, una imagen o archivos y pulsa ⌘⇧V.",
        "panel.empty.pins.title": "Sin fijados",
        "panel.empty.pins.body": "Selecciona una tarjeta y pulsa ⌘P para conservarla aquí.",
        "panel.empty.matches.title": "Sin resultados",
        "panel.empty.matches.body": "Ningún clip coincide con la búsqueda.",
        "panel.footer.select": "←→ Elegir",
        "panel.footer.pin": "⌘P Fijar",
        "panel.footer.tabs": "⌘1/2 Pestañas",
        "panel.footer.paste": "⏎ Pegar",
        "panel.footer.close": "esc Cerrar",
        "card.kind.text": "Texto",
        "card.kind.link": "Enlace",
        "card.kind.image": "Imagen",
        "card.kind.files": "Archivo",
        "card.kind.color": "Color",
        "card.characters.one": "1 carácter",
        "card.characters.other": "%d caracteres",
        "card.files.one": "1 archivo",
        "card.files.other": "%d archivos",
        "card.rgb": "RGB %d, %d, %d",
        "card.image": "Imagen",
        "card.pin": "Fijar",
        "card.unpin": "Quitar",
        "card.copy": "Copiar",
        "menu.open": "Abrir historial (⌘⇧V)",
        "menu.launchAtLogin": "Iniciar al iniciar sesión",
        "menu.fixAccess": "Reparar permiso de Accesibilidad…",
        "menu.about": "Acerca de Clipwharf",
        "menu.quit": "Salir de Clipwharf",
        "menu.language": "Idioma",
        "menu.language.system": "Sistema",
        "tooltip": "Clipwharf — historial del portapapeles (⌘⇧V)",
        "alert.access.title": "Clipwharf necesita Accesibilidad para pegar solo",
        "alert.access.body": """
        El clip ya está en el portapapeles: pulsa ⌘V para pegarlo.

        Si Clipwharf ya aparece activado en Ajustes del Sistema, ese permiso pertenece \
        a una compilación anterior: recompilar cambia la identidad del código. Usa \
        «Reparar permiso…» para borrar el registro antiguo y concederlo de nuevo.
        """,
        "alert.fix": "Reparar permiso…",
        "alert.notNow": "Ahora no",
        "alert.login.title": "Permite Clipwharf en los ítems de inicio",
        "alert.login.body": """
        macOS añadió Clipwharf a los ítems de inicio pero necesita tu permiso.

        Actívalo en Ajustes del Sistema → General → Ítems de inicio.
        """,
        "alert.openSettings": "Abrir Ajustes…",
        "alert.later": "Más tarde",
        "alert.hotkey.title": "⌘⇧V ya está en uso",
        "alert.hotkey.body": """
        Otra app ha registrado ese atajo global, así que Clipwharf no pudo hacerlo. \
        El icono de clip en la barra de menús sigue funcionando.
        """,
        "alert.ok": "OK",
        "alert.error.loginItem": "No se pudo actualizar el ítem de inicio",
        "alert.error.restore": "No se pudo restaurar este clip",
        "about.tagline": "Un historial de portapapeles pequeño y totalmente local para macOS.",
        "about.body": """
        %@

        Versión %@ · %@
        Gratis y local. Sin cuentas, sin nube, sin rastreo.

        Código: %@
        """,
        "about.done": "Listo",
        "error.missingContent": "Este elemento ya no tiene contenido para pegar.",
        "error.unreadableImage": "No se pudo leer la imagen guardada."
    ]
}
