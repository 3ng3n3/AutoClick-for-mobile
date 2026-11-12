#!/usr/bin/env bash

set -Eeuo pipefail

ORANGE='\033[38;5;208m'
CYAN='\033[38;5;45m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'

clear 2>/dev/null || true

printf "${ORANGE}"
cat <<'LOGO'
   ___  ___  ____    ____            __
  / _ \/ _ \/ __/   / __ )____  ____/ /__  _____
 / ___/ /_/ /\ \   / __  / __ \/ __  / _ \/ ___/
/_/   \____/___/  /_/ /_/\___/\__,_/\___/_/
LOGO
printf "${RESET}"
printf "${CYAN}             CPS BOOSTER - ENVIRONMENT SETUP${RESET}\n\n"

info()    { printf "${CYAN}[*]${RESET} %s\n" "$1"; }
success() { printf "${GREEN}[+]${RESET} %s\n" "$1"; }
error()   { printf "${RED}[!]${RESET} %s\n" "$1"; }

if ! command -v python3 >/dev/null 2>&1; then
    info "Python 3 not found. Installing..."

    if command -v pkg >/dev/null 2>&1; then
        pkg update -y
        pkg install -y python
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y python3
    else
        error "Could not detect a supported package manager."
        error "Install Python 3 manually, then run this script again."
        exit 1
    fi
else
    success "Python 3 is already installed."
fi

if ! command -v adb >/dev/null 2>&1; then
    info "ADB not found. Installing..."

    if command -v pkg >/dev/null 2>&1; then
        pkg install -y android-tools
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y android-tools-adb
    else
        error "Could not detect a supported package manager."
        error "Install Android Platform Tools (ADB) manually."
        exit 1
    fi
else
    success "ADB is already installed."
fi

printf "\n"
success "Environment setup completed."
printf "\n"

info "Python version:"
python3 --version

info "ADB version:"
adb version

printf "\n"
printf "${ORANGE}NEXT STEPS${RESET}\n"
printf "1. Enable USB debugging on your Android device.\n"
printf "2. Connect the device and authorize the debugging prompt.\n"
printf "3. Check the connection with: ${CYAN}adb devices${RESET}\n"
printf "4. Run your Python script with: ${CYAN}python3 cps_booster.py${RESET}\n"

printf "\n"
printf "${RED}IMPORTANT${RESET}\n"
printf "The script also uses Android's getevent and input shell commands.\n"
printf "Access to ${CYAN}/dev/input/event2${RESET} may be restricted or require root.\n"
printf "The correct event device can vary between Android devices.\n"
printf "This installer does not root your device or change its permissions.\n"


