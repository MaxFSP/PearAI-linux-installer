#!/bin/bash
source "$(dirname "$0")/pearai_config.sh"
source "$(dirname "$0")/utils.sh"

setup_directories() {
    log "Setting up directories..."
    mkdir -p "$APPS_DIR"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$APP_DIR"
    mkdir -p "$ICON_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$USER_CONFIG_DIR"
}

set_file_permissions() {
    log "Setting file permissions..."
    
    # Set base permissions
    find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
    find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
    
    # Set 755 permissions for PearAI files
    chmod 755 "$INSTALL_DIR/PearAI"
    chmod 755 "$INSTALL_DIR/bin/PearAI"
    
    # Set 755 for all .so and .so.* files
    find "$INSTALL_DIR" -type f -name "*.so" -exec chmod 755 {} \;
    find "$INSTALL_DIR" -type f -name "*.so.*" -exec chmod 755 {} \;
    
    # Set 755 for chrome-sandbox and chrome_crashpad_handler
    [ -f "$INSTALL_DIR/chrome-sandbox" ] && chmod 755 "$INSTALL_DIR/chrome-sandbox"
    [ -f "$INSTALL_DIR/chrome_crashpad_handler" ] && chmod 755 "$INSTALL_DIR/chrome_crashpad_handler"
}

extract_files() {
    log "Extracting installation files..."
    tar -xzf "$TARBALL" -C "$INSTALL_DIR" || handle_error "Failed to extract tarball"
    set_file_permissions
}

install_desktop_entries() {
    log "Setting up desktop entries..."
    cp "$DESKTOP_FILE" "$APP_DIR/$(basename "$DESKTOP_FILE")"
    cp "$URL_HANDLER_FILE" "$APP_DIR/$(basename "$URL_HANDLER_FILE")"
    
    sed -i "s|Exec=/usr/bin/|Exec=steam-run $INSTALL_DIR/bin/|g" "$APP_DIR/$(basename "$DESKTOP_FILE")"
    sed -i "s|Icon=.*|Icon=$ICON_DIR/pearAI.png|g" "$APP_DIR/$(basename "$DESKTOP_FILE")"
    
    sed -i "s|Exec=PearAI|Exec=steam-run $INSTALL_DIR/bin/PearAI|g" "$APP_DIR/$(basename "$URL_HANDLER_FILE")"
    sed -i "s|Icon=.*|Icon=$ICON_DIR/pearAI.png|g" "$APP_DIR/$(basename "$URL_HANDLER_FILE")"
    
    chmod 644 "$APP_DIR"/*
}

register_url_handler() {
    log "Registering URL handler..."
    local MIMEAPPS="$CONFIG_DIR/mimeapps.list"
    touch "$MIMEAPPS"
    
    if ! grep -q "x-scheme-handler/pearai=" "$MIMEAPPS"; then
        echo "[Default Applications]" >> "$MIMEAPPS"
        echo "x-scheme-handler/pearai=$(basename "$URL_HANDLER_FILE")" >> "$MIMEAPPS"
    fi
    
    xdg-mime default "$(basename "$URL_HANDLER_FILE")" x-scheme-handler/pearai
}

install_icon() {
    log "Installing the PearAI icon..."
    cp "$ICON_FILE" "$ICON_DIR/$(basename "$ICON_FILE")"
    chmod 644 "$ICON_DIR/$(basename "$ICON_FILE")"
}

create_symlink() {
    log "Creating symlink..."
    ln -sf "$INSTALL_DIR/bin/$BINARY" "$BIN_DIR/$BINARY"
    chmod 755 "$INSTALL_DIR/bin/$BINARY"
    
    if ! grep -q "$BIN_DIR" "$HOME_DIR/.profile" 2>/dev/null; then
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME_DIR/.profile"
    fi
}

install_pearai() {
    log "Starting PearAI installation..."
    
    setup_directories
    extract_files
    install_desktop_entries
    register_url_handler
    install_icon
    create_symlink
    
    log "Installation completed successfully"
    echo "Please log out and log back in for the PATH changes to take effect."
}

# Run installation
install_pearai
