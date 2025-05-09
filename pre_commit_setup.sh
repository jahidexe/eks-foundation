#!/bin/bash
set -e

VENV_DIR=".venv"

echo "🐍 Checking for existing Python virtual environment..."

if [ -d "$VENV_DIR" ]; then
  echo "🔁 Reusing existing virtual environment at $VENV_DIR"
else
  echo "✨ Creating new virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

echo "📦 Installing or upgrading pre-commit..."
pip install --upgrade pip
pip install pre-commit

echo "🔧 Setting up Git hooks..."
pre-commit install
pre-commit autoupdate

echo "✅ pre-commit is set up and ready!"
