#!/bin/bash

# PearAI Configuration File

# PearAI version and package name
PEARAI_VERSION="1.5.0"
PKG_NAME="PearAI"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$BASE_DIR/source"
UTILS_DIR="$BASE_DIR/utils"

# Installation directory
INSTALL_DIR="/opt/$PKG_NAME"

# Binary and application files
BINARY="PearAI"
DESKTOP_FILE="$UTILS_DIR/$PKG_NAME.desktop"
URL_HANDLER_FILE="$UTILS_DIR/$PKG_NAME-url-handler.desktop"
ICON_FILE="$UTILS_DIR/pearAI.png"

# Tarball location
TARBALL="$SOURCE_DIR/${PKG_NAME}.tar.gz"

# System directories
APP_DIR="/usr/share/applications"
ICON_DIR="/usr/share/icons/hicolor/256x256/apps"

# Determine correct home directory
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    USER_NAME="$SUDO_USER"
else
    USER_HOME="$HOME"
    USER_NAME=$(whoami)
fi

# User configuration directory
USER_CONFIG_DIR="$USER_HOME/.config/$PKG_NAME"
USER_CONFIG_DIR_SYMLINK="$USER_HOME/.config/pearai"

# Backup directory
BACKUP_DIR="/tmp/${PKG_NAME}_backup"

# Log file location
LOG_FILE="/tmp/${PKG_NAME}_install.log"

# Documentation URL
DOCS_URL="https://trypear.ai/docs"
