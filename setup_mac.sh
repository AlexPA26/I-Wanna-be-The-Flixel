#!/bin/bash

# Setup script for setting up the HaxeFlixel development environment on macOS.
# This script will install Homebrew (if missing), Haxe, Neko, and all required project libraries.

# Exit immediately if a command exits with a non-zero status
set -e

# Define text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}   I Wanna Be The Flixel - macOS Setup Script     ${NC}"
echo -e "${BLUE}==================================================${NC}"

# 1. Check/Install Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${BLUE}[1/4] Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add brew to PATH for the current session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}[1/4] Homebrew is already installed.${NC}"
fi

# 2. Install Haxe and Neko
echo -e "${BLUE}[2/4] Installing Haxe and Neko...${NC}"
if ! command -v haxe &> /dev/null || ! command -v neko &> /dev/null; then
    brew install haxe neko
    echo -e "${GREEN}Haxe and Neko installed successfully.${NC}"
else
    echo -e "${GREEN}Haxe and Neko are already installed.${NC}"
fi

# 3. Setup Haxelib
echo -e "${BLUE}[3/4] Setting up Haxelib...${NC}"
if [ ! -d "$HOME/haxelib" ]; then
    mkdir -p "$HOME/haxelib"
    haxelib setup "$HOME/haxelib"
else
    echo -e "${GREEN}Haxelib is already set up.${NC}"
fi

# 4. Install Project Libraries
echo -e "${BLUE}[4/4] Installing Haxelib libraries required for the project...${NC}"
haxelib install lime --always
haxelib install openfl --always
haxelib install flixel --always
haxelib install flixel-addons --always
haxelib install flixel-ui --always
haxelib install hxcpp --always

# 5. Run Lime setup
echo -e "${BLUE}Running Lime setup...${NC}"
haxelib run lime setup

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   Setup Complete! Development environment ready. ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "To compile the project for macOS, run:"
echo -e "  ${BLUE}lime build mac -release${NC}"
echo -e "To run a test build, run:"
echo -e "  ${BLUE}lime test mac${NC}"
