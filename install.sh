#!/usr/bin/env bash

# ==============================================================================
# Capsule Launcher - Installer Script for KDE Plasma 6
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

WIDGET_ID="capsule-launcher"
WIDGET_NAME="Capsule Launcher"
DEST_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}${BOLD}"
echo "  ╔════════════════════════════════════════════════════════════╗"
echo "  ║              CAPSULE LAUNCHER - INSTALLER                  ║"
echo "  ║     Modern Pill Search Bar & 6-App Dock for KDE Plasma 6   ║"
echo "  ╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}[*] Preparing installation for '${WIDGET_NAME}'...${NC}"

# Ensure parent directory exists
mkdir -p "$HOME/.local/share/plasma/plasmoids"

# If cloned outside ~/.local/share/plasma/plasmoids/desktop-app, copy files
if [ "$SCRIPT_DIR" != "$DEST_DIR" ]; then
    echo -e "${BLUE}[*] Copying widget files to:${NC} $DEST_DIR"
    mkdir -p "$DEST_DIR"
    cp -r "$SCRIPT_DIR/metadata.json" "$DEST_DIR/"
    cp -r "$SCRIPT_DIR/contents" "$DEST_DIR/"
    [ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$DEST_DIR/"
    [ -f "$SCRIPT_DIR/install.sh" ] && cp "$SCRIPT_DIR/install.sh" "$DEST_DIR/" && chmod +x "$DEST_DIR/install.sh"
    [ -f "$SCRIPT_DIR/uninstall.sh" ] && cp "$SCRIPT_DIR/uninstall.sh" "$DEST_DIR/" && chmod +x "$DEST_DIR/uninstall.sh"
else
    echo -e "${BLUE}[*] Detected running directly from Plasmoids directory:${NC} $DEST_DIR"
fi

# Refresh Plasma sycoca cache
if command -v kbuildsycoca6 &> /dev/null; then
    kbuildsycoca6 --noincremental &> /dev/null || true
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Installation Successful!${NC}"
echo ""
echo -e "${CYAN}${BOLD}How to add the widget to your Desktop:${NC}"
echo -e "  1. ${BOLD}Right-click${NC} anywhere on your KDE Desktop."
echo -e "  2. Select ${BOLD}'Add Widgets...'${NC} (or 'Tambah Widget...')."
echo -e "  3. Search for ${BOLD}'${WIDGET_NAME}'${NC}."
echo -e "  4. Drag and drop it onto your desktop!"
echo ""
echo -e "${YELLOW}Tips:${NC}"
echo -e "  - Type in the top search bar to instantly filter your apps."
echo -e "  - Press ${BOLD}Enter${NC} in the search bar to launch the first result."
echo -e "  - Click the ${BOLD}<${NC} and ${BOLD}>${NC} arrow buttons to navigate."
echo -e "  - Use your ${BOLD}mouse wheel${NC} on the dock to quickly scroll through apps!"
echo ""
