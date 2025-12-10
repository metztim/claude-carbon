#!/bin/bash
set -e

# Claude Carbon Hook Uninstallation Script
# Removes Claude Carbon event hooks from ~/.claude/settings.json

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

# Remove hooks from settings using jq
remove_hooks_with_jq() {
  local file=$1

  print_status "Removing Claude Carbon hooks from settings..."

  # Create temporary file with hooks removed
  jq 'del(.hooks.UserPromptSubmit, .hooks.Stop) | if .hooks == {} then del(.hooks) else . end' "$file" > "${file}.tmp"

  mv "${file}.tmp" "$file"
  print_success "Hooks removed from settings"
}

# Show manual instructions
show_manual_instructions() {
  cat << 'EOF'

Manual Uninstallation Instructions
===================================

Since jq is not installed, please manually remove the Claude Carbon hooks from
your ~/.claude/settings.json file:

1. Open ~/.claude/settings.json in your editor:
   nano ~/.claude/settings.json

2. Remove or modify the "hooks" object. Look for entries like:

   "UserPromptSubmit": [
     {
       "type": "command",
       "command": "open -g 'claudecarbon://event?type=prompt&session=$CLAUDE_SESSION_ID'"
     }
   ]

   and

   "Stop": [
     {
       "type": "command",
       "command": "open -g 'claudecarbon://event?type=stop&session=$CLAUDE_SESSION_ID'"
     }
   ]

3. If these are the only hooks, you can delete the entire "hooks" object.
   If there are other hooks, just remove the UserPromptSubmit and Stop entries.

4. Save the file and restart Claude Code.

EOF
}

# Main uninstallation flow
main() {
  echo ""
  echo "=========================================="
  echo "Claude Carbon Hook Uninstallation"
  echo "=========================================="
  echo ""

  # Check if settings file exists
  if [ ! -f "$SETTINGS_FILE" ]; then
    print_status "Settings file not found - nothing to uninstall"
    echo ""
    echo "Claude Carbon hooks are not installed."
    echo ""
    exit 0
  fi

  print_status "Found settings file"

  # Check if hooks exist
  if ! check_jq; then
    print_warning "jq is not installed (required for automatic removal)"
    echo ""
    show_manual_instructions
    exit 1
  fi

  # Verify hooks exist before proceeding
  if ! jq -e '.hooks.UserPromptSubmit // .hooks.Stop' "$SETTINGS_FILE" > /dev/null 2>&1; then
    print_status "Claude Carbon hooks not found in settings"
    echo ""
    echo "No Claude Carbon hooks to remove."
    echo ""
    exit 0
  fi

  # Create backup
  cp "$SETTINGS_FILE" "$BACKUP_FILE"
  print_success "Backup created at $BACKUP_FILE"

  # Remove hooks
  remove_hooks_with_jq "$SETTINGS_FILE"

  print_success "Uninstallation complete!"
  echo ""
  print_status "Claude Carbon hooks have been removed."
  echo ""
  echo "Next steps:"
  echo "  1. Restart Claude Code"
  echo "  2. Start a new session to apply the changes"
  echo ""
  echo "Your settings backup has been saved to:"
  echo "  $BACKUP_FILE"
  echo ""
}

main
