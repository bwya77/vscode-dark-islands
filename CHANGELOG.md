# Changelog

## 0.0.2 - [2026-02-19]

### FIXED
- Fixed chat window colors broken: #15
- Install script (tested on MacOS) #5, #6
- The explorer pane would not show all items, some items would be cut off #67, #74, #66, #20, #12
- Commit message box cut off #57, #70
- Primary sidebar would be truncated if we moved it to the right #55
- Issue with explorer pane items being unselected but the file would remain selected. 
- Border radius of terminal does not match editor, chat, etc. #61
- Made the primary sidebar icons slightly larger (18px to 22px)
- Window controls background color is incorrect #72
- When opening VSCode with no open files, the default tab would be cut off. #30
- When working with `ipynb` files the editor wouldnt follow correct rendering and code blocks did not stand out #45
- Elements in the terminal when split screen would spill over
- Editor tabs overlapping with floating header in Linux #26
- Markdown files respect `font-family` CSS rules and render monospace fonts correctly #48

### ADDED
- Chat text window has rounded corners instead of squared #47
- Uninstall script (tested on MacOS)
- Funding.yml file 
- Users can set the 'roundness' of elements by modifying `css` variables. Please see the "Customizing Border Radius" section in the README.md file
- Users can set the spacing between elements such as the explorer pane, chat pane, editor, and temrinal. #17
- Users can now set the primary and secondary colors by setting the `islands-bg-surface` and `islands-bg-canvas` variables.
- 2px spacing between the terminal and editor. 
- The system dialog box now follows our theme with rounded corners
- Shadow under the sticky widget in the editor. 

### CHANGED
- Theme and settings.json file are versioned properly #17

### REMOVED
- Removed the highlight boxes in selection windows - these cannot be rounded #10
