#!/bin/bash

######################################################################################
# Script to create desktop icon and terminal command for Cursor AppImage             #
######################################################################################

set -euo pipefail

main() {
    declare_variables || { log_failed "Failed to declare variables."; return 1; }
    download_latest_cursor_app_image_file || true
    find_cursor_app_image_file || { log_failed "Could not find any Cursor AppImage file."; return 1; }
    find_icon_file || { log_failed "Could not find icon file."; return 1; }
    make_cursor_app_image_file_executable || { log_failed "Failed to make Cursor AppImage file executable."; return 1; }
    build_execution_command || { log_failed "Failed to build execution command."; return 1; }
    create_terminal_command || { log_failed "Failed to create terminal command."; return 1; }
    create_desktop_file || { log_failed "Failed to create desktop file."; return 1; }
    update_desktop_database || { log_failed "Failed to update desktop database."; return 1; }
}

log_info() {
    local message="$1"
    echo -e "[ INFO ] $message"
}

log_warning() {
    local message="$1"
    echo -e "[\033[33m WARN \033[0m] $message" 1>&2
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
    INITIAL_DOWNLOAD_URL="https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/latest"
    DOWNLOAD_URL=""
    ENV_VARIABLES=()
    COMMAND_FLAGS=()
    EXEC_COMMAND=""
    DESKTOP_DIR="$HOME/.local/share/applications"
    DESKTOP_FILE_NAME="Cursor.desktop"
    DESKTOP_FILE="$DESKTOP_DIR/$DESKTOP_FILE_NAME"
    COMMAND_FILE="$HOME/.local/bin/cursor"
}

download_latest_cursor_app_image_file() {
    get_valid_download_url || { log_warning "Download URL is invalid."; return 1; }
    download_cursor_app_image_file_if_not_exists || { log_warning "Failed to download latest Cursor AppImage file."; return 1; }
    delete_old_cursor_app_image_files || { log_warning "Failed to delete old Cursor AppImage files."; return 1; }
}

get_valid_download_url() {
    log_info "Getting download URL..."
    DOWNLOAD_URL=$(curl -w "%{url_effective}" -I -L -s -S "$INITIAL_DOWNLOAD_URL" -o /dev/null 2>/dev/null)
    [[ -n "$DOWNLOAD_URL" ]] || return 1
    log_info "Got download URL '$DOWNLOAD_URL'."

    [[ "$DOWNLOAD_URL" == *.AppImage ]] || return 1
    log_ok "Download URL is valid."
}

download_cursor_app_image_file_if_not_exists() {
    CURSOR_APP_IMAGE_FILE="$SCRIPT_DIR/$(basename "$DOWNLOAD_URL")"

    if [[ -f "$CURSOR_APP_IMAGE_FILE" ]]; then
        log_info "The latest Cursor AppImage file already exists, so skip downloading."
        return 0
    fi

    log_info "Downloading '$(basename "$DOWNLOAD_URL")'..."
    curl -L -s -O "$DOWNLOAD_URL" --output-dir "$SCRIPT_DIR"
    log_ok "Downloaded '$(basename "$DOWNLOAD_URL")' successfully."
}

delete_old_cursor_app_image_files() {
    for file in "$SCRIPT_DIR"/Cursor*.AppImage*; do
        if [[ -f "$file" ]] && [[ "$file" != "$CURSOR_APP_IMAGE_FILE" ]]; then
            rm -f "$file"
        fi
    done

    log_ok "Deleted old Cursor AppImage files."
}

find_cursor_app_image_file() {
    for file in "$SCRIPT_DIR"/Cursor*.AppImage; do
        if [[ -f "$file" ]]; then
            CURSOR_APP_IMAGE_FILE="$file"
            log_ok "Found Cursor AppImage file '$(basename "$CURSOR_APP_IMAGE_FILE")'."
            return 0
        fi
    done

    return 1
}

find_icon_file() {
    [[ -f "$ICON_FILE" ]]
    log_ok "Found icon file '$(basename "$ICON_FILE")'."
}

make_cursor_app_image_file_executable() {
    chmod +x "$CURSOR_APP_IMAGE_FILE"
    log_ok "Made file '$(basename "$CURSOR_APP_IMAGE_FILE")' executable."
}

build_execution_command() {
    set_environment_variables_and_flags_for_wayland
    set_environment_variables_and_flags_for_fcitx5

    if [[ ${#ENV_VARIABLES[@]} -gt 0 ]]; then
        EXEC_COMMAND="env ${ENV_VARIABLES[*]} $CURSOR_APP_IMAGE_FILE ${COMMAND_FLAGS[*]}"
    else
        EXEC_COMMAND="$CURSOR_APP_IMAGE_FILE"
    fi

    log_ok "Built execution command."
}

set_environment_variables_and_flags_for_wayland() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]] || [[ "$WAYLAND_DISPLAY" ]]; then
        ENV_VARIABLES+=("GDK_BACKEND=wayland")
        ENV_VARIABLES+=("QT_QPA_PLATFORM=wayland")
        ENV_VARIABLES+=("SDL_VIDEODRIVER=wayland")
        ENV_VARIABLES+=("CLUTTER_BACKEND=wayland")
        ENV_VARIABLES+=("ELECTRON_OZONE_PLATFORM_HINT=wayland")

        COMMAND_FLAGS+=("-enable-features=UseOzonePlatform")
        COMMAND_FLAGS+=("--ozone-platform=wayland")
    fi
}

set_environment_variables_and_flags_for_fcitx5() {
    if command -v fcitx5 >/dev/null 2>&1; then
        ENV_VARIABLES+=("GTK_IM_MODULE=fcitx5")
        ENV_VARIABLES+=("QT_IM_MODULE=fcitx5")
        ENV_VARIABLES+=("XMODIFIERS=@im=fcitx5")
        ENV_VARIABLES+=("SDL_IM_MODULE=fcitx5")
        ENV_VARIABLES+=("GLFW_IM_MODULE=ibus")

        COMMAND_FLAGS+=("--enable-wayland-ime")
    fi
}

create_terminal_command() {
    echo "$EXEC_COMMAND" '"$@" &' > "$COMMAND_FILE"
    chmod +x "$COMMAND_FILE"
    log_ok "Created terminal command 'cursor'."
}

create_desktop_file() {
    mkdir -p "$DESKTOP_DIR"
    cp "$SCRIPT_DIR/$DESKTOP_FILE_NAME" "$DESKTOP_FILE"
    sed -i "s|@@command_file@@|$COMMAND_FILE|" "$DESKTOP_FILE"
    sed -i "s|@@icon_file@@|$ICON_FILE|" "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
    log_ok "Created desktop file '$DESKTOP_FILE'."
}

update_desktop_database() {
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1
    log_ok "Updated desktop database."
}

main
