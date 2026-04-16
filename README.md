# Islands Dark

A custom VS Code UI theme built around the Islands Dark color theme and a workbench CSS layer. The CSS layer is the main visual effect: floating panels, rounded corners, glass borders, a pill activity bar, subtle shadows, and quieter chrome.

![Islands Dark Screenshot](assets/CleanShot%202026-02-19%20at%2019.37.59@2x.png)

## Important

VS Code does not officially support custom CSS for the main workbench. Islands Dark uses [Custom CSS and JS Loader](https://marketplace.visualstudio.com/items?itemName=be5invis.vscode-custom-css) to apply `custom-css/islands-dark.css` to VS Code's workbench HTML.

That means:

- VS Code may show a corrupt installation warning after enabling custom CSS.
- VS Code updates can remove the patch; run **Reload Custom CSS and JS** again after updates.
- Admin permissions may be required if VS Code is installed in a protected location.
- This package ships CSS only. It does not require custom JavaScript.

## What This Repo Provides

- A normal VS Code color theme: `themes/islands-dark.json`
- A custom workbench stylesheet: `custom-css/islands-dark.css`
- Optional Bear Sans UI fonts in `fonts/`
- Minimal helper scripts that install only the native color theme and print the manual CSS setup

## Install

### Option 1: Scripted Install

The scripts install the native Islands Dark color theme into your local VS Code extensions folder and try to install Custom CSS and JS Loader with the `code` CLI.

They do not edit `settings.json`, install fonts, enable custom CSS, or patch VS Code. The scripts print the exact settings and next steps after they run.

Windows PowerShell:

```powershell
.\install.ps1
```

macOS/Linux:

```bash
./install.sh
```

Then run one of these commands from VS Code's Command Palette:

```text
Enable Custom CSS and JS
```

or:

```text
Reload Custom CSS and JS
```

Reload VS Code when prompted.

Install the `.otf` files from `fonts/` manually if you want the exact typography.

### Option 2: Manual Install

1. Install this theme extension from the repo, VSIX, or the helper script.
2. Install [Custom CSS and JS Loader](https://marketplace.visualstudio.com/items?itemName=be5invis.vscode-custom-css).
3. Add these settings, changing the CSS path to your local checkout:

```json
"workbench.colorTheme": "Islands Dark",
"vscode_custom_css.statusbar": true,
"vscode_custom_css.imports": [
  "file:///C:/Dhyan/repos/vscode-dark-islands/custom-css/islands-dark.css"
]
```

On macOS/Linux, use a file URL like:

```json
"workbench.colorTheme": "Islands Dark",
"vscode_custom_css.statusbar": true,
"vscode_custom_css.imports": [
  "file:///Users/you/repos/vscode-dark-islands/custom-css/islands-dark.css"
]
```

4. Run **Enable Custom CSS and JS** or **Reload Custom CSS and JS**.
5. Reload VS Code.

## Fonts

The custom CSS references:

- `Bear Sans UI`
- `Bear Sans UI Heading`

The font files are included in `fonts/`. If they are not installed, VS Code falls back to your system sans-serif font. For the closest look, install the `.otf` files from `fonts/`.

Recommended editor and terminal fonts are optional:

```json
"editor.fontFamily": "IBM Plex Mono, Consolas, monospace",
"terminal.integrated.fontFamily": "FiraCode Nerd Font Mono, Consolas, monospace"
```

## Uninstall

1. Run **Disable Custom CSS and JS** from the Command Palette. This asks Custom CSS and JS Loader to restore VS Code's patched workbench file.
2. Remove the Islands Dark CSS URL from `vscode_custom_css.imports`.
3. Change to another color theme or uninstall Islands Dark.
4. Reload VS Code.

The helper scripts remove only the locally copied native color theme folder. They do not edit `settings.json`.

Windows:

```powershell
.\uninstall.ps1
```

macOS/Linux:

```bash
./uninstall.sh
```

If VS Code still reports a corrupt installation after disabling custom CSS, update or reinstall VS Code to restore the official app files.

## Troubleshooting

### CSS did not apply

Run **Reload Custom CSS and JS** and reload VS Code. If VS Code is installed under `Program Files` or another protected location, restart VS Code as Administrator and run the command again.

### CSS disappeared after update

VS Code updates replace the patched workbench HTML. Run **Reload Custom CSS and JS** again.

### I previously used Custom UI Style

Remove any `custom-ui-style.stylesheet` settings from your settings file, then use only `vscode_custom_css.imports` for Islands Dark.

## License

MIT
