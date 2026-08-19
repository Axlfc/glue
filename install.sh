#!/usr/bin/env bash
# install.sh - Installer for glue

set -e

GLUE_TARGET_DIR="${GLUE_TARGET_DIR:-$HOME/.glue}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing glue into $GLUE_TARGET_DIR..."

if [[ "$REPO_DIR" != "$GLUE_TARGET_DIR" ]]; then
    mkdir -p "$GLUE_TARGET_DIR"
    cp -rf "$REPO_DIR"/* "$GLUE_TARGET_DIR"/
fi

# Ensure default config exists
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/glue"
mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_DIR/config" ]]; then
    if [[ -f "$GLUE_TARGET_DIR/config/glue.conf.example" ]]; then
        cp "$GLUE_TARGET_DIR/config/glue.conf.example" "$CONFIG_DIR/config"
        echo "Created default config at $CONFIG_DIR/config"
    fi
fi

# Function to safely append source line to shell RC file
add_to_rc() {
    local rc_file="$1"
    local source_line="source $GLUE_TARGET_DIR/glue.sh"

    if [[ -f "$rc_file" ]]; then
        if ! grep -Fq "$source_line" "$rc_file"; then
            echo "" >> "$rc_file"
            echo "# Glue package manager wrapper" >> "$rc_file"
            echo "$source_line" >> "$rc_file"
            echo "Added glue source line to $rc_file"
        else
            echo "Glue is already sourced in $rc_file"
        fi
    fi
}

add_to_rc "$HOME/.bashrc"
add_to_rc "$HOME/.zshrc"

echo ""
echo "Glue installation complete!"
echo "To start using glue immediately, run:"
echo "  source $GLUE_TARGET_DIR/glue.sh"
