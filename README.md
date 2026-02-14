# Islands Dark

<a href="https://www.buymeacoffee.com/bwya77" style="margin-right: 10px;">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" />
</a>
<a href="https://github.com/sponsors/bwya77">
    <img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA" />
</a>


A dark color theme for Visual Studio Code inspired by JetBrains' Islands Dark theme. Features floating glass-like panels, rounded corners, smooth animations, and a deeply refined UI.

![Islands Dark Screenshot](assets/CleanShot%202026-02-13%20at%2023.27.47@2x.png)

## Features

- Deep dark canvas (`#131217`) with floating panels
- Glass-effect borders with directional light simulation (brighter top/left, subtle bottom/right)
- Rounded corners on all panels, notifications, command palette, and sidebars
- Pill-shaped activity bar with glass selection indicators
- Breadcrumb bar and status bar that dim when not hovered
- Tab close buttons that fade in on hover
- Smooth transitions on sidebar selections, scrollbars, and status bar
- Pill-shaped scrollbar thumbs
- Warm syntax highlighting with comprehensive language support (JS/TS, Python, Go, Rust, HTML/CSS, JSON, YAML, Markdown)
- Geist Mono font throughout

## Installation

This theme has two parts: a **color theme** and **CSS customizations** that create the floating glass panel look.

### Step 1: Install the theme

Clone this repo and install the theme as a local extension:

```bash
git clone https://github.com/bwya77/vscode-dark-islands.git islands-dark
cd islands-dark
code --install-extension .
```

Alternatively, copy the `themes/islands-dark.json` file into a VS Code extension manually.

### Step 2: Install the Custom UI Style extension

The floating panels, rounded corners, glass borders, and animations are powered by the **Custom UI Style** extension.

1. Open **Extensions** in VS Code (`Cmd+Shift+X` / `Ctrl+Shift+X`)
2. Search for **Custom UI Style** (by `subframe7536`)
3. Click **Install**

### Step 3: Install fonts

This theme uses two fonts:

- **[Geist Mono](https://vercel.com/font)** — used in the editor and terminal
- **Bear Sans UI** — used in the sidebar, tabs, command center, and status bar (included in `fonts/` folder)

To install Bear Sans UI:
1. Open the `fonts/` folder in this repo
2. Select all `.otf` files and double-click to open in Font Book (macOS) or right-click > Install (Windows)

If you prefer different fonts, update the `editor.fontFamily`, `terminal.integrated.fontFamily`, and `font-family` values in the settings.

### Step 4: Apply the settings

Copy the contents of `settings.json` from this repo into your VS Code settings:

1. Open **Command Palette** (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Search for **Preferences: Open User Settings (JSON)**
3. Merge the contents of this repo's `settings.json` into your settings file

> **Note:** If you already have existing settings, merge carefully. The key settings are `workbench.colorTheme`, `custom-ui-style.stylesheet`, and the font/indent preferences.

### Step 5: Enable Custom UI Style

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
| **File icons** | Subtle glow via drop-shadow |

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
