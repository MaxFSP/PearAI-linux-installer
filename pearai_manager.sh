#!/bin/bash

source "$(dirname "$0")/scripts/pearai_config.sh"
source "$(dirname "$0")/scripts/utils.sh"

ensure_log_file

# Function to display help
show_help() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show PearAI version"
    echo "  -d, --docs     Show PearAI docs"
    echo "  install        Install PearAI"
    echo "  uninstall      Uninstall PearAI"
}

# Function to display the main menu
display_menu() {
    clear
    echo "================================"
    echo "    PearAI Manager v$PEARAI_VERSION"
    echo "================================"
    echo "1. Install PearAI"
    echo "2. Uninstall PearAI"
    echo "3. Exit"
    echo "================================"
    echo -n "Enter your choice [1-3]: "
}

# Function to install PearAI
install_pearai() {
    log "Starting installation"
    if [ "$EUID" -ne 0 ]; then
        sudo bash "$(dirname "$0")/scripts/install_pearai.sh"
    else
        clear
        bash "$(dirname "$0")/scripts/install_pearai.sh"
    fi
    if [ $? -eq 0 ]; then
        log "PearAI installation completed successfully"
        exit 0
    else
        echo "Installation failed. Check the log for details."
        log "Installation failed"
    fi
}

# Function to uninstall PearAI
uninstall_pearai() {
    echo "Are you sure you want to uninstall PearAI? (y/N)"
    read -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "Starting uninstallation"
        if [ "$EUID" -ne 0 ]; then
            sudo bash "$(dirname "$0")/scripts/uninstall_pearai.sh"
        else
            clear
            bash "$(dirname "$0")/scripts/uninstall_pearai.sh"
        fi
        if [ $? -eq 0 ]; then
            log "PearAI uninstallation completed successfully"
            exit 0
        else
            log "Uninstallation failed"
        fi
    else
        log "Uninstallation cancelled by user"
    fi
}

# Trap for clean exit
trap 'echo "Script interrupted. Exiting..."; exit 1' INT TERM

# Check for command-line arguments
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "PearAI version $PEARAI_VERSION"
        exit 0
        ;;
    -d|--docs)
        echo "PearAI docs $DOCS_URL"
        exit 0
        ;;
    install)
        install_pearai
        exit 0
        ;;
    uninstall)
        uninstall_pearai
        exit 0
        ;;
esac

# Main loop
while true; do
    display_menu
    read -r choice

    case $choice in
        1)
            install_pearai
            ;;
        2)
            uninstall_pearai
            ;;
        3)
            echo "Exiting PearAI Manager. Goodbye!"
            log "PearAI Manager exited normally"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            log "Invalid option selected"
            ;;
    esac

    read -p "Press Enter to continue..."
done
