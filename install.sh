#!/usr/bin/env bash
set -euo pipefail

# Simple interactive MySQL installer for Ubuntu / Debian
# - shows a sea-blue ASCII banner
# - prompts user (default Y) to continue
# - installs MySQL to the system-recommended data directory (/var/lib/mysql)
# - prints checkbox-style progress for each step
# - reminds user to run mysql_secure_installation

BLUE="\e[36m"
RESET="\e[0m"
CHECK_MARK="✓"
CROSS_MARK="✘"

print_banner() {
  cat <<'BANNER'
 ________ ________  ________   ________  ________  ___               
|\  _____\\   __  \|\   ___  \|\   ____\|\   __  \|\  \              
\ \  \__/\ \  \|\  \ \  \\ \  \ \  \___|\ \  \|\  \ \  \             
 \ \   __\\ \   __  \ \  \\ \  \ \_____  \ \  \\\  \ \  \            
  \ \  \_| \ \  \ \  \ \  \\ \  \|____|\  \ \  \\\  \ \  \____      
   \ \__\   \ \__\ \__\ \__\\ \__\____\_\  \ \_____  \ \_______\   
    \|__|    \|__|\|__|\|__| \|__|\_________\|___| \__\|_______|   
                                      \|_________|     \|__|      
BANNER
}

# Print colored banner
echo -e "${BLUE}"
print_banner
echo -e "${RESET}"

# Prompt (default Y)
read -r -p "Do you want to proceed with installation? [Y/n] " answer
answer=${answer:-Y}
case "$answer" in
  [Yy]|[Yy][Ee][Ss]|"")
    echo "Proceeding with installation..."
    ;;
  *)
    echo "Installation cancelled by user."
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

# 1) Update package index
echo "Updating package index..."
if sudo apt-get update -y >/dev/null 2>&1; then
  step_status "Package index updated" 0
else
  step_status "Package index updated" 1
fi

# 2) Install MySQL server
echo "Installing mysql-server package..."
if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server >/dev/null 2>&1; then
  step_status "mysql-server installed" 0
else
  step_status "mysql-server installed" 1
fi

# 3) Enable and start MySQL service
echo "Enabling and starting MySQL service..."
if sudo systemctl enable mysql >/dev/null 2>&1 && sudo systemctl start mysql >/dev/null 2>&1; then
  step_status "MySQL service enabled and started" 0
else
  step_status "MySQL service enabled and started" 1
fi

# 4) Recommended data directory (system default)
MYSQL_DATADIR="/var/lib/mysql"
echo "MySQL data directory: $MYSQL_DATADIR"
if [ -d "$MYSQL_DATADIR" ]; then
  step_status "Recommended data directory exists ($MYSQL_DATADIR)" 0
else
  step_status "Recommended data directory exists ($MYSQL_DATADIR)" 1
fi

# 5) Post-install recommendation
echo "IMPORTANT: Please run 'sudo mysql_secure_installation' to secure your MySQL installation."
echo "If you plan to connect remotely, also ensure you configure bind-address and firewall rules."

# Final check: is the service active?
if sudo systemctl is-active --quiet mysql; then
  echo -e "\n${BLUE}========================================${RESET}"
  echo -e "${BLUE}INSTALLATION SUCCESSFULLY${RESET}"
  echo -e "${BLUE}========================================${RESET}"
  exit 0
else
  echo -e "\n${BLUE}========================================${RESET}"
  echo -e "Installation finished, but MySQL service is not active."
  echo -e "Please check logs: sudo journalctl -u mysql --no-pager"
  echo -e "${BLUE}========================================${RESET}"
  exit 1
fi
