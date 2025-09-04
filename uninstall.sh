#!/bin/bash

# KruRooAI Uninstall Script
# Safely removes KruRooAI from the system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

echo "🗑️  KruRooAI Uninstall Script"
echo "============================="
echo ""
print_warning "This will remove KruRooAI from your system"
echo ""

if ! confirm "Are you sure you want to continue?"; then
    echo "Uninstall cancelled"
    exit 0
fi

echo ""

# 1. Remove global command
print_status "Removing global command..."
if [ -L "/usr/local/bin/krurooai" ] || [ -f "/usr/local/bin/krurooai" ]; then
    if sudo rm -f /usr/local/bin/krurooai; then
        print_success "Global command removed"
    else
        print_error "Failed to remove global command"
    fi
else
    print_success "Global command not found (already removed)"
fi

# 2. Ask about workspace
echo ""
if [ -d "$HOME/KruRooAI-Work" ]; then
    print_status "Found workspace at ~/KruRooAI-Work"
    echo "Contents:"
    ls -la "$HOME/KruRooAI-Work" 2>/dev/null || echo "  (empty or inaccessible)"
    echo ""
    
    if confirm "Remove workspace directory? (This will delete all your data/contexts/reports)"; then
        rm -rf "$HOME/KruRooAI-Work"
        print_success "Workspace removed"
    else
        print_warning "Workspace kept at ~/KruRooAI-Work"
    fi
else
    print_success "No workspace found"
fi

# 3. Ask about project directory
echo ""
PROJECT_DIR=$(pwd)
print_status "Current project directory: $PROJECT_DIR"

if [[ "$PROJECT_DIR" == *"krurooai-project" ]]; then
    echo ""
    print_warning "You are currently in the project directory"
    print_status "After this script finishes, you should run:"
    print_status "  cd .."
    print_status "  rm -rf krurooai-project"
    
    SHOULD_REMOVE_PROJECT=true
else
    if confirm "Remove project directory at $PROJECT_DIR?"; then
        SHOULD_REMOVE_PROJECT=true
    else
        SHOULD_REMOVE_PROJECT=false
    fi
fi

# 4. Ask about Ollama models
echo ""
print_status "Checking Ollama models..."
if command -v ollama &> /dev/null; then
    MODELS=$(ollama list 2>/dev/null | grep -E "(gpt-oss|llama)" | awk '{print $1}' || true)
    
    if [ -n "$MODELS" ]; then
        print_status "Found AI models:"
        echo "$MODELS"
        echo ""
        
        if confirm "Remove AI models? (Warning: These are large downloads)"; then
            echo "$MODELS" | while read -r model; do
                if [ -n "$model" ]; then
                    print_status "Removing model: $model"
                    ollama rm "$model" || print_warning "Failed to remove $model"
                fi
            done
            print_success "AI models removed"
        else
            print_warning "AI models kept"
        fi
    else
        print_success "No KruRooAI models found"
    fi
    
    # Ask about Ollama itself
    echo ""
    if confirm "Remove Ollama entirely? (Only if you don't use it for other projects)"; then
        print_status "Stopping Ollama service..."
        pkill ollama 2>/dev/null || true
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null && brew list | grep -q ollama; then
                brew uninstall ollama
                print_success "Ollama uninstalled via Homebrew"
            else
                print_warning "Ollama not installed via Homebrew, manual removal may be needed"
            fi
        else
            # Linux
            sudo rm -f /usr/local/bin/ollama
            sudo rm -rf /usr/share/ollama
            rm -rf "$HOME/.ollama" 2>/dev/null || true
            print_success "Ollama removed"
        fi
    else
        print_warning "Ollama kept (you can still use it for other projects)"
    fi
else
    print_success "Ollama not found"
fi

# 5. Ask about R packages
echo ""
if confirm "Remove R packages used by KruRooAI? (optparse, yaml, jsonlite)"; then
    print_status "Removing R packages..."
    R --slave --no-restore -e "
    packages <- c('optparse', 'yaml', 'jsonlite')
    installed <- rownames(installed.packages())
    to_remove <- packages[packages %in% installed]
    if(length(to_remove) > 0) {
      remove.packages(to_remove)
      cat('Removed:', paste(to_remove, collapse=', '), '\n')
    } else {
      cat('No packages to remove\n')
    }
    " 2>/dev/null || print_warning "Failed to remove some R packages"
    print_success "R packages processed"
else
    print_warning "R packages kept (they might be used by other programs)"
fi

# 6. Ask about Python packages
echo ""
if confirm "Remove Python requests package? (May be used by other programs)"; then
    print_status "Removing Python requests..."
    if pip3 uninstall requests -y 2>/dev/null; then
        print_success "Python requests removed"
    else
        print_warning "Failed to remove requests (may not be installed or permission issue)"
    fi
else
    print_warning "Python requests kept"
fi

# 7. Clean up any remaining files
print_status "Cleaning up remaining files..."
find /usr/local/bin -name "*krurooai*" -delete 2>/dev/null || true
find /tmp -name "*krurooai*" -delete 2>/dev/null || true

print_success "Cleanup completed"

# Final instructions
echo ""
echo "🎉 Uninstall completed!"
echo ""

if [ "$SHOULD_REMOVE_PROJECT" = true ] && [[ "$PROJECT_DIR" == *"krurooai-project" ]]; then
    print_warning "Don't forget to remove the project directory:"
    echo "  cd .."
    echo "  rm -rf krurooai-project"
    echo ""
fi

print_status "To verify removal, try:"
echo "  which krurooai  # Should return 'not found'"
echo "  ls ~/KruRooAI-Work  # Should not exist (if you chose to remove it)"
echo ""

print_success "Thank you for using KruRooAI! 👋"