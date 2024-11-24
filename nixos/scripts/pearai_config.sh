#!/bin/bash

# PearAI Configuration File

# PearAI version and package name
PEARAI_VERSION="1.5.0"
PKG_NAME="PearAI"

# User directories (everything under HOME)
HOME_DIR="$HOME"
APPS_DIR="$HOME_DIR/apps"
LOCAL_DIR="$HOME_DIR/.local"
CONFIG_DIR="$HOME_DIR/.config"

# Installation directories
INSTALL_DIR="$APPS_DIR/$PKG_NAME"
APP_DIR="$LOCAL_DIR/share/applications"
ICON_DIR="$LOCAL_DIR/share/icons/hicolor/256x256/apps"
BIN_DIR="$LOCAL_DIR/bin"
USER_CONFIG_DIR="$CONFIG_DIR/PearAI"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="source"
UTILS_DIR="$BASE_DIR/utils"

# Binary and application files
BINARY="PearAI"
DESKTOP_FILE="$UTILS_DIR/$PKG_NAME.desktop"
URL_HANDLER_FILE="$UTILS_DIR/$PKG_NAME-url-handler.desktop"
ICON_FILE="$UTILS_DIR/pearAI.png"
TARBALL="$SOURCE_DIR/${PKG_NAME}.tar.gz"
LOG_FILE="$HOME_DIR/.pearai_install.log"

# Documentation URL
DOCS_URL="https://trypear.ai/docs"
