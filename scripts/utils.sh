#!/bin/bash

# Source configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pearai_config.sh"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "Error: $1"
    echo "Error: $1" >&2
    exit 1
}

# Function to change ownership and set permissions
configure_permissions() {
    local path="$1"
    local type="$2"  # "dir" or "file"
    local user="$3"

    [ "$type" == "dir" ] && chmod -R 755 "$path" || chmod 644 "$path"
    [ $? -ne 0 ] && handle_error "Failed to set permissions for '$path'"

    chown -R "$user":"$user" "$path" || handle_error "Failed to change ownership of '$path' to '$user'"
}

# Check if a file exists
check_file_exists() {
    if [ ! -f "$1" ]; then
        handle_error "$1 not found. Please ensure all necessary files are in place."
    fi
}

# Check if a directory exists, create if it doesn't
check_directory_exists() {
    if [ ! -d "$1" ]; then
        log "Creating directory $1..."
        mkdir -p "$1" || handle_error "Failed to create directory $1"
    else
        log "Directory $1 already exists."
    fi
}

# Remove file or directory
remove_file_or_dir() {
    local path="$1"
    local description="$2"

    if [ -e "$path" ]; then
        sudo rm -rf "$path" || handle_error "Failed to remove $description"
        log "Removed $description"
    fi
}

# Check for fresh install
check_fresh_install() {
    log "Checking for existing PearAI installation"

    if [ -d "$INSTALL_DIR" ] || [ -f "/usr/bin/$BINARY" ] || [ -f "/usr/share/applications/$DESKTOP_FILE" ] || [ -f "/usr/share/applications/$URL_HANDLER_FILE" ]; then
        log "PearAI is already installed. Removing previous installation..."

        # Remove desktop files
        remove_file_or_dir "/usr/share/applications/$DESKTOP_FILE" "$DESKTOP_FILE"
        remove_file_or_dir "/usr/share/applications/$URL_HANDLER_FILE" "$URL_HANDLER_FILE"

        # Remove binary
        remove_file_or_dir "/usr/bin/$BINARY" "$BINARY binary"

        # Remove installation folder
        remove_file_or_dir "$INSTALL_DIR" "PearAI installation directory"

        log "Previous installation removed. Proceeding with fresh installation."
    else
        log "No previous installation found. Proceeding with fresh installation."
    fi
}

# Ensure log file is created with correct permissions
ensure_log_file() {
    if [ ! -f "$LOG_FILE" ]; then
        sudo touch "$LOG_FILE" || echo "Error: Failed to create log file $LOG_FILE"
        sudo chmod 666 "$LOG_FILE" || echo "Error: Failed to set permissions for log file $LOG_FILE"
        sudo chown root:root "$LOG_FILE"
    fi
}

check_version() {
    log "Checking PearAI version compatibility"
    # Implement version checking logic here if needed
    # For now, we'll just return 0 (success)
    return 0
}
