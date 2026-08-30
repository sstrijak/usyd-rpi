#!/usr/bin/env bash

# This script will install required packages and drivers to use Intel AX210 WiFi 6E card on Raspberry Pi
# Full guide available from http://wiki.zde.plus/ZP585, but there is no need to compile the driver (it also errors out). Instead, the script downloads the driver from git.kernel.org

set -eo pipefail

# ==========================================
# Helpers & Formatting
# ==========================================
RED='\033[0;32m\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1" >&2; exit 1; }

# ==========================================
# 0. Root Privilege Check
# ==========================================
if [[ "$EUID" -ne 0 ]]; then
  error "This script must be run as root. Please run with: sudo $0"
fi

# ==========================================
# 1. Hardware Detection Check
# ==========================================
info "Checking for Intel AX210 PCIe hardware..."
if ! command -v lspci &>/dev/null; then
  info "Installing pciutils to inspect PCIe bus..."
  apt-get update -qq && apt-get install -y -qq pciutils
fi

if ! lspci | grep -Ei "AX210|Typhoon Peak|Intel.*(Wireless|Wi-Fi)" >/dev/null 2>&1; then
  error "Intel AX210 hardware not detected on the PCIe bus. Check physical connection / HAT configuration."
fi
info "Intel Wi-Fi card detected on PCIe bus."

# ==========================================
# 2. Package & Header Installation
# ==========================================
KERNEL_VER="$(uname -r)"
info "Kernel release detected: $KERNEL_VER"
info "Updating apt package index and installing dependencies..."

apt-get update -y

REQUIRED_PACKAGES=(
  "linux-headers-${KERNEL_VER}"
  firmware-iwlwifi
  flex
  bison
  wget
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
  info "Installing $pkg..."
  if ! apt-get install -y "$pkg"; then
    warn "Direct package '$pkg' installation failed. Attempting general headers metapackage..."
    apt-get install -y linux-headers-rpi-2712 || apt-get install -y linux-headers-rpi-v8 || true
  fi
done

# ==========================================
# 3. Firmware Download & Placement
# ==========================================
FIRMWARE_DIR="/lib/firmware"
INTEL_DIR="/lib/firmware/intel"

UCODE_FILE="iwlwifi-ty-a0-gf-a0-89.ucode"
PNVM_FILE="iwlwifi-ty-a0-gf-a0.pnvm"

URL_UCODE_PRIMARY="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/intel/iwlwifi/${UCODE_FILE}"
URL_UCODE_BACKUP="https://raw.githubusercontent.com/armbian/firmware/master/${UCODE_FILE}"
URL_PNVM="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/intel/iwlwifi/${PNVM_FILE}"

mkdir -p "$FIRMWARE_DIR" "$INTEL_DIR"

# Download microcode (.ucode)
info "Fetching $UCODE_FILE..."
if ! wget -q --spider "$URL_UCODE_PRIMARY"; then
  warn "Primary source unavailable. Falling back to mirror..."
  wget -O "${FIRMWARE_DIR}/${UCODE_FILE}" "$URL_UCODE_BACKUP" || error "Failed to download $UCODE_FILE"
else
  wget -O "${FIRMWARE_DIR}/${UCODE_FILE}" "$URL_UCODE_PRIMARY" || error "Failed to download $UCODE_FILE"
fi

# Download PNVM (.pnvm)
info "Fetching $PNVM_FILE..."
wget -O "${FIRMWARE_DIR}/${PNVM_FILE}" "$URL_PNVM" || warn "PNVM file download failed (may not be critical on all revisions)."

# Place copies into /lib/firmware/intel
info "Syncing firmware into $INTEL_DIR..."
cp -f "${FIRMWARE_DIR}/${UCODE_FILE}" "${INTEL_DIR}/"
[[ -f "${FIRMWARE_DIR}/${PNVM_FILE}" ]] && cp -f "${FIRMWARE_DIR}/${PNVM_FILE}" "${INTEL_DIR}/"

# ==========================================
# 4. Kernel Module Reload
# ==========================================
info "Reloading iwlwifi kernel modules..."
modprobe -r iwlmvm 2>/dev/null || true
modprobe -r iwlwifi 2>/dev/null || true
modprobe iwlwifi || error "Failed to load iwlwifi module."

# Give the subsystem a second to initialize
sleep 2

# ==========================================
# 5. Verification & Interface Status
# ==========================================
info "Verifying driver initialization in kernel logs..."
if dmesg | grep -i "loaded firmware version" | tail -n 5; then
  info "Driver loaded firmware successfully."
else
  warn "Driver loaded, but firmware banner was not explicitly found in recent dmesg output."
fi

echo ""
info "Listing active network interfaces:"
ip -br link show

echo ""
# Identify newly created wireless interfaces
WLAN_IFS=$(ip -br link show | awk '$1 ~ /^wlan/ {print $1}')

if [[ -n "$WLAN_IFS" ]]; then
  info "Wireless interface(s) available: $WLAN_IFS"
  for iface in $WLAN_IFS; do
    ip link set "$iface" up 2>/dev/null || true
  done
  info "Setup complete. Intel AX210 is ready for use."
else
  error "No wireless interfaces detected. Check 'dmesg | grep -i iwl' for runtime initialization errors."
fi




