# Cursor Linux Setup

A setup script for integrating Cursor IDE AppImage with your Linux desktop environment.

## Prerequisites

- Linux system with bash shell
- `update-desktop-database` command available

## Installation

1. Run the setup script:
   ```bash
   ./setup.sh
   ```
2. If the script failed to download the latest Cursor AppImage, please manually download it from [cursor.com/download](https://cursor.com/download) and place it in this directory. Then run the command above again.

## Update

To update Cursor to the latest version, please also run:
```bash
./setup.sh
```
It will automatically download the latest version and remove all other old Cursor*.AppImage files.

## What it does

- Creates desktop entry for application menu
- Installs `cursor` command for terminal usage

## Troubleshooting

**Missing update-desktop-database**: Install `desktop-file-utils` package

**AppImage not found**: Ensure Cursor AppImage is in the same directory as setup.sh

**Cursor command not found**: Add `$HOME/.local/bin` to your PATH in `~/.bashrc` or `~/.zshrc`:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
