#!/bin/bash

# Source external configuration and utility scripts
source "$(dirname "$0")/pearai_config.sh"
source "$(dirname "$0")/utils.sh"

# Ensure a log file is set up
ensure_log_file

# Trap for handling interruptions and ensuring cleanup
trap 'handle_interrupt' INT TERM

handle_interrupt() {
    log "Installation interrupted. Performing cleanup..."
    cleanup_on_interrupt
    exit 1
}

cleanup_on_interrupt() {
    # Add any necessary cleanup commands here
    # For example, if you have temporary files or directories, remove them
    # Example:
    # rm -rf "$TEMP_DIR"
    log "Cleanup after interruption completed."
}

create_symlink() {
    log "Creating symbolic link for PearAI"

    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        USER_NAME="$SUDO_USER"
    else
        USER_HOME="$HOME"
        USER_NAME=$(whoami)
    fi

    log "Detected user: $USER_NAME"
    log "User home directory: $USER_HOME"

    local source_dir="$USER_CONFIG_DIR"
    local target_link="$USER_CONFIG_DIR_SYMLINK"

    check_directory_exists "$source_dir"
    configure_permissions "$source_dir" "dir" "$USER_NAME"

    if [ -L "$target_link" ] && [ "$(readlink -f "$target_link")" = "$source_dir" ]; then
        log "Correct symbolic link already exists."
        return 0
    fi

    remove_file_or_dir "$target_link" "existing target"

    log "Creating symbolic link '$target_link' -> '$source_dir'..."
    sudo -u "$USER_NAME" ln -s "$source_dir" "$target_link" || handle_error "Failed to create symbolic link"

    configure_permissions "$(dirname "$target_link")" "dir" "$USER_NAME"

    log "Symbolic link created successfully: '$target_link' -> '$source_dir'"
}

extract_files() {
    log "Extracting installation files from the archive into $INSTALL_DIR..."

    # Check if tarball exists
    check_file_exists "$TARBALL"

    # Create target directory
    mkdir -p "$INSTALL_DIR" || handle_error "Failed to create installation directory $INSTALL_DIR"

    # Extract all files into /opt/PearAI
    tar -xzf "$TARBALL" -C "$INSTALL_DIR" || handle_error "Failed to extract tarball $TARBALL"
}

install_desktop_entries() {
    log "Setting up desktop entries..."

    mkdir -p "$APP_DIR" || handle_error "Failed to create applications directory $APP_DIR"

    # Check if desktop files exist
    check_file_exists "$DESKTOP_FILE"
    check_file_exists "$URL_HANDLER_FILE"

    # Copy desktop files
    cp "$DESKTOP_FILE" "$APP_DIR/$(basename "$DESKTOP_FILE")" || handle_error "Failed to copy $DESKTOP_FILE"
    cp "$URL_HANDLER_FILE" "$APP_DIR/$(basename "$URL_HANDLER_FILE")" || handle_error "Failed to copy $URL_HANDLER_FILE"

    chmod 644 "$APP_DIR/$(basename "$DESKTOP_FILE")" "$APP_DIR/$(basename "$URL_HANDLER_FILE")" || handle_error "Failed to set permissions on desktop entries"

    log "Desktop entries successfully set up."
}

install_icon() {
    log "Installing the PearAI icon..."

    # Check if icon file exists
    check_file_exists "$ICON_FILE"

    # Install the icon
    install -Dm644 "$ICON_FILE" "$ICON_DIR/$(basename "$ICON_FILE")" || handle_error "Failed to install app icon $ICON_FILE"

    log "App icon installed successfully."
}

create_symlink_bin() {
    log "Creating a symlink to /usr/bin for easy access to PearAI binary..."

    # Check if the binary exists
    check_file_exists "$INSTALL_DIR/bin/$BINARY"

    ln -sf "$INSTALL_DIR/bin/$BINARY" "/usr/bin/$BINARY" || handle_error "Failed to create symlink for $BINARY"

    log "Symlink created successfully: /usr/bin/$BINARY -> $INSTALL_DIR/bin/$BINARY"
}

update_desktop_database() {
    log "Updating the desktop applications database..."

    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$APP_DIR" || handle_error "Failed to update the desktop database"
        log "Desktop applications database updated successfully."
    else
        log "Warning: Could not update the desktop app database (command not found)."
    fi
}

rebuild_icon_cache() {
    log "Rebuilding desktop icon cache..."

    if command -v gtk-update-icon-cache &> /dev/null; then
        gtk-update-icon-cache /usr/share/icons/hicolor || handle_error "Failed to rebuild the desktop icon cache"
        log "Desktop icon cache rebuilt successfully."
    else
        log "Warning: Could not rebuild the icon cache (command not found). If you experience issues with the icon, try logging out and back in or restarting your computer."
    fi
}

updating_chrome_sandbox_permissions() {
    log "Updating chrome-sandbox permissions..."

    if [ -f "$INSTALL_DIR/chrome-sandbox" ]; then
        sudo chown root "$INSTALL_DIR/chrome-sandbox" || handle_error "Failed to change owner of chrome-sandbox"
        sudo chmod 4755 "$INSTALL_DIR/chrome-sandbox" || handle_error "Failed to set permissions on chrome-sandbox"
        log "Permissions for chrome-sandbox updated successfully."
    else
        log "No chrome-sandbox found, skipping this step."
    fi
}

copy_additional_resources() {
    log "Copying additional resources..."

    # Assuming additional resources are in a specific directory within the tarball
    # Adjust the source and destination as needed
    local resources_dir="$INSTALL_DIR/resources"
    local target_resources_dir="$INSTALL_DIR/"

    if [ -d "$resources_dir" ]; then
        cp -r "$resources_dir/"* "$target_resources_dir" || handle_error "Failed to copy additional resources"
        log "Additional resources copied successfully."
    else
        log "No additional resources to copy."
    fi
}

cleanup() {
    log "Cleaning up temporary files..."
    # No temporary files to clean up in this version
    log "Cleanup completed."
}

final_messages() {
    log "Installation of PearAI completed successfully!"
    log "Installation of PearAI completed successfully!"
    log "You can launch PearAI from the applications menu (e.g., GNOME, KDE, etc.) or by typing '$BINARY' in the terminal."
    log "If you experience issues, try logging out and back in."
    log "For further help, feel free to contact us on the PearAI Discord community!"
}

install_pearai() {
    log "Starting PearAI installation..."

    # Ensure the installation is fresh and version checks are performed
    check_fresh_install
    check_version

    extract_files
    create_symlink_bin
    install_desktop_entries
    install_icon
    create_symlink
    updating_chrome_sandbox_permissions
    copy_additional_resources
    update_desktop_database
    rebuild_icon_cache
    cleanup
    final_messages
}

# Execute the installation
install_pearai
