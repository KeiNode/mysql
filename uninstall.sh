#!/usr/bin/env bash
set -euo pipefail

# Interactive MySQL uninstaller for Ubuntu / Debian
# - prompts user (default N) to confirm uninstall
# - stops service, removes packages, removes data and config directories
# - shows checkbox-style progress for each step
# - final banner: Uninstall Mysql SUCCESSFULLY, BYE USER.

BLUE="\e[36m"
RESET="\e[0m"
CHECK_MARK="✓"
CROSS_MARK="✘"

print_header() {
  echo -e "${BLUE}========================================${RESET}"
  echo -e "${BLUE}      UNINSTALL MYSQL - INTERACTIVE     ${RESET}"
  echo -e "${BLUE}========================================${RESET}"
}

print_header

# Prompt (default N)
read -r -p "Do you want to uninstall MySQL? [y/N] " confirm
confirm=${confirm:-N}
case "$confirm" in
  [Yy]|[Yy][Ee][Ss])
    echo "Proceeding with uninstallation..."
    ;;
  *)
    echo "Uninstallation cancelled by user."
    exit 0
    ;;
esac

# Helper to print step status
step_status() {
  local desc="$1"
  local rc=$2
  if [ "$rc" -eq 0 ]; then
    echo -e "[${CHECK_MARK}] $desc"
  else
    echo -e "[${CROSS_MARK}] $desc"
  fi
}

ALL_OK=0

# 1) Stop MySQL service
echo "Stopping MySQL service..."
if sudo systemctl stop mysql >/dev/null 2>&1; then
  step_status "MySQL service stopped" 0
else
  step_status "MySQL service stopped" 1
  ALL_OK=1
fi

# 2) Remove MySQL packages
echo "Removing MySQL packages..."
if sudo apt-get remove --purge -y mysql-server mysql-client mysql-common >/dev/null 2>&1; then
  step_status "MySQL packages removed" 0
else
  step_status "MySQL packages removed" 1
  ALL_OK=1
fi

# 3) Auto-remove dependencies
echo "Auto-removing unused packages..."
if sudo apt-get autoremove -y >/dev/null 2>&1; then
  step_status "Auto-remove completed" 0
else
  step_status "Auto-remove completed" 1
  ALL_OK=1
fi

# 4) Clean apt cache
echo "Cleaning apt cache..."
if sudo apt-get autoclean -y >/dev/null 2>&1; then
  step_status "Apt cache cleaned" 0
else
  step_status "Apt cache cleaned" 1
  ALL_OK=1
fi

# 5) Remove MySQL directories
MYSQL_DATADIR="/var/lib/mysql"
MYSQL_CONFDIR="/etc/mysql"

echo "Removing MySQL data and configuration directories..."
if sudo rm -rf "$MYSQL_DATADIR" "$MYSQL_CONFDIR" >/dev/null 2>&1; then
  step_status "Data and config directories removed" 0
else
  step_status "Data and config directories removed" 1
  ALL_OK=1
fi

# 6) Check for remaining MySQL packages
echo "Checking for remaining MySQL packages..."
if dpkg -l | grep -i mysql >/dev/null 2>&1; then
  step_status "Remaining MySQL packages detected" 1
  ALL_OK=1
else
  step_status "No MySQL packages remaining" 0
fi

# Final banner
if [ "$ALL_OK" -eq 0 ]; then
  echo -e "\n${BLUE}========================================${RESET}"
  echo -e "${BLUE}Uninstall Mysql SUCCESSFULLY, BYE USER.${RESET}"
  echo -e "${BLUE}========================================${RESET}"
  exit 0
else
  echo -e "\n${BLUE}========================================${RESET}"
  echo -e "Some steps failed during uninstallation. Please review the logs above."
  echo -e "Check service logs using: sudo journalctl -u mysql --no-pager"
  echo -e "${BLUE}========================================${RESET}"
  exit 1
fi
