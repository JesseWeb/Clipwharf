# Clipwharf

Un historique de presse-papiers minimaliste et 100 % local pour macOS.

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/) [![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org) [![Release](https://img.shields.io/github/v/release/JesseWeb/Clipwharf)](https://github.com/JesseWeb/Clipwharf/releases) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)

![Clipwharf: press ⌘⇧V, pick a card, it pastes](docs/demo.gif)

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · **[Français](README.fr.md)** · [Español](README.es.md)

Clipwharf est un historique de presse-papiers **entièrement local** pour macOS. Copiez comme d'habitude, appuyez sur **⌘⇧V**, choisissez une carte : le contenu retourne dans le presse-papiers et se colle dans l'application que vous utilisiez.

Implémentation indépendante (clean-room), sans lien avec Paste ni aucun autre gestionnaire commercial, et sans aucun de leurs codes, ressources ou icônes. Pas de compte, pas de cloud, pas de télémétrie : rien ne quitte votre Mac.

## Fonctionnalités

- **Cinq types de cartes** : texte, lien, couleur, image, fichier. Les fichiers sont prévisualisés avec QuickLook (comme le Finder) ; plusieurs fichiers donnent une grille 2 × 2 avec un badge « +N ».
- **Épingles** : `⌘P` épingle une carte. Les épingles ont leur propre onglet et ne sont jamais supprimées par la limite de 200 entrées.
- **Recherche** : insensible à la casse, tous les mots doivent correspondre. Cherche dans le texte, les noms de fichiers, l'hôte des liens et le **nom de l'application source**.
- **Badge de l'application source** : chaque carte indique d'où elle vient.
- **Gestionnaires de mots de passe ignorés** : 1Password, Bitwarden, LastPass, Dashlane, Trousseau d'accès, Passwords et Keeper ne sont pas enregistrés.
- **Lancement à l'ouverture de session** : icône de la barre des menus → *Launch at Login*.
- **100 % local** : index JSON et fichiers PNG dans `~/Library/Application Support/Clipwharf`.

## Prérequis

- macOS 13 Ventura ou plus récent
- Xcode 15 ou plus récent (Swift 5.9+)

## Installation

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

**Option 3 — aucun téléchargement.** Clipwharf ne publie pas de binaire : la
notarisation exige un compte Apple Developer payant, et une version non notariée
accueillerait chaque utilisateur par un avertissement Gatekeeper. Les options 1 et
2 sont les chemins pris en charge, et une compilation locale a l'avantage de
porter votre propre identité de code.

## Premier lancement

1. Un trombone apparaît dans la barre des menus (pas d'icône dans le Dock, pas de fenêtre principale ; quitter via le menu contextuel).
2. Copiez du texte, une image ou un fichier, puis appuyez sur **⌘⇧V**.
3. Accordez l'Accessibilité pour le collage automatique : **Réglages Système → Confidentialité et sécurité → Accessibilité → activez Clipwharf.** Sans cela, le contenu est quand même copié et Clipwharf vous demande de faire ⌘V vous-même.

## Raccourcis

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

## Emplacement des données

```
~/Library/Application Support/Clipwharf/
├── history.json   # index du plus récent au plus ancien
└── Blobs/         # images (<uuid>.png)
```

Tout est en JSON et en fichiers simples. Quittez Clipwharf et supprimez ce dossier pour repartir de zéro.

## Signature et distribution (important)

- **Le dépôt ne contient que le code source** : `dist/` est ignoré, aucun `.app`, `.icns` ni certificat n'est versionné.
- `scripts/make-app.sh` utilise l'identité de signature de **la machine qui compile** : certificat Apple Development s'il existe, sinon signature ad-hoc. Aucun nom de développeur ni Team ID n'est codé en dur.
- Votre compilation porte donc **votre** identité de code, sans lien avec le certificat du mainteneur.
- **Signature ad-hoc et Accessibilité** : macOS lie l'autorisation à l'identité du code ; une identité ad-hoc change à chaque compilation, donc l'interrupteur peut paraître activé alors que le nouveau binaire n'est pas autorisé. Utilisez l'icône de la barre des menus → **Fix Accessibility Permission…** puis réactivez. Les compilations signées avec un certificat stable conservent l'autorisation.
- **Distribuer un `.app` signé à d'autres** exige un Developer ID et une notarisation, avec une clé privée qui ne doit jamais être publiée. C'est pourquoi le projet ne distribue que le code source.

## Dépannage

| Symptôme | Solution |
|---|---|
| L'interrupteur Accessibilité est activé mais la demande revient | Barre des menus → **Fix Accessibility Permission…**, puis réactivez |
| ⌘⇧V ne fait rien | Un autre gestionnaire (Paste, etc.) occupe le raccourci : quittez-le ou passez par l'icône |
| « Clipwharf.app souhaite accéder aux données d'autres apps » | Invite macOS lors du premier aperçu QuickLook d'un fichier appartenant à une autre app : autorisez une fois |
| Le panneau se ferme dès que je clique ailleurs | C'est voulu : il se masque en perdant le focus. Rouvrez-le avec ⌘⇧V |

## Développement

```sh
swift test
swift build -c release --product Clipwharf
./scripts/make-app.sh debug
```

## Licence

Clipwharf est un logiciel libre sous **GNU Affero General Public License v3.0** :
vous pouvez l'utiliser, le modifier et le partager, y compris commercialement, à
condition que les dérivés et les services réseau restent ouverts sous la même
licence.

Les produits qui ne peuvent pas accepter ce copyleft peuvent acheter une
**licence commerciale**, qui supprime ces obligations. Tarifs et conditions :
[COMMERCIAL.md](COMMERCIAL.md) ; contributions : [CONTRIBUTING.md](CONTRIBUTING.md).

Copyright et mentions : [NOTICE](NOTICE).
