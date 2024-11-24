#!/bin/bash

source "$(dirname "\$0")/scripts/pearai_config.sh"
source "$(dirname "\$0")/scripts/utils.sh"

ensure_log_file

# Function to modify NixOS configuration
modify_nixos_config() {
  local config_file="/etc/nixos/configuration.nix"

  if [ ! -f "$config_file" ]; then
      log "Error: configuration.nix not found"
      return 1
  fi

  cp "$config_file" "${config_file}.backup"

  if grep -q "environment.systemPackages" "$config_file"; then
      sed -i '/environment.systemPackages = with pkgs; $/a \    steam-run' "$config_file"
  else
      sed -i '/^}/i \  environment.systemPackages = with pkgs; [\n    steam-run\n  ];' "$config_file"
  fi

  if [ $? -eq 0 ]; then
      log "Successfully modified NixOS configuration"
      return 0
  else
      log "Failed to modify NixOS configuration"
      mv "${config_file}.backup" "$config_file"
      return 1
  fi
}

# Function to display help
show_help() {
  echo "Usage: \$0 [option]"
  echo "Options:"
  echo "  -h, --help     Show this help message"
  echo "  -v, --version  Show PearAI version"
  echo "  -d, --docs     Show PearAI docs"
  echo "  install        Install PearAI"
  echo "  uninstall      Uninstall PearAI"
  echo "  nix-install    Install PearAI on NixOS"
  echo "  nix-uninstall  Uninstall PearAI from NixOS"
}

# Function to display the main menu
display_menu() {
  clear
  echo "================================"
  echo "    PearAI Manager v$PEARAI_VERSION"
  echo "================================"
  echo "1. Install PearAI"
  echo "2. Uninstall PearAI"
  echo "3. Install PearAI on NixOS"
  echo "4. Uninstall PearAI from NixOS"
  echo "5. Exit"
  echo "================================"
  echo -n "Enter your choice [1-5]: "
}

# Function to install PearAI
install_pearai() {
  log "Starting installation"
  if [ "$EUID" -ne 0 ]; then
      sudo bash "$(dirname "\$0")/scripts/install_pearai.sh"
  else
      bash "$(dirname "\$0")/scripts/install_pearai.sh"
  fi

  local result=$?
  if [ $result -eq 0 ]; then
      log "PearAI installation completed successfully"
      return 0
  else
      echo "Installation failed. Check the log for details."
      log "Installation failed"
      return 1
  fi
}

# Function to uninstall PearAI
uninstall_pearai() {
  echo "Are you sure you want to uninstall PearAI? (y/N)"
  read -r confirm
  if [[ $confirm =~ ^[Yy]$ ]]; then
      log "Starting uninstallation"
      if [ "$EUID" -ne 0 ]; then
          sudo bash "$(dirname "\$0")/scripts/uninstall_pearai.sh"
      else
          sudo bash "$(dirname "\$0")/scripts/uninstall_pearai.sh"
      fi

      local result=$?
      if [ $result -eq 0 ]; then
          log "PearAI uninstallation completed successfully"
          return 0
      else
          log "Uninstallation failed"
          return 1
      fi
  else
      log "Uninstallation cancelled by user"
      return 1
  fi
}

# Function to install PearAI on NixOS
install_pearai_nixos() {
  log "Starting NixOS installation"

  bash "check_steam-run.sh"
  local check_result=$?

  if [ $check_result -ne 0 ]; then
      log "Steam-run check failed"
      return 1
  fi

  #modify_nixos_config
  local install_result=$?

  if [ $install_result -eq 0 ]; then
      log "PearAI NixOS installation completed successfully"
      echo "Please rebuild NixOS configuration with: sudo nixos-rebuild switch"
      bash "nixos/scripts/install_pearai.sh"
      return 0
  else
      log "NixOS installation failed"
      echo "Installation failed. Check the logs for details."
      return 1
  fi
}

# Function to uninstall PearAI from NixOS
uninstall_pearai_nixos() {
  echo "Are you sure you want to uninstall PearAI from NixOS? (y/N)"
  read -r confirm
  if [[ $confirm =~ ^[Yy]$ ]]; then
      log "Starting NixOS uninstallation"
      bash "nixos/scripts/uninstall_pearai.sh"
      local result=$?
      if [ $result -eq 0 ]; then
          log "PearAI NixOS uninstallation completed successfully"
          return 0
      else
          log "NixOS uninstallation failed"
          return 1
      fi
  else
      log "NixOS uninstallation cancelled by user"
      return 1
  fi
}

# Trap for clean exit
trap 'echo "Script interrupted. Exiting..."; exit 1' INT TERM

# Check for command-line arguments
case "\$1" in
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
      exit $?
      ;;
  uninstall)
      uninstall_pearai
      exit $?
      ;;
  nix-install)
      install_pearai_nixos
      exit $?
      ;;
  nix-uninstall)
      uninstall_pearai_nixos
      exit $?
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
          install_pearai_nixos
          ;;
      4)
          uninstall_pearai_nixos
          ;;
      5)
          echo "Exiting PearAI Manager. Goodbye!"
          log "PearAI Manager exited normally"
          exit 0
          ;;
      *)
          echo "Invalid option. Please try again."
          log "Invalid option selected"
          ;;
  esac

  echo
  read -p "Press Enter to continue..."
done
