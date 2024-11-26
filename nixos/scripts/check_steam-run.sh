#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/steam_run_utils.sh"

check_steam_run() {
    if nix-store -qR /run/current-system | grep -q steam-run; then
        echo "steam-run is installed system-wide"
        return 0
    fi

    if nix-env -q | grep -q steam-run; then
        echo "steam-run is installed in user profile"
        return 0
    fi

    echo "steam-run is not installed"
    return 1
}

main() {
    if [ ! -f /etc/NIXOS ]; then
        echo "Error: This script is intended for NixOS only"
        exit 1
    }

    check_sudo_privileges
    check_configuration_file
    
    check_steam_run
    exit $?
}

main
