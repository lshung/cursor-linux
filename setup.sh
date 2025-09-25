#!/bin/bash

####################################################################
# Script to create desktop icon and command for Cursor AppImage    #
####################################################################

# Exit on error
set -e

main() {
    declare_variables
    find_cursor_app_image_file
    check_if_icon_file_exists
    make_cursor_app_image_file_executable
    create_desktop_entries_dir_if_not_exists
    create_desktop_entry_file
    update_desktop_database
    create_terminal_command_cursor
}

log_ok() {
    local message="$1"
    echo -e "[\033[32m  OK  \033[0m] $message"
}

log_failed() {
    local message="$1"
    echo -e "[\033[31mFAILED\033[0m] $message" 1>&2
}

declare_variables() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ICON_FILE="$SCRIPT_DIR/icon.png"
    DESKTOP_DIR="$HOME/.local/share/applications"
    DESKTOP_FILE_NAME="Cursor.desktop"
    DESKTOP_FILE="$DESKTOP_DIR/$DESKTOP_FILE_NAME"
    CURSOR_COMMAND_FILE="$HOME/.local/bin/cursor"
}

find_cursor_app_image_file() {
    for file in "$SCRIPT_DIR"/Cursor*.AppImage; do
        if [[ -f "$file" ]]; then
            CURSOR_APP_IMAGE_FILE="$file"
            log_ok "Found Cursor AppImage file '$(basename "$CURSOR_APP_IMAGE_FILE")'"
            return 0
        fi
    done

    log_failed "Could not find Cursor AppImage file"
    return 1
}

check_if_icon_file_exists() {
    if [[ -f "$ICON_FILE" ]]; then
        log_ok "Found icon file '$(basename "$ICON_FILE")'"
    else
        log_failed "Could not find icon file '$(basename "$ICON_FILE")'"
        return 1
    fi
}

make_cursor_app_image_file_executable() {
    if chmod +x "$CURSOR_APP_IMAGE_FILE"; then
        log_ok "Made file '$(basename "$CURSOR_APP_IMAGE_FILE")' executable"
    else
        log_failed "Failed to make file '$(basename "$CURSOR_APP_IMAGE_FILE")' executable"
        return 1
    fi
}

create_desktop_entries_dir_if_not_exists() {
    if mkdir -p "$DESKTOP_DIR"; then
        log_ok "Created directory '$DESKTOP_DIR'"
    else
        log_failed "Failed to create directory '$DESKTOP_DIR'"
        return 1
    fi
}

create_desktop_entry_file() {
    if cp "$SCRIPT_DIR/$DESKTOP_FILE_NAME" "$DESKTOP_FILE" \
        && sed -i "s|@@cursor_app_image_file@@|$CURSOR_APP_IMAGE_FILE|" "$DESKTOP_FILE" \
        && sed -i "s|@@icon_file@@|$ICON_FILE|" "$DESKTOP_FILE" \
        && chmod +x "$DESKTOP_FILE"; then
        log_ok "Created file '$DESKTOP_FILE'"
    else
        log_failed "Failed to create file '$DESKTOP_FILE'"
        return 1
    fi
}

update_desktop_database() {
    if ! command -v update-desktop-database >/dev/null 2>&1; then
        log_failed "Command update-desktop-database does not exist"
        return 1
    fi

    if update-desktop-database "$DESKTOP_DIR"; then
        log_ok "Updated desktop database"
    else
        log_failed "Failed to update desktop database"
        return 1
    fi
}

create_terminal_command_cursor() {
    if echo "$CURSOR_APP_IMAGE_FILE" '"$@" &' > "$CURSOR_COMMAND_FILE" \
        && chmod +x "$CURSOR_COMMAND_FILE"; then
        log_ok "Created terminal command 'cursor'"
    else
        log_failed "Failed to create terminal command 'cursor'"
        return 1
    fi
}

main
