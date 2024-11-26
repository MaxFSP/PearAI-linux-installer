#!/bin/bash

# Function to uninstall steam-run system-wide
uninstall_steam_run_system() {
    local config_file="/etc/nixos/configuration.nix"
    
    # Backup the configuration file
    cp "$config_file" "${config_file}.backup"
    
    # Remove steam-run from systemPackages
    sed -i '/\bsteam-run\b/d' "$config_file"
    
    echo "steam-run has been removed from system configuration."
    echo "Please run 'sudo nixos-rebuild switch' to apply changes."
}

# Function to uninstall steam-run for current user
uninstall_steam_run_user() {
    local home_manager_file="$HOME/.config/home-manager/home.nix"
    
    if [ -f "$home_manager_file" ]; then
        # Backup the configuration file
        cp "$home_manager_file" "${home_manager_file}.backup"
        
        # Remove steam-run from home-manager configuration
        sed -i '/\bsteam-run\b/d' "$home_manager_file"
        
        echo "steam-run has been removed from user configuration."
        echo "Please run 'home-manager switch' to apply changes."
    else
        echo "No home-manager configuration found."
    fi
}

echo "Do you want to uninstall steam-run? (y/N)"
read -r confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "Choose uninstall scope:"
    echo "1. System-wide (requires sudo)"
    echo "2. User-level"
    read -r scope
    
    case $scope in
        1)
            if [ "$EUID" -ne 0 ]; then
                echo "System-wide uninstallation requires root privileges."
                sudo "$0"
                exit $?
            fi
            uninstall_steam_run_system
            ;;
        2)
            uninstall_steam_run_user
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
else
    echo "Uninstallation cancelled."
    exit 0
fi
