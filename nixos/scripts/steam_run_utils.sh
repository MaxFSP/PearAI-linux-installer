#!/usr/bin/env bash

get_sudo_user() {
    logname || whoami
}

check_sudo_privileges() {
    if ! sudo -v; then
        echo "Error: This script requires sudo privileges"
        exit 1
    fi
}

check_configuration_file() {
    if [ ! -f /etc/nixos/configuration.nix ]; then
        echo "Error: configuration.nix not found in /etc/nixos/"
        exit 1
    fi
}

check_unfree() {
    if sudo grep -q "^\s*nixpkgs.config.allowUnfree\s*=\s*true\s*;" /etc/nixos/configuration.nix; then
        echo "Unfree packages are enabled system-wide"
        return 0
    fi

    if sudo grep -q "^\s*#.*nixpkgs.config.allowUnfree\s*=\s*true\s*;" /etc/nixos/configuration.nix; then
        echo "Unfree packages setting exists but is commented system-wide"
        return 2
    fi

    echo "Unfree packages are not enabled"
    return 1
}

enable_unfree() {
    if [ ! -f /etc/nixos/configuration.nix.backup ]; then
        sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
    fi

    if sudo grep -q "^\s*#.*nixpkgs.config.allowUnfree\s*=\s*true\s*;" /etc/nixos/configuration.nix; then
        sudo sed -i 's/^\s*#\s*nixpkgs\.config\.allowUnfree\s*=\s*true\s*;/  nixpkgs.config.allowUnfree = true;/' /etc/nixos/configuration.nix
    else
        sudo sed -i '/^{/a\  nixpkgs.config.allowUnfree = true;' /etc/nixos/configuration.nix
    fi
}

rebuild_system() {
    echo "Rebuilding NixOS configuration..."
    if sudo nixos-rebuild switch; then
        echo "System successfully rebuilt"
        return 0
    else
        echo "Error: Failed to rebuild system"
        return 1
    fi
}
#!/bin/bash

# Check if steam-run is installed system-wide
check_system_steam_run() {
    if nixos-rebuild dry-build 2>&1 | grep -q "steam-run"; then
        return 0  # Found
    fi
    return 1  # Not found
}

# Check if steam-run is installed via home-manager
check_user_steam_run() {
    if [ -f "$HOME/.config/home-manager/home.nix" ] && grep -q "steam-run" "$HOME/.config/home-manager/home.nix"; then
        return 0  # Found
    fi
    return 1  # Not found
}

# Check if steam-run is available in path
check_steam_run_available() {
    if command -v steam-run >/dev/null 2>&1; then
        return 0  # Found
    fi
    return 1  # Not found
}

# Verify steam-run functionality
test_steam_run() {
    if steam-run echo "test" >/dev/null 2>&1; then
        return 0  # Working
    fi
    return 1  # Not working
}
