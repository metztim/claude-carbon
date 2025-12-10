#!/bin/bash
set -e

# Claude Carbon Hook Installation Script
# Installs Claude Carbon event hooks into ~/.claude/settings.json

SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="${SETTINGS_FILE}.backup.$(date +%s)"

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper function to print colored output
print_status() {
  echo -e "${BLUE}→${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

# Check for jq
check_jq() {
  if ! command -v jq &> /dev/null; then
    return 1
  fi
  return 0
}

# Create settings file with hooks
create_settings_with_hooks() {
  local file=$1
  print_status "Creating new settings file with Claude Carbon hooks..."

  cat > "$file" << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "open -g 'claudecarbon://event?type=prompt&session=$CLAUDE_SESSION_ID'"
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "open -g 'claudecarbon://event?type=stop&session=$CLAUDE_SESSION_ID'"
      }
    ]
  }
}
EOF

  print_success "Settings file created at $file"
}

# Merge hooks into existing settings using jq
merge_hooks_with_jq() {
  local file=$1

  print_status "Merging hooks into existing settings..."

  # Create temporary file with merged content
  jq '.hooks |= . + {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "open -g '\''claudecarbon://event?type=prompt&session=$CLAUDE_SESSION_ID'\''"
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "open -g '\''claudecarbon://event?type=stop&session=$CLAUDE_SESSION_ID'\''"
      }
    ]
  }' "$file" > "${file}.tmp"

  mv "${file}.tmp" "$file"
  print_success "Hooks merged into settings"
}

# Fallback: show manual instructions
show_manual_instructions() {
  cat << 'EOF'

Manual Installation Instructions
=================================

Since jq is not installed, please manually add the following to your
~/.claude/settings.json file:

1. Open ~/.claude/settings.json in your editor:
   nano ~/.claude/settings.json

2. If the file doesn't exist, create it with this content:

{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "open -g 'claudecarbon://event?type=prompt&session=$CLAUDE_SESSION_ID'"
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "open -g 'claudecarbon://event?type=stop&session=$CLAUDE_SESSION_ID'"
      }
    ]
  }
}

3. If the file already has content, add the "hooks" object to the root level:

{
  "existing_key": "value",
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "open -g 'claudecarbon://event?type=prompt&session=$CLAUDE_SESSION_ID'"
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "open -g 'claudecarbon://event?type=stop&session=$CLAUDE_SESSION_ID'"
      }
    ]
  }
}

4. Save the file and restart Claude Code.

EOF
}

# Main installation flow
main() {
  echo ""
  echo "=========================================="
  echo "Claude Carbon Hook Installation"
  echo "=========================================="
  echo ""

  # Check if settings file exists
  if [ -f "$SETTINGS_FILE" ]; then
    print_status "Found existing settings file"

    # Create backup
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    print_success "Backup created at $BACKUP_FILE"

    # Try to merge with jq
    if check_jq; then
      merge_hooks_with_jq "$SETTINGS_FILE"
      print_success "Installation complete!"
      echo ""
      print_status "Claude Carbon hooks installed successfully."
      echo ""
      echo "Next steps:"
      echo "  1. Restart Claude Code"
      echo "  2. Start a new session to activate the hooks"
      echo ""
    else
      print_warning "jq is not installed (required for automatic merge)"
      echo ""
      show_manual_instructions
      exit 1
    fi
  else
    # Settings file doesn't exist - create it
    print_status "Settings file not found, creating new one..."

    # Ensure directory exists
    mkdir -p "$HOME/.claude"

    if check_jq; then
      create_settings_with_hooks "$SETTINGS_FILE"
      print_success "Installation complete!"
      echo ""
      print_status "Claude Carbon hooks installed successfully."
      echo ""
      echo "Next steps:"
      echo "  1. Restart Claude Code"
      echo "  2. Start a new session to activate the hooks"
      echo ""
    else
      print_warning "jq is not installed"
      echo ""
      echo "To install jq:"
      echo "  • macOS (Homebrew): brew install jq"
      echo "  • macOS (MacPorts): sudo port install jq"
      echo "  • Linux (Debian/Ubuntu): sudo apt-get install jq"
      echo "  • Linux (Fedora): sudo dnf install jq"
      echo ""
      show_manual_instructions
      exit 1
    fi
  fi
}

main
