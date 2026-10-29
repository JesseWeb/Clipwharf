# Clipwharf

Un historial de portapapeles pequeño y totalmente local para macOS.

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/) [![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org) [![Release](https://img.shields.io/github/v/release/JesseWeb/Clipwharf)](https://github.com/JesseWeb/Clipwharf/releases) [![License](https://img.shields.io/badge/license-noncommercial-lightgrey)](LICENSE)

![Clipwharf: press ⌘⇧V, pick a card, it pastes](docs/demo.gif)

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Français](README.fr.md) · **[Español](README.es.md)**

Clipwharf es un historial de portapapeles **totalmente local** para macOS. Copia como siempre, pulsa **⌘⇧V**, elige una tarjeta y el contenido vuelve al portapapeles y se pega en la app que estabas usando.

Implementación independiente (clean-room), sin relación con Paste ni con otros gestores comerciales, y sin su código, recursos ni iconos. Sin cuenta, sin nube, sin telemetría: nada sale de tu Mac.

## Funciones

- **Cinco tipos de tarjeta**: texto, enlace, color, imagen y archivo. Los archivos se previsualizan con QuickLook (como en Finder); varios archivos forman una cuadrícula 2 × 2 con la insignia «+N».
- **Fijados**: `⌘P` fija una tarjeta. Los fijados tienen su propia pestaña y nunca se eliminan por el límite de 200 entradas.
- **Búsqueda**: sin distinguir mayúsculas, todas las palabras deben coincidir. Busca en el texto, nombres de archivo, dominio del enlace y el **nombre de la app de origen**.
- **Insignia de la app de origen** en cada tarjeta.
- **Gestores de contraseñas excluidos**: 1Password, Bitwarden, LastPass, Dashlane, Llavero, Passwords y Keeper no se guardan.
- **Inicio al iniciar sesión**: icono de la barra de menús → *Launch at Login*.
- **Solo local**: índice JSON y archivos PNG en `~/Library/Application Support/Clipwharf`.

## Requisitos

- macOS 13 Ventura o posterior
- Xcode 15 o posterior (Swift 5.9+)

## Instalación

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

## Primer uso

1. Aparece un clip en la barra de menús (sin icono en el Dock ni ventana principal; se cierra desde el menú contextual).
2. Copia texto, una imagen o un archivo y pulsa **⌘⇧V**.
3. Concede Accesibilidad para pegar automáticamente: **Ajustes del Sistema → Privacidad y seguridad → Accesibilidad → activa Clipwharf**. Sin permiso, el contenido se copia igualmente y se te pide pulsar ⌘V.

## Atajos

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

## Dónde están los datos

```
~/Library/Application Support/Clipwharf/
├── history.json   # índice, lo más reciente primero
└── Blobs/         # imágenes (<uuid>.png)
```

Todo es JSON y archivos normales. Sal de Clipwharf y borra esa carpeta para reiniciar.

## Firma y distribución (importante)

- **El repositorio solo contiene código fuente**: `dist/` está ignorado; no se versiona ningún `.app`, `.icns` ni certificado.
- `scripts/make-app.sh` usa la identidad de firma de **la máquina que compila**: certificado Apple Development si existe; si no, firma ad-hoc. No hay ningún nombre de desarrollador ni Team ID escrito en el código.
- Por eso tu compilación lleva **tu** identidad de código y no depende del certificado del mantenedor.
- **Firma ad-hoc y Accesibilidad**: macOS vincula el permiso a la identidad del código; con ad-hoc cambia en cada compilación, así que el interruptor puede parecer activado mientras el binario nuevo no lo está. Usa el icono de la barra de menús → **Fix Accessibility Permission…** y vuelve a activarlo. Las compilaciones con certificado estable conservan el permiso.
- **Distribuir un `.app` firmado a otras personas** requiere Developer ID y notarización, y la clave privada nunca debe publicarse; por eso el proyecto solo distribuye código.

## Solución de problemas

| Síntoma | Solución |
|---|---|
| El interruptor de Accesibilidad está activo pero sigue pidiendo permiso | Barra de menús → **Fix Accessibility Permission…** y actívalo de nuevo |
| ⌘⇧V no hace nada | Otro gestor (Paste, etc.) ocupa el atajo: ciérralo o usa el icono |
| «Clipwharf.app desea acceder a datos de otras apps» | Aviso de macOS al previsualizar con QuickLook un archivo de otra app: permite una vez |
| El panel se cierra al hacer clic en otra app | Es intencionado: se oculta al perder el foco. Vuelve a abrirlo con ⌘⇧V |

## Desarrollo

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

## Licencia

Clipwharf se distribuye bajo una **licencia no comercial de código disponible**. Puedes
usarlo, modificarlo y compartirlo con fines **no comerciales**; queda **prohibido** usarlo
comercialmente, venderlo o cobrar por él. El uso comercial requiere una licencia escrita aparte.

Los términos vinculantes están en [LICENSE](LICENSE). El uso comercial no autorizado constituye
un incumplimiento y puede perseguirse con indemnización de daños, restitución de beneficios,
costas y honorarios.

Licencias comerciales y precios: [COMMERCIAL.md](COMMERCIAL.md). Contribuir: [CONTRIBUTING.md](CONTRIBUTING.md).
