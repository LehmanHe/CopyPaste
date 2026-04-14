# CopyPaste

A lightweight clipboard manager for macOS.

## Features

- Clipboard history with search
- Keyboard-first navigation
- Pin frequently used items
- Paste with or without formatting
- Native macOS UI
- Open source

## Requirements

- macOS Sonoma 14+
- Xcode 16+ (for building from source)

## Install

Download the latest DMG from [Releases](https://github.com/p0deje/CopyPaste/releases/latest), or build from source:

```sh
git clone https://github.com/p0deje/CopyPaste.git
cd CopyPaste
./scripts/build_dmg.sh
```

The DMG will be generated in the `build/` directory.

## Usage

| Action | Shortcut |
|--------|----------|
| Open popup | <kbd>⇧</kbd> + <kbd>⌘</kbd> + <kbd>C</kbd> |
| Select & copy | <kbd>Enter</kbd> |
| Select & paste | <kbd>⌥</kbd> + <kbd>Enter</kbd> |
| Paste without formatting | <kbd>⌥</kbd> + <kbd>⇧</kbd> + <kbd>Enter</kbd> |
| Delete item | <kbd>⌥</kbd> + <kbd>⌫</kbd> |
| Pin/unpin item | <kbd>⌥</kbd> + <kbd>P</kbd> |
| Clear all | <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>⌫</kbd> |
| Preferences | <kbd>⌘</kbd> + <kbd>,</kbd> |

## License

[MIT](./LICENSE)
