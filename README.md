# Cursor Linux Setup

A setup script for integrating Cursor IDE AppImage with your Linux desktop environment.

## Prerequisites

- Download Cursor AppImage from [cursor.com/download](https://cursor.com/download)
- Linux system with bash shell
- `update-desktop-database` command available

## Installation

1. Download the Cursor AppImage and place it in this directory
2. Run the setup script:
   ```bash
   ./setup.sh
   ```

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
