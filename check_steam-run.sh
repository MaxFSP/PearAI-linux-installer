#!/usr/bin/env bash
get_sudo_user() {
logname || whoami
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

install_steam_run_system() {
# Check if steam-run is already in configuration
if sudo grep -q "steam-run" /etc/nixos/configuration.nix; then
    echo "steam-run is already in configuration.nix"
    return 0
fi

# Backup configuration
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup

# Check for existing systemPackages section
if sudo grep "environment\.systemPackages = with pkgs;" /etc/nixos/configuration.nix; then
    # Add steam-run to existing package list if not already present
    if ! sudo grep "steam-run" /etc/nixos/configuration.nix; then
        sudo sed -i '/environment\.systemPackages = with pkgs; /a\    steam-run' /etc/nixos/configuration.nix
    fi
else
    # Add new package list with steam-run
    sudo sed -i '/^}/i \  environment.systemPackages = with pkgs; [\n    steam-run\n  ];' /etc/nixos/configuration.nix
fi

if [ $? -eq 0 ]; then
    echo "Successfully added steam-run to system packages"
    return 0
else
    echo "Failed to add steam-run to system packages"
    sudo mv /etc/nixos/configuration.nix.backup /etc/nixos/configuration.nix
    return 1
fi
}
install_steam_run_user() {
  local username="$(get_sudo_user)"
  echo "Adding steam-run to user ${username} packages..."

  if [ -z "${username}" ] || ! id "${username}" >/dev/null 2>&1; then
      echo "Error: Invalid username"
      return 1
  fi

  # Create or update ~/.config/nixpkgs/config.nix for the user
  local user_nixpkgs_dir="/home/${username}/.config/nixpkgs"
  local user_config_file="${user_nixpkgs_dir}/config.nix"

  # Create directory if it doesn't exist
  sudo -u "${username}" mkdir -p "${user_nixpkgs_dir}"

  # Create or update config.nix
  if [ ! -f "${user_config_file}" ]; then
      sudo -u "${username}" bash -c "cat > '${user_config_file}'" << 'EOF'
{
allowUnfree = true;
}
EOF
  fi

  # Set proper permissions
  sudo chown -R "${username}:${username}" "${user_nixpkgs_dir}"

  echo "Attempting to install steam-run for user ${username}..."
  if sudo -u "${username}" nix-env -iA nixos.steam-run; then
      echo "Successfully installed steam-run for user ${username}"
      return 0
  else
      echo "Failed to install steam-run for user ${username}"
      return 1
  fi
}

check_configuration_file() {
if [ ! -f /etc/nixos/configuration.nix ]; then
    echo "Error: configuration.nix not found in /etc/nixos/"
    exit 1
fi
}

check_sudo_privileges() {
if ! sudo -v; then
    echo "Error: This script requires sudo privileges"
    exit 1
fi
}

handle_unfree_packages() {
check_unfree
local unfree_status=$?

case $unfree_status in
    0)
        echo "Unfree packages are already enabled, proceeding..."
        ;;
    1|2)
        echo "Unfree packages must be enabled to install steam-run."
        read -p "Would you like to enable unfree packages? (y/n): " enable_choice

        if [[ $enable_choice =~ ^[Yy]$ ]]; then
            enable_unfree
        else
            echo "Cannot proceed without enabling unfree packages."
            exit 1
        fi
        ;;
esac
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

main() {
if [ ! -f /etc/NIXOS ]; then
    echo "Error: This script is intended for NixOS only"
    exit 1
fi

check_sudo_privileges
check_configuration_file
handle_unfree_packages

check_steam_run
local steam_run_status=$?

if [ $steam_run_status -eq 0 ]; then
    echo "steam-run is already installed."
    exit 0
fi

echo "Where would you like to install steam-run?"
echo "1) System-wide (available to all users)"
echo "2) User profile (only for current user)"
echo "3) Cancel installation"
read -p "Enter your choice (1/2/3): " choice

case $choice in
    1)
        if install_steam_run_system; then
            rebuild_system && {
                echo "Installation completed successfully!"
                echo "You may need to log out and back in for the changes to take effect."
                exit 0
            }
        fi
        ;;
    2)
        if install_steam_run_user; then
            echo "Installation completed successfully!"
            echo "You may need to log out and back in for the changes to take effect."
            exit 0
        fi
        ;;
    3)
        echo "Installation cancelled by user."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Installation failed."
exit 1
}

main
