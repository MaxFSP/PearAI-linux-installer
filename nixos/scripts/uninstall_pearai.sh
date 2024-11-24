#!/bin/bash

source "$(dirname "$0")/pearai_config.sh"
source "$(dirname "$0")/utils.sh"

uninstall_pearai() {
    log "Starting PearAI uninstallation..."
    
    # Unregister URL handler
    xdg-mime uninstall "$APP_DIR/$(basename "$URL_HANDLER_FILE")" || true
    
    # Remove application files
    rm -rf "$INSTALL_DIR"
    rm -f "$APP_DIR/$(basename "$DESKTOP_FILE")"
    rm -f "$APP_DIR/$(basename "$URL_HANDLER_FILE")"
    rm -f "$ICON_DIR/$(basename "$ICON_FILE")"
    rm -f "$BIN_DIR/$BINARY"
    rm -f "$CONFIG_DIR/pearai"
    rm -rf "$USER_CONFIG_DIR"
    
    # Clean up mimeapps.list
    if [ -f "$CONFIG_DIR/mimeapps.list" ]; then
        sed -i '/x-scheme-handler\/pearai=/d' "$CONFIG_DIR/mimeapps.list"
    fi
    
    # Remove apps directory if empty
    rmdir "$APPS_DIR" 2>/dev/null || true
    nix-env --uninstall steam-run
    log "Uninstallation completed successfully"
    echo "Note: You may want to remove the PATH addition from ~/.profile if no other apps use it."
}

# Run uninstallation
uninstall_pearai
