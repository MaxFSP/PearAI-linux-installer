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

check_steam_run_location() {
  if sudo nix-store -qR /run/current-system | grep -q steam-run; then
      echo "system"
  elif nix-env -q | grep -q steam-run; then
      echo "user"
  else
      echo ""
  fi
}

remove_steam_run() {
  local remove_type=$1  # "system" or "user"

  if [ "$remove_type" = "system" ]; then
      # Backup configuration if backup doesn't exist
      if [ ! -f /etc/nixos/configuration.nix.backup ]; then
          sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
      fi

      # Create temp file
      local temp_file=$(mktemp)
      sudo cp /etc/nixos/configuration.nix "$temp_file"

      # Remove steam-run from configuration
      sudo sed -i '/steam-run/d' "$temp_file"

      # Clean up empty package lists if needed
      sed -i '/environment\.systemPackages = with pkgs; $\s*$/d' "$temp_file"

      sudo cp "$temp_file" /etc/nixos/configuration.nix
      rm "$temp_file"

      echo "Removed steam-run from system configuration"
      return 0
  elif [ "$remove_type" = "user" ]; then
      local username="$(get_sudo_user)"
      if sudo -u "${username}" nix-env -e steam-run; then
          echo "Removed steam-run from user profile"
          return 0
      else
          echo "Failed to remove steam-run from user profile"
          return 1
      fi
  fi
}

remove_unfree() {
  # Backup configuration if backup doesn't exist
  if [ ! -f /etc/nixos/configuration.nix.backup ]; then
      sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
  fi

  # Create temp file
  local temp_file=$(mktemp)
  sudo cp /etc/nixos/configuration.nix "$temp_file"

  # Remove unfree setting
  sudo sed -i '/nixpkgs\.config\.allowUnfree\s*=\s*true/d' "$temp_file"

  sudo cp "$temp_file" /etc/nixos/configuration.nix
  rm "$temp_file"

  echo "Removed unfree package setting"
  return 0
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

handle_removal() {
  echo "Do you want to remove unfree package support as well?"
  echo "1) Yes, remove both steam-run and unfree package support"
  echo "2) No, only remove steam-run"
  echo "3) Cancel removal"
  read -p "Enter your choice (1/2/3): " choice

  case $choice in
      1)
          # Remove both steam-run and unfree
          local install_type=$(check_steam_run_location)
          if [ -n "$install_type" ]; then
	      remove_steam_run "$install_type"
              #sudo sed -i '/steam-run/d' /etc/nixos/configuration.nix
              remove_unfree
              rebuild_system && {
                  echo "Successfully removed steam-run and unfree package support"
                  echo "You may need to log out and back in for the changes to take effect."
                  exit 0
              }
          fi
          ;;
      2)
          # Only remove steam-run
          local install_type=$(check_steam_run_location)
          if [ -n "$install_type" ]; then
              remove_steam_run "$install_type"
              rebuild_system && {
                  echo "Successfully removed steam-run"
                  echo "You may need to log out and back in for the changes to take effect."
                  exit 0
              }
          fi
          ;;
      3)
          echo "Removal cancelled."
          exit 0
          ;;
      *)
          echo "Invalid choice. Exiting."
          exit 1
          ;;
  esac
}

main() {
  if [ ! -f /etc/NIXOS ]; then
      echo "Error: This script is intended for NixOS only"
      exit 1
  fi

  check_sudo_privileges
  check_configuration_file

  local install_type=$(check_steam_run_location)
  if [ -z "$install_type" ]; then
      echo "steam-run is not installed"
      exit 0
  fi

  echo "Found steam-run installed as: $install_type"
  handle_removal
}

# Run the script
main
