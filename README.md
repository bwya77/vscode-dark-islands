# Islands Dark

<a href="https://www.buymeacoffee.com/bwya77" style="margin-right: 10px;">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" />
</a>
<a href="https://github.com/sponsors/bwya77">
    <img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA" />
</a>


## **THIS THEME IS STILL A WORK IN PROGRESS**

A dark color theme for Visual Studio Code inspired by JetBrains' Islands Dark theme. Features floating glass-like panels, rounded corners, smooth animations, and a deeply refined UI.

![Islands Dark Screenshot](assets/CleanShot%202026-02-14%20at%2021.47.05@2x.png)

## Features

- Deep dark canvas (`#131217`) with floating panels
- Glass-effect borders with directional light simulation (brighter top/left, subtle bottom/right)
- Rounded corners on all panels, notifications, command palette, and sidebars
- Pill-shaped activity bar with glass selection indicators
- Breadcrumb bar and status bar that dim when not hovered
- Tab close buttons that fade in on hover
- Smooth transitions on sidebar selections, scrollbars, and status bar
- Pill-shaped scrollbar thumbs
- Color-matched icon glow effect (works best with [Seti Folder](https://marketplace.visualstudio.com/items?itemName=l-igh-t.vscode-theme-seti-folder) icon theme)
- Warm syntax highlighting with comprehensive language support (JS/TS, Python, Go, Rust, HTML/CSS, JSON, YAML, Markdown)
- IBM Plex Mono in the editor, FiraCode Nerd Font Mono in the terminal

![Islands Dark Screenshot UI](assets/CleanShot%202026-02-14%20at%2021.45.00@2x.png)

## Installation

This theme has two parts: a **color theme** and **CSS customizations** that create the floating glass panel look.

### One-Liner Install (Recommended)

The fastest way to install:

#### macOS/Linux

```bash
curl -fsSL https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.sh | bash
```

#### Windows

```powershell
irm https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.ps1 | iex
```

### Manual Clone Install

If you prefer to clone first:

#### macOS/Linux

```bash
git clone https://github.com/bwya77/vscode-dark-islands.git islands-dark
cd islands-dark
./install.sh
```

#### Windows

```powershell
git clone https://github.com/bwya77/vscode-dark-islands.git islands-dark
cd islands-dark
.\install.ps1
```

The scripts will automatically:
- ✅ Install the Islands Dark theme extension
- ✅ Install the Custom UI Style extension
- ✅ Install Bear Sans UI fonts
- ✅ Merge settings into your VS Code configuration
- ✅ Enable Custom UI Style and reload VS Code

> **Note:** IBM Plex Mono and FiraCode Nerd Font Mono must be installed separately (the script will remind you). The installer also works with VS Code Insiders.

### Manual Installation

If you prefer to install manually, follow these steps:

#### Step 1: Install the theme

Clone this repo and copy the extension files:

```bash
git clone https://github.com/bwya77/vscode-dark-islands.git islands-dark
cd islands-dark
mkdir -p ~/.vscode/extensions/bwya77.islands-dark-1.0.0
cp package.json ~/.vscode/extensions/bwya77.islands-dark-1.0.0/
cp -r themes ~/.vscode/extensions/bwya77.islands-dark-1.0.0/
```

On Windows (PowerShell):
```powershell
git clone https://github.com/bwya77/vscode-dark-islands.git islands-dark
cd islands-dark
$ext = "$env:USERPROFILE\.vscode\extensions\bwya77.islands-dark-1.0.0"
New-Item -ItemType Directory -Path $ext -Force
Copy-Item package.json $ext\
Copy-Item themes $ext\themes -Recurse
```

> For VS Code Insiders, use `~/.vscode-insiders/extensions` or `%USERPROFILE%\.vscode-insiders\extensions` instead.

#### Step 2: Install the Custom UI Style extension

The floating panels, rounded corners, glass borders, and animations are powered by the **Custom UI Style** extension.

1. Open **Extensions** in VS Code: (`Cmd+Shift+X` / `Ctrl+Shift+X`)
2. Search for **Custom UI Style** (by `subframe7536`)
3. Click **Install**

#### Step 3: Install recommended icon theme

For the best experience with the color-matched icon glow effect, install the **Seti Folder** icon theme:

1. Open **Extensions** in VS Code (`Cmd+Shift+X` / `Ctrl+Shift+X`)
2. Search for **[Seti Folder](https://marketplace.visualstudio.com/items?itemName=l-igh-t.vscode-theme-seti-folder)** (by `l-igh-t`)
3. Click **Install**
4. Set it as your icon theme: **Command Palette** > **Preferences: File Icon Theme** > **Seti Folder**

#### Step 5: Install fonts

This theme uses two fonts:

- **IBM Plex Mono** — used in the editor
- **FiraCode Nerd Font Mono** — used in the terminal
- **Bear Sans UI** — used in the sidebar, tabs, command center, and status bar (included in `fonts/` folder)

To install Bear Sans UI:
1. Open the `fonts/` folder in this repo
2. Select all `.otf` files and double-click to open in Font Book (macOS) or right-click > Install (Windows)

If you prefer different fonts, update the `editor.fontFamily`, `terminal.integrated.fontFamily`, and `font-family` values in the settings.

#### Step 6: Apply the settings

Copy the contents of `settings.json` from this repo into your VS Code: settings:

1. Open **Command Palette** (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Search for **Preferences: Open User Settings (JSON)**
3. Merge the contents of this repo's `settings.json` into your settings file

> **Note:** If you already have existing settings, merge carefully. The key settings are `workbench.colorTheme`, `custom-ui-style.stylesheet`, and the font/indent preferences.

#### Step 7: Enable Custom UI Style

1. Open **Command Palette** (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Run **Custom UI Style: Enable**
3. VS Code will reload

> **Note:** You may see a "corrupt installation" warning after enabling. This is expected since Custom UI Style injects CSS into VS Code. Click the gear icon on the warning and select **Don't Show Again**.

## What the CSS customizations do

| Element | Effect |
|---------|--------|
| **Canvas** | Deep dark background (`#131217`) behind all panels |
| **Sidebar** | Floating with 24px rounded corners, glass borders, drop shadow |
| **Editor** | Floating with 24px rounded corners, glass borders, browser-tab effect |
| **Activity bar** | Pill-shaped with glass inset shadows, circular selection indicator |
| **Command center** | Pill-shaped with glass effect |
| **Bottom panel** | Floating with 14px rounded corners, glass borders |
| **Right sidebar** | Floating with 24px rounded corners, glass borders |
| **Notifications** | 14px rounded corners, glass borders, deep drop shadow |
| **Command palette** | 16px rounded corners, glass borders, rounded list rows |
| **Scrollbars** | Pill-shaped thumbs with fade transition |
| **Tabs** | Browser-tab style (active tab open at bottom), close button fades in on hover |
| **Breadcrumbs** | Hidden until hover with smooth fade transition |
| **Status bar** | Dimmed text that brightens on hover |
| **File icons** | Color-matched glow via drop-shadow (best with Seti Folder icon theme) |

## Troubleshooting

### Changes aren't taking effect
Try disabling and re-enabling Custom UI Style:
1. **Command Palette** > **Custom UI Style: Disable**
2. Reload VS Code
3. **Command Palette** > **Custom UI Style: Enable**
4. Reload VS Code

### "Corrupt installation" warning
This is expected after enabling Custom UI Style. Dismiss it or select **Don't Show Again**.

### Previously used "Custom CSS and JS Loader" extension
If you previously used the **Custom CSS and JS Loader** extension (`be5invis.vscode-custom-css`), it may have injected CSS directly into VS Code's `workbench.html` that persists even after disabling. If styles conflict, reinstall VS Code to get a clean `workbench.html`, then use only **Custom UI Style**.

## Credits

Inspired by the [JetBrains Islands Dark](https://www.jetbrains.com/) UI theme.

## License

MIT
