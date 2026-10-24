#!/usr/bin/env bash

# ==============================================================================
# Capsule Launcher - Uninstaller Script
# ==============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

WIDGET_ID="desktop-app"
DEST_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID"

echo -e "${YELLOW}${BOLD}[*] Uninstalling Capsule Launcher...${NC}"

if [ -d "$DEST_DIR" ]; then
    rm -rf "$DEST_DIR"
    echo -e "${GREEN}✓ Removed files from:${NC} $DEST_DIR"
fi

if command -v kbuildsycoca6 &> /dev/null; then
    kbuildsycoca6 --noincremental &> /dev/null || true
fi

echo -e "${GREEN}${BOLD}✓ Capsule Launcher has been uninstalled.${NC}"
