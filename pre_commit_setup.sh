#!/bin/bash
set -euo pipefail

# Config
VENV_DIR=".venv"
PYTHON="${PYTHON:-python3}"
CONFIG_FILE=".pre-commit-config.yaml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${YELLOW}🐍 Checking Python virtual environment...${RESET}"
if [ -d "$VENV_DIR" ]; then
  echo -e "${GREEN}🔁 Reusing existing virtual environment: $VENV_DIR${RESET}"
else
  echo -e "${GREEN}✨ Creating virtual environment at $VENV_DIR${RESET}"
  $PYTHON -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Ensure pip and pre-commit are installed
echo -e "${YELLOW}📦 Installing dependencies...${RESET}"
pip install --upgrade pip >/dev/null
pip install --upgrade pre-commit >/dev/null

# Ensure pre-commit config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}❌ '$CONFIG_FILE' not found.${RESET}"
  echo "Please add your pre-commit config first."
  exit 1
fi

echo -e "${GREEN}📂 Found $CONFIG_FILE. Installing Git hooks...${RESET}"
pre-commit install

echo -e "${YELLOW}🔄 Updating pre-commit hook versions...${RESET}"
pre-commit autoupdate

echo -e "${GREEN}✅ Git hooks installed and updated.${RESET}"

# Optional: Display which hooks are configured
echo -e "${YELLOW}🔎 Available hooks:${RESET}"
pre-commit list-hooks --config "$CONFIG_FILE"

# Prompt to run hooks now
read -rp "🚀 Run pre-commit on all files now? (y/N): " choice
case "$choice" in
  y|Y)
    echo -e "${YELLOW}🔍 Running all pre-commit hooks...${RESET}"
    pre-commit run --all-files
    echo -e "${GREEN}✅ Hooks completed successfully.${RESET}"
    ;;
  *)
    echo -e "${YELLOW}💡 Skipped initial run. To run manually later:${RESET}"
    echo -e "   ${GREEN}source $VENV_DIR/bin/activate && pre-commit run --all-files${RESET}"
    ;;
esac