#!/bin/bash

source "$(dirname "$0")/pearai_config.sh"
source "$(dirname "$0")/utils.sh"

ensure_log_file

uninstall_pearai() {
    log "Starting PearAI uninstallation..."

    remove_file_or_dir "/usr/bin/$BINARY" "/usr/bin/$BINARY"
    remove_file_or_dir "/usr/share/applications/$(basename "$DESKTOP_FILE")" "/usr/share/applications/$(basename "$DESKTOP_FILE")"
    remove_file_or_dir "/usr/share/applications/$(basename "$URL_HANDLER_FILE")" "/usr/share/applications/$(basename "$URL_HANDLER_FILE")"
    remove_file_or_dir "$ICON_DIR/$(basename "$ICON_FILE")" "$ICON_DIR/$(basename "$ICON_FILE")"
    remove_file_or_dir "$INSTALL_DIR" "$INSTALL_DIR"
    remove_file_or_dir "$USER_HOME/.pearai" "$USER_HOME/.pearai"
    remove_file_or_dir "$USER_CONFIG_DIR_SYMLINK" "$USER_CONFIG_DIR_SYMLINK"
    remove_file_or_dir "$USER_CONFIG_DIR" "$USER_CONFIG_DIR"
}

uninstall_pearai
